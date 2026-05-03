# shellcheck shell=bash
# shellcheck disable=SC1091
# filetype=sh

function gh_pr_list() {
  local limit=300

  # If first arg is a number, treat it as limit
  if [[ $1 == <-> ]]; then
    limit="$1"
    shift
  fi

  gh pr list --limit "$limit" "$@"
}

function __gh_parse_pbcopy_flag() {
  local pbcopy=0
  local args=()

  for arg in "$@"; do
    case "$arg" in
      --pbcopy)
        pbcopy=1
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  # 残り引数を stdout に返す
  printf '%s\n' "${args[@]}"

  # return code で pbcopy モードを伝える
  if (( pbcopy )); then
    return 10   # pbcopy mode
  else
    return 0
  fi
}

function __gh_copy() {
  pbcopy
}

function ghpr_view() {
  local pr rc rest

  rest="$(__gh_parse_pbcopy_flag "$@")"
  rc=$?

  if (( rc == 2 )); then
    echo "Usage: ghpr_view [--pbcopy] [PR_NUMBER]" >&2
    return 2
  fi

  pr="$rest"

  if (( rc == 10 )); then
    gh pr view "$pr" --json title,body \
      --jq '"# " + .title + "\n\n" + .body' \
    | __gh_copy
    echo "📋 PR body copied as Markdown"
  else
    gh pr view "$pr" --json title,body \
      --jq '"# " + .title + "\n\n" + .body' \
    | bat --language md
  fi
}

function ghpr_url() {
  local pr rc rest url

  rest="$(__gh_parse_pbcopy_flag "$@")"
  rc=$?

  if (( rc == 2 )); then
    echo "Usage: ghpr_copy [--pbcopy] [PR_NUMBER]" >&2
    return 2
  fi

  pr="$rest"

  if [[ -n "$pr" ]]; then
    url=$(gh pr view "$pr" --json url --jq .url)
  else
    url=$(gh pr view --json url --jq .url)
  fi

  print -rn -- "$url" | pbcopy
  (( rc != 10 )) && echo "$url"
}

function ghpr_watch() {
  local pr rc rest

  rest="$(__gh_parse_pbcopy_flag "$@")"
  rc=$?

  if (( rc == 2 )); then
    echo "Usage: ghpr_watch [--pbcopy] [PR_NUMBER]" >&2
    return 2
  fi

  pr="$rest"

  if [[ -n "$pr" ]]; then
    gh pr checks --watch -i 3 "$pr"
    (( rc == 10 )) && gh pr checks "$pr" --json name,state,link | __gh_copy
  else
    gh pr checks --watch -i 3
    (( rc == 10 )) && gh pr checks --json name,state,link | __gh_copy
  fi
}

# function ghpr_fzf_view() {
#   local pr

#   pr="$(
#     gh pr list --json number,title,author,state,url \
#     | jq -r '.[] | "\(.number)\t\(.state)\t\(.author.login)\t\(.title)\t\(.url)"' \
#     | fzf \
#         --delimiter='\t' \
#         --with-nth=1,4 \
#         --preview='printf "PR #%s\nState : %s\nAuthor: %s\n\n%s\n\n%s\n" {1} {2} {3} {4} {5}' \
#         --preview-window=right:60%:wrap \
#     | awk -F'\t' '{print $1}'
#   )" || return 1

#   gh pr view "$pr" --json title,body \
#     --jq '"# " + .title + "\n\n" + .body' \
#   | bat --language md
# }


function ghpr_fzf_view() {
  local pr

  pr="$(
    gh_pr_list --json number,title,author,state,url \
    | jq -r '.[] | "\(.number)\tPR #\(.number) | \(.state) | \(.author.login) | \(.title)"' \
    | fzf \
        --delimiter='\t' \
        --with-nth=2.. \
        --prompt='PR> ' \
        --preview='sh -c '"'"'
          gh pr view "$1" --json title,headRefName \
            --jq "[
              \"# \" + .title,
              \"\",
              \"Branch: \" + .headRefName
            ] | join(\"\\n\")"
        '"'"' sh {1}' \
        --preview-window=right:60%:wrap \
    | awk -F'\t' '{print $1}'
  )" || return

  [[ -z "$pr" ]] && return

  gh pr view "$pr" --json title,body \
    --jq '"# " + .title + "\n\n" + .body' \
  | bat --language=markdown --paging=always
}

function ghpr_fzf_open() {
  local rc rest pr

  # parse --pbcopy (shared helper)
  rest="$(__gh_parse_pbcopy_flag "$@")"
  rc=$?

  if (( rc == 2 )); then
    echo "Usage: ghpr_fzf_open [--pbcopy] [gh pr list options]" >&2
    return 2
  fi

  pr="$(
    gh pr list ${=rest} --limit 500 \
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
  )" || return

  [[ -z "$pr" ]] && return

  if (( rc == 10 )); then
    gh pr view "$pr" --json headRefName --jq .headRefName | __gh_copy
    echo "📋 Branch name copied"
  fi
  gh pr view -w "$pr"
}

function ghpr_create() {
  if gh pr view >/dev/null 2>&1; then
    echo "❌ Pull request already exists for this branch." >&2
    return 1
  fi

  # なければ Draft PR を作成
  gh pr create --draft
  gh pr view --web
}

function ghpr_open() {
  if ! gh pr view >/dev/null 2>&1; then
    echo "❌ No pull request exists for this branch." >&2
    return 1
  fi

  gh pr view --web
}

function ghpr_create_from_llm() {
  local json
  json="$(cat)" || return 1

  gh pr create --draft \
    --title "$(jq -r .title <<<"$json")" \
    --body "$(jq -r .body <<<"$json")"
}

function ghpr_checks_watch() {
  local interval="${1:-5}"

  while true; do
    clear

    # fetch status once
    local checks
    checks="$(gh pr checks --json name,state)"

    # render to human-readable output
    local rendered
    rendered="$(jq -r '.[] | "\(.state)\t\(.name)"' <<<"$checks")"

    # display
    print -r -- "$rendered"

    # notify when FAIL / CANCELLED (NO echo)
    if jq -e 'any(.[]; .state=="FAILURE" or .state=="CANCELLED")' \
         <<<"$checks" >/dev/null; then

      local failed
      failed="$(jq -r '.[] | select(.state=="FAILURE" or .state=="CANCELLED") | .name' \
                 <<<"$checks")"

      notify_error "❌ CI failed: ${failed//$'\n'/, }"
      return 1
    fi

    # notify when SUCCESS / SKIPPED (NO echo)
    if jq -e '
         all(.[];
           .state!="FAILURE"
           and .state!="CANCELLED"
           and .state!="PENDING"
           and .state!="IN_PROGRESS"
         )' <<<"$checks" >/dev/null; then

      notify_news "✅ All checks passed (including SKIPPED)"
      break
    fi

    sleep "$interval"
  done
}

function ghpr_fzf_checks_open() {
  gh pr checks --json name,state,link \
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
  | awk -F'\t' '{print $3}' \
  | xargs open
}

function gh_repo_open() {
  gh repo view --web
}
