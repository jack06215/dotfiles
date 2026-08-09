# shellcheck shell=bash
# shellcheck disable=SC1091
# filetype=sh

# Callers must use `_check_gum_cmd || return 1`: on its own the call reports
# the problem but does not stop the caller from running on without gum.
source "$ZDOTDIR/src/functions.zsh"

function gh_pr_list() {
  local limit=300

  # If first arg is a number, treat it as limit
  if [[ $1 == <-> ]]; then
    limit="$1"
    shift
  fi

  gh pr list --limit "$limit" "$@"
}

# Pick a pull request and print its number. Any arguments are passed through to
# `gh pr list`, so `ghpr --author @me` narrows the list before the picker opens.
#
# fzf rather than gum filter: the preview pane renders the title, head branch
# and body of whichever PR is under the cursor, and gum's pickers have no
# preview pane at all.
function _ghpr_fzf_pick() {
  gh pr list "$@" --limit 500 \
    --json number,title,author,state,url \
    | jq -r '.[] | "\(.number)\tPR #\(.number) | \(.state) | \(.author.login) | \(.title)"' \
    | fzf \
      --delimiter='\t' \
      --with-nth=2.. \
      --prompt='PR> ' \
      --preview='sh -c '"'"'
        gh pr view "$1" --json title,body,headRefName \
          --jq "[
            \"# \" + .title,
            \"\",
            \"Branch: \" + .headRefName,
            \"\",
            .body
          ] | join(\"\\n\")"
      '"'"' sh {1}' \
      --preview-window=right:60%:wrap \
    | awk -F'\t' '{print $1}'
}

# Pick a PR once, then act on it repeatedly from a menu.
#
# This replaces ghpr_view / ghpr_url / ghpr_open / ghpr_fzf_open / ghpr_fzf_view
# and the --pbcopy flag they each parsed separately. That flag was really an
# answer to "what do you want out of this PR?", which is a menu rather than a
# flag - and as a menu the answer can change without re-picking the PR.
function ghpr() {
  _check_gum_cmd || return 1

  local pr action

  pr="$(_ghpr_fzf_pick "$@")" || return
  [[ -n "$pr" ]] || return

  while true; do
    action=$(printf '%s\n' \
      "view      Read the PR body in a pager|view" \
      "web       Open the PR in a browser|web" \
      "url       Copy the PR URL|url" \
      "branch    Copy the head branch name|branch" \
      "body      Copy title + body as Markdown|body" \
      "checks    Watch CI until it settles|checks" \
      "quit      Done|quit" \
      | gum choose --label-delimiter="|" \
        --height=9 \
        --header="PR #$pr - what next?") || return

    case "$action" in
      view)
        gh pr view "$pr" --json title,body \
          --jq '"# " + .title + "\n\n" + .body' \
          | gum format -t markdown \
          | gum pager
        ;;
      web)
        gh pr view -w "$pr"
        ;;
      url)
        # tr rather than a bare pipe: gh terminates the field with a newline,
        # which would otherwise be pasted along with the URL.
        gh pr view "$pr" --json url --jq .url | tr -d '\n' | pbcopy
        gum log --level info "PR URL copied to the clipboard"
        ;;
      branch)
        gh pr view "$pr" --json headRefName --jq .headRefName | tr -d '\n' | pbcopy
        gum log --level info "Head branch copied to the clipboard"
        ;;
      body)
        gh pr view "$pr" --json title,body \
          --jq '"# " + .title + "\n\n" + .body' | pbcopy
        gum log --level info "Title and body copied as Markdown"
        ;;
      checks)
        ghpr_checks_watch "$pr"
        ;;
      quit)
        return 0
        ;;
    esac
  done
}

function ghpr_create() {
  _check_gum_cmd || return 1

  if gh pr view > /dev/null 2>&1; then
    echo "Pull request already exists for this branch." >&2
    return 1
  fi

  # check_pushed_to_remote (git.zsh) already reports precisely which of the
  # three cases failed - no branch, no upstream, or ahead of upstream - so
  # offer the fix rather than repeating the diagnosis.
  if ! check_pushed_to_remote; then
    gum confirm "Push this branch to origin first?" || return 1
    gum spin --spinner=minidot --show-error --title="Pushing..." -- \
      git push -u origin HEAD || return 1
  fi

  local base
  # lstrip=3 turns refs/remotes/origin/main into main, which is what --base
  # expects; HEAD is dropped because it is the remote's symbolic default, not
  # a branch you can open a PR against.
  base=$(git branch -r --format='%(refname:lstrip=3)' \
    | grep -v '^HEAD$' \
    | gum filter --header="Open the PR against which base branch?" \
      --placeholder="base") || return
  [[ -n "$base" ]] || return 1

  # gh prompts for the title and body itself, so there is nothing for gum to
  # add here beyond the base branch it would otherwise have guessed.
  gh pr create --draft --base "$base" || return 1
  gh pr view --web
}

function ghpr_create_from_llm() {
  _check_gum_cmd || return 1

  local json title body
  json="$(cat)" || return 1

  title=$(jq -r '.title // empty' <<< "$json")
  body=$(jq -r '.body // empty' <<< "$json")

  [[ -n "$title" ]] || {
    echo "No title in the JSON payload." >&2
    return 1
  }

  # The payload was written by a model, so put it on screen before it becomes a
  # PR. Printed rather than paged: stdin is the JSON pipe, and a pager here
  # would be competing with it for the terminal.
  printf '# %s\n\n%s\n' "$title" "$body" | gum format -t markdown

  # gum reads keys from stdin, which at this point is the exhausted JSON pipe,
  # so point it at the terminal explicitly.
  gum confirm "Create a draft PR with this title and body?" < /dev/tty || return 1

  gh pr create --draft --title "$title" --body "$body"
}

# gh's own watch: a live-updating table, and nothing else. Use ghpr_checks_watch
# when you want to walk away and be told once the run settles.
function ghpr_watch() {
  local pr="${1:-}"
  local -a args
  [[ -n "$pr" ]] && args=("$pr")

  gh pr checks "${args[@]}" --watch -i 3
}

# Watch CI until it settles, then send a desktop notification. Takes an
# optional PR number so the ghpr menu can hand one over; without it, gh falls
# back to the PR for the current branch.
function ghpr_checks_watch() {
  _check_gum_cmd || return 1

  local pr="${1:-}" interval="${2:-5}" checks rc failed
  local -a args
  [[ -n "$pr" ]] && args=("$pr")

  while true; do
    # gum spin passes the wrapped command's stdout through when its own stdout
    # is not a terminal, so $(...) still captures the JSON while the spinner
    # draws on stderr. --show-error keeps that quiet unless the fetch breaks.
    checks=$(gum spin --spinner=minidot --show-error \
      --title="Checking CI${pr:+ on PR #$pr}..." -- \
      gh pr checks "${args[@]}" --json name,state,bucket)
    rc=$?

    # gh exits 8 while checks are still pending and 1 once one has failed, so a
    # non-zero exit is the normal case mid-run and cannot be treated as an
    # error. Only an empty payload means the fetch itself went wrong.
    if [[ -z "$checks" ]]; then
      echo "Could not read checks (gh exit $rc)." >&2
      return 1
    fi

    # An empty array satisfies the `all(...)` settled test below, which would
    # otherwise announce "all checks passed" for a PR that has no checks at all.
    if jq -e 'length == 0' <<< "$checks" > /dev/null; then
      echo "No checks reported for this pull request." >&2
      return 1
    fi

    # Redrawn in place of the old `clear`, which wiped whatever was on screen
    # before the watch started along with the previous pass.
    jq -r '["STATE","CHECK"], (.[] | [.state, .name]) | @csv' <<< "$checks" \
      | gum table --print --border=rounded --widths=14,60

    # bucket is gh's own categorisation of state into pass/fail/pending/
    # skipping/cancel, which is why there is no list of state strings here.
    if jq -e 'any(.[]; .bucket == "fail" or .bucket == "cancel")' <<< "$checks" > /dev/null; then
      failed=$(jq -r '.[] | select(.bucket == "fail" or .bucket == "cancel") | .name' <<< "$checks")
      gum log --level error --time kitchen "CI failed" checks "${failed//$'\n'/, }"
      notify_error "CI failed: ${failed//$'\n'/, }"
      return 1
    fi

    if jq -e 'all(.[]; .bucket != "pending")' <<< "$checks" > /dev/null; then
      gum log --level info --time kitchen "All checks passed"
      notify_news "All checks passed (including SKIPPED)"
      return 0
    fi

    sleep "$interval"
  done
}

# Kept on fzf: the preview pane is what makes a bare check name identifiable.
function ghpr_fzf_checks_open() {
  local pr="${1:-}" link
  local -a args
  [[ -n "$pr" ]] && args=("$pr")

  link=$(
    gh pr checks "${args[@]}" --json name,state,link \
      | jq -r '.[] | "\(.state)\t\(.name)\t\(.link)"' \
      | fzf \
        --delimiter='\t' \
        --with-nth=1,2 \
        --preview='
          echo "State : {1}"
          echo "Check : {2}"
          echo
          echo "Open in browser:"
          echo "{3}"
        ' \
        --preview-window=right:50%:wrap \
      | awk -F'\t' '{print $3}'
  )

  # Escaping the picker leaves this empty, and a bare `open` with no argument
  # opens a Finder window rather than doing nothing.
  [[ -n "$link" ]] || return

  open "$link"
}

function gh_repo_open() {
  gh repo view --web
}
