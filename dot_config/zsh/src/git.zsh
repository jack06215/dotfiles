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
  git log --oneline |
  fzf --preview 'git show --color=always {1}' |
  awk '{print $1}'
}


function gdiff() {
  local sha
  sha=$(
    git log --oneline |
    fzf --preview 'git show --color=always {1}' |
    awk '{print $1}'
  ) || return

  git show --color=always --first-parent "$sha"
}

# Conventional commit types offered by `gcm`, mirroring the menu of the
# lazygit `<c>` custom command. Each entry is "<picker label>|<value>";
# `gum choose --label-delimiter` prints only the part after the pipe, so the
# descriptions never leak into the commit message.
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
  # git conventional commit, driven by gum
  command -v gum >/dev/null 2>&1 || {
    echo "❌ gum is not installed (brew install gum)." >&2
    return 1
  }

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "❌ Not a git repository." >&2
    return 1
  }

  # Nothing staged yet: show what is outstanding and offer to stage all of it.
  if git diff --cached --quiet 2>/dev/null; then
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

  local type scope summary description rest
  type=$(printf '%s\n' "${_GIT_COMMIT_TYPES[@]}" |
    gum choose --label-delimiter="|" \
               --height=12 \
               --header="Select the type of change you are committing.") || return

  scope=$(gum input --header="Enter a scope (optional)." \
                    --placeholder="scope") || return

  # Since the scope is optional, wrap it in parentheses only if it has a value.
  [[ -n "$scope" ]] && scope="($scope)"

  # Pre-populate "type(scope): " so only the summary itself has to be typed.
  summary=$(gum input --header="Summary of this change" \
                      --value="${type}${scope}: ") || return

  # Reject a summary left as the bare pre-filled prefix. The pattern is quoted
  # so that a scope's parentheses are matched literally, not as a glob group.
  rest="${summary#"${type}${scope}:"}"
  if [[ -z "${rest//[[:space:]]/}" ]]; then
    echo "❌ Aborted: empty commit summary." >&2
    return 1
  fi

  description=$(gum write --header="Details of this change (optional, ctrl+d to finish)" \
                          --placeholder="Details of this change") || return

  gum confirm "Commit changes?" || return 1

  # Pass a body only when one was written, so an empty -m doesn't leave a
  # trailing blank paragraph in the message.
  if [[ -n "${description//[[:space:]]/}" ]]; then
    git commit -m "$summary" -m "$description"
  else
    git commit -m "$summary"
  fi
}

function check_pushed_to_remote() {
  local branch
  branch="$(git symbolic-ref --short HEAD 2>/dev/null)" || {
    echo "❌ Not on a branch." >&2
    return 1
  }

  if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    echo "❌ Branch '$branch' has no upstream." >&2
    return 1
  fi

  if [[ "$(git rev-parse "@")" != "$(git rev-parse "@{u}")" ]]; then
    echo "❌ Branch '$branch' is not pushed to remote." >&2
    return 1
  fi

  return 0
}
