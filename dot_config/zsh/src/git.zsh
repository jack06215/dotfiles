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
