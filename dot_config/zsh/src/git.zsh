# Callers must use `_check_gum_cmd || return 1`: on its own the call reports
# the problem but does not stop the caller from running on without gum.
function _check_gum_cmd() {
  command -v gum > /dev/null 2>&1 || {
    # funcstack[2] is the calling function, so the message names it.
    echo "${funcstack[2]:-gum} requires 'gum' to be installed." >&2
    return 1
  }
}

function gcb() {
  # git checkout branch
  local branch
  branch=$(git branch --all | grep -v 'HEAD' | sed 's/.* //' | fzf) || return
  git checkout "$branch"
}

function gco() {
  # git checkout commit
  local commit
  commit=$(git log --oneline | fzf | awk '{print $1}') || return
  git checkout "$commit"
}

function gbs() {
  # git switch branch
  local branch
  branch=$(git branch --color=never \
    | sed 's/^..//' \
    | fzf --prompt="Git branches > ") || return
  git switch "$branch"
}

function gcg() {
  # git clean gone
  local branches
  branches=$(git branch -vv | grep ': gone]' | awk '{print $1}')

  if [[ -z "$branches" ]]; then
    echo "No gone branches found."
    return 0
  fi

  echo "Deleting the following branches:"
  echo "$branches"
  echo

  read "confirm?Are you sure? (y/N): "
  if [[ "$confirm" != "y" ]]; then
    echo "Cancelled."
    return 1
  fi

  echo "$branches" | xargs -I {} git branch -D {}
}

function glog() {
  git log --oneline \
    | fzf --preview 'git show --color=always {1}' \
    | awk '{print $1}'
}

function gdiff() {
  local sha
  sha=$(
    git log --oneline \
      | fzf --preview 'git show --color=always {1}' \
      | awk '{print $1}'
  ) || return

  git show --color=always --first-parent "$sha"
}

_GIT_COMMIT_TYPES=(
  "feat      A new feature|feat"
  "fix       A bug fix|fix"
  "docs      Documentation only changes|docs"
  "style     Styling changes (white-space, formatting, etc)|style"
  "refactor  Refactoring code|refactor"
  "perf      Performance improvements|perf"
  "test      Test additions or fixes|test"
  "build     Build system or dependency changes|build"
  "ci        CI configuration changes|ci"
  "chore     Other non-code changes|chore"
  "revert    Reverting changes|revert"
)

function gcm() {
  _check_gum_cmd || return 1

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    echo "Not a git repository." >&2
    return 1
  }

  if git diff --cached --quiet 2> /dev/null; then
    if [[ -z "$(git status --porcelain)" ]]; then
      echo "Nothing to commit."
      return 1
    fi
    git status --short
    gum confirm "Nothing staged. Stage everything?" || return 1
    git add -A
  fi

  # Reference only, so the summary can be written with the diff at hand: a
  # summary on screen, and the full diff on the clipboard (as the lazygit `<c>`
  # command does) for pasting into a PR description, an LLM prompt, etc.
  git diff --cached --stat
  git diff --cached | pbcopy

  local type scope tmpdir msgfile editor message rest
  type=$(printf '%s\n' "${_GIT_COMMIT_TYPES[@]}" \
    | gum choose --label-delimiter="|" \
      --height=12 \
      --header="Select the type of change you are committing.") || return

  scope=$(gum input --header="Enter a scope (optional)." \
    --placeholder="scope") || return

  # Since the scope is optional, wrap it in parentheses only if it has a value.
  [[ -n "$scope" ]] && scope="($scope)"

  tmpdir=$(mktemp -d) || return 1
  msgfile="$tmpdir/COMMIT_EDITMSG"
  trap "rm -rf ${(q)tmpdir}" EXIT

  {
    printf '%s\n\n# :wq! to commit\n# :cq! to discard commit\n#\n# --- staged diff (reference only; stripped from the commit message) ---\n' \
      "${type}${scope}: "
    git diff --cached | sed 's/^/# /'
  } > "$msgfile"

  editor=$(git var GIT_EDITOR) || return 1

  if ! eval "${editor} ${(q)msgfile}"; then
    echo "Aborted." >&2
    return 1
  fi

  # Drop the reference block. git's own --cleanup would do this too, but the
  # message has to be stripped here to tell an empty one from a real one.
  message=$(grep -v '^#' "$msgfile")

  # Reject a message left as the bare pre-filled prefix. The pattern is quoted
  # so that a scope's parentheses are matched literally, not as a glob group.
  rest="${message#"${type}${scope}:"}"
  if [[ -z "${rest//[[:space:]]/}" ]]; then
    echo "Aborted: empty commit message." >&2
    return 1
  fi

  gum confirm "Commit changes?" || return 1

  print -r -- "$message" | git commit --cleanup=strip -F -
}

function check_pushed_to_remote() {
  local branch
  branch="$(git symbolic-ref --short HEAD 2> /dev/null)" || {
    echo "Not on a branch." >&2
    return 1
  }

  if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" > /dev/null 2>&1; then
    echo "Branch '$branch' has no upstream." >&2
    return 1
  fi

  if [[ "$(git rev-parse "@")" != "$(git rev-parse "@{u}")" ]]; then
    echo "Branch '$branch' is not pushed to remote." >&2
    return 1
  fi

  return 0
}

# Print the directory git uses to track an in-progress rebase, or return
# non-zero when no rebase is running. The merge backend (git's default) uses
# rebase-merge; the older apply backend uses rebase-apply.
function _git_rebase_dir() {
  # Not named `path`: that is tied to $PATH in zsh, and declaring it local
  # blanks PATH for the rest of the function, so even `git` stops resolving.
  local name candidate
  for name in rebase-merge rebase-apply; do
    candidate=$(git rev-parse --git-path "$name" 2> /dev/null) || return 1
    if [[ -d "$candidate" ]]; then
      print -r -- "$candidate"
      return 0
    fi
  done
  return 1
}

# Print "<current>/<total>" for the rebase tracked in <dir>, if git recorded it.
function _git_rebase_progress() {
  local dir="$1"
  if [[ -f "$dir/msgnum" && -f "$dir/end" ]]; then
    print -r -- "$(< "$dir/msgnum")/$(< "$dir/end")"
  elif [[ -f "$dir/next" && -f "$dir/last" ]]; then
    print -r -- "$(< "$dir/next")/$(< "$dir/last")"
  fi
}

function grb() {
  # git rebase, with an interactive base picker
  _check_gum_cmd || return 1

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    echo "Not a git repository." >&2
    return 1
  }

  if _git_rebase_dir > /dev/null; then
    echo "A rebase is already in progress - run grbc to work through it." >&2
    return 1
  fi

  local onto base count unpublished published orig upstream
  local -a args
  onto=$(printf '%s\n' \
    "branch    Rebase onto another branch|branch" \
    "commit    Rebase onto a commit from the log|commit" \
    "upstream  Rebase onto the tracking branch|upstream" \
    | gum choose --label-delimiter="|" \
      --header="Rebase onto what?") || return

  case "$onto" in
    branch)
      base=$(git branch --all --format='%(refname:short)' \
        | grep -v '^HEAD$' \
        | gum filter --header="Rebase onto which branch?" \
          --placeholder="branch")
      ;;
    commit)
      # Same shape as gco/glog: pick a log line, keep the sha off the front.
      base=$(git log --oneline -30 \
        | gum filter --header="Rebase onto which commit?" \
          --placeholder="commit" \
        | awk '{print $1}')
      ;;
    upstream)
      base=$(git rev-parse --abbrev-ref '@{u}' 2> /dev/null) || {
        echo "No upstream configured for this branch." >&2
        return 1
      }
      ;;
  esac

  # Cancelling out of gum leaves this empty, and so does the awk on the end of
  # the commit picker, which exits 0 either way.
  [[ -n "$base" ]] || return 1

  count=$(git rev-list --count "$base..HEAD" 2> /dev/null) || {
    echo "'$base' is not a valid rebase base." >&2
    return 1
  }

  if ((count == 0)); then
    echo "Nothing to replay - HEAD is already on $base."
    return 0
  fi

  echo "Commits to replay onto $base:"
  git log --oneline --reverse "$base..HEAD"

  # Rewriting commits that are already on the upstream means a force-push
  # afterwards, so say so before anything gets rewritten.
  if upstream=$(git rev-parse --abbrev-ref '@{u}' 2> /dev/null); then
    unpublished=$(git rev-list --count "$base..HEAD" --not '@{u}')
    published=$((count - unpublished))
    if ((published > 0)); then
      echo
      echo "Warning: $published of these are already on $upstream."
      echo "         Rebasing rewrites them and will need a force-push."
    fi
  fi

  gum confirm "Rebase $count commit(s) onto $base?" || return 1

  # Printed before anything is rewritten, so the old tip stays recoverable.
  orig=$(git rev-parse HEAD)
  echo "Pre-rebase HEAD: $orig  (git reset --hard $orig to undo)"

  args=(--autostash)
  if gum confirm "Edit the todo list?" \
    --affirmative="Interactive" \
    --negative="Straight replay"; then
    # --autosquash only takes effect on an interactive rebase; this is what
    # folds in the fixup! commits that gfix creates.
    args+=(--interactive --autosquash)
  fi

  git rebase "${args[@]}" "$base" || {
    echo
    echo "Rebase stopped - run grbc to work through it."
    return 1
  }
}

function grbc() {
  # git rebase continue: work through an in-progress rebase
  _check_gum_cmd || return 1

  local dir action file progress
  local -a conflicted picked menu

  dir=$(_git_rebase_dir) || {
    echo "No rebase in progress."
    return 1
  }

  # Re-checked every pass: the loop ends when git tears the directory down.
  while dir=$(_git_rebase_dir); do
    conflicted=(${(f)"$(git diff --name-only --diff-filter=U)"})
    progress=$(_git_rebase_progress "$dir")

    if ((${#conflicted})); then
      git status --short -- "${conflicted[@]}"
      menu=(
        "edit       Open a conflicted file in the editor|edit"
        "diff       Show the conflict diff|diff"
        "resolved   Stage files as resolved|resolved"
        "continue   git rebase --continue|continue"
        "skip       Drop this commit and move on|skip"
        "abort      Abandon the rebase|abort"
      )
      action=$(printf '%s\n' "${menu[@]}" \
        | gum choose --label-delimiter="|" \
          --height=8 \
          --header="Rebasing ${progress:-?} - ${#conflicted} file(s) conflicted") || return
    else
      menu=(
        "continue   git rebase --continue|continue"
        "skip       Drop this commit and move on|skip"
        "abort      Abandon the rebase|abort"
      )
      action=$(printf '%s\n' "${menu[@]}" \
        | gum choose --label-delimiter="|" \
          --height=5 \
          --header="Rebasing ${progress:-?} - nothing left to resolve") || return
    fi

    case "$action" in
      edit)
        file=$(printf '%s\n' "${conflicted[@]}" \
          | gum choose --header="Edit which file?") || continue
        eval "$(git var GIT_EDITOR) ${(q)file}"
        ;;
      diff)
        git diff -- "${conflicted[@]}"
        ;;
      resolved)
        picked=(${(f)"$(printf '%s\n' "${conflicted[@]}" \
          | gum choose --no-limit --header="Mark which files resolved?")"})
        ((${#picked})) && git add -- "${picked[@]}"
        ;;
      continue)
        git rebase --continue
        ;;
      skip)
        git rebase --skip
        ;;
      abort)
        gum confirm "Abort the rebase?" && {
          git rebase --abort
          return 0
        }
        ;;
    esac
  done

  echo "Rebase complete."
}

function gfix() {
  # git commit --fixup, choosing the commit being fixed up. Fold the result in
  # later with grb -> Interactive, which passes --autosquash.
  _check_gum_cmd || return 1

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    echo "Not a git repository." >&2
    return 1
  }

  if git diff --cached --quiet 2> /dev/null; then
    if [[ -z "$(git status --porcelain)" ]]; then
      echo "Nothing to commit."
      return 1
    fi
    git status --short
    gum confirm "Nothing staged. Stage everything?" || return 1
    git add -A
  fi

  git diff --cached --stat

  local target
  target=$(git log --oneline -30 \
    | gum filter --header="Which commit does this fix up?" \
      --placeholder="commit" \
    | awk '{print $1}')
  [[ -n "$target" ]] || return 1

  gum confirm "Create fixup! for $(git log -1 --format='%h %s' "$target")?" || return 1

  git commit --fixup="$target"
}
