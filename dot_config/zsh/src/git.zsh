# Callers must use `_check_gum_cmd || return 1`: on its own the call reports
# the problem but does not stop the caller from running on without gum.
source "$ZDOTDIR/src/functions.zsh"

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

function gbr() {
  _check_gum_cmd || return 1

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    echo "Not a git repository." >&2
    return 1
  }

  local ticket description branch
  local -a words

  ticket=$(gum input --header="Ticket number (optional)." \
    --placeholder="PR") || return

  ticket=${${ticket:-PR}:u}

  description=$(gum input --header="Describe the branch in English." \
    --placeholder="add login button") || return

  words=(${=description:l})
  if ((${#words} == 0)); then
    echo "Aborted: empty description." >&2
    return 1
  fi

  branch="${ticket}/${(j:-:)words}"

  # The description is only lowercased and dashed, so anything else git refuses
  # in a ref name is reported rather than silently rewritten.
  git check-ref-format --branch "$branch" > /dev/null 2>&1 || {
    echo "'$branch' is not a valid branch name." >&2
    return 1
  }

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "Branch '$branch' already exists - run gbs to switch to it." >&2
    return 1
  fi

  gum confirm "Create branch '$branch'?" || return 1

  git checkout -b "$branch"
}

function gcg() {
  # git clean gone: delete local branches whose upstream has been deleted.
  _check_gum_cmd || return 1

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    echo "Not a git repository." >&2
    return 1
  }

  local current out b
  local -a gone picked unmerged

  # for-each-ref rather than `git branch -vv | awk '{print $1}'`: that pipeline
  # returns "*" for the checked-out branch, so `git branch -D '*'` is what runs
  # and fails, making the branch most likely to matter the one it silently
  # skips.
  gone=(${(f)"$(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads \
    | awk '$2 == "[gone]" { print $1 }')"})

  ((${#gone})) || {
    echo "No gone branches found. (git fetch --prune first if that seems wrong.)"
    return 0
  }

  # A checked-out branch cannot be deleted, so keep it out of the menu rather
  # than letting the pick fail later at the git call.
  current=$(git symbolic-ref --short HEAD 2> /dev/null)
  [[ -n "$current" ]] && gone=(${gone:#$current})

  ((${#gone})) || {
    echo "Only '$current' is gone, and it is checked out - switch away first."
    return 0
  }

  # --selected='*' starts with everything ticked, so clearing the list is still
  # one keystroke, but sparing a branch no longer means aborting the whole run.
  out=$(printf '%s\n' "${gone[@]}" \
    | gum choose --no-limit \
      --height=15 \
      --selected='*' \
      --header="Delete which gone branches? (tab to toggle, enter to confirm)") || return 1

  picked=(${(f)out})
  ((${#picked})) || return 0

  # -d refuses anything not merged into HEAD. Collect the refusals rather than
  # reaching for -D up front, so the force becomes a separate informed decision
  # instead of the default.
  for b in "${picked[@]}"; do
    git branch -d "$b" 2> /dev/null || unmerged+=("$b")
  done

  ((${#unmerged})) || return 0

  echo "Not fully merged into ${current:-HEAD}:"
  printf '  %s\n' "${unmerged[@]}"

  # --default=false makes "No" the resting position; gum confirm otherwise
  # defaults to Yes, which is the wrong way round for an unrecoverable delete.
  gum confirm "Force-delete these ${#unmerged} branch(es)?" --default=false || return 1

  git branch -D -- "${unmerged[@]}"
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

# Print one line per path that can still be staged - worktree changes not yet in
# the index, plus untracked files - as "<status>  <path>". -z keeps the paths
# unquoted, so the status strips back off with ${line#*  } even when a path
# contains spaces, which is what gum filter's plain-text output needs (unlike
# gum choose, it has no --label-delimiter to carry a separate value).
function _git_stage_candidates() {
  local st f
  while IFS= read -r -d '' st && IFS= read -r -d '' f; do
    print -r -- "$st  $f"
  done < <(git diff --name-status --no-renames -z)

  while IFS= read -r -d '' f; do
    print -r -- "?  $f"
  done < <(git ls-files --others --exclude-standard -z)
}

# Stage what the commit should contain. With --all that is everything; otherwise
# the worktree is offered as a multi-select. Anything staged beforehand is left
# alone either way, so a hand-built index survives.
function _git_stage_for_commit() {
  local all=$1 out
  local -a candidates picked paths

  if ((all)); then
    git add -A
    return
  fi

  candidates=(${(f)"$(_git_stage_candidates)"})
  ((${#candidates})) || return 0

  out=$(printf '%s\n' "${candidates[@]}" \
    | gum filter --no-limit \
      --height=15 \
      --header="Select files to stage (tab to mark, enter to confirm)." \
      --placeholder="") || {
    # Escaping the picker is only an abort when it would leave nothing to
    # commit; otherwise it means "just commit what is already staged".
    git diff --cached --quiet 2> /dev/null && return 1
    gum confirm "Stage nothing more and commit the current index?" || return 1
    return 0
  }

  picked=(${(f)out})
  ((${#picked})) || return 0

  # add -A rather than a plain add, so a picked path that was deleted in the
  # worktree stages as a deletion instead of erroring.
  paths=(${picked#*  })
  git add -A -- "${paths[@]}"
}

# Run the repository's pre-commit checks once. The pre-commit framework's config
# wins over .git/hooks/pre-commit, because when both are present the hook is only
# a shim that runs the framework anyway. No config and no hook is a silent no-op.
function _git_run_pre_commit() {
  local root hook
  root=$(git rev-parse --show-toplevel) || return 1

  if [[ -f "$root/.pre-commit-config.yaml" ]]; then
    if ! command -v pre-commit > /dev/null 2>&1; then
      echo "Skipping checks: .pre-commit-config.yaml found but 'pre-commit' is not installed." >&2
      return 0
    fi
    # No paths: pre-commit run defaults to the staged files.
    (cd "$root" && pre-commit run)
    return
  fi

  # --git-path honours core.hooksPath, and :A makes it absolute so it survives
  # the cd to the work tree root that hooks are run from.
  hook=$(git rev-parse --git-path hooks/pre-commit) || return 1
  hook=${hook:A}
  [[ -x "$hook" ]] || return 0

  (cd "$root" && "$hook")
}

# Run the checks before the editor opens, so a failure costs nothing more than
# the pickers rather than a written message. Formatters exit non-zero having
# already written their fixes to the worktree, so a failed run is often just
# "fold these in and go again" - hence the retry rather than a flat rejection.
#
# git runs the hooks again at commit time. That second pass is cheap once they
# pass, and leaving it in place keeps commit-msg hooks working, which the
# --no-verify needed to skip it would also disable.
function _git_pre_commit_flow() {
  local before after
  local -i pass=0
  local -a staged dirty

  while true; do
    ((pass++))
    staged=(${(f)"$(git diff --cached --name-only)"})
    ((${#staged})) || return 0

    # Hashed rather than diffed against a file list: a formatter rewriting a
    # file that was already partially staged changes the diff without changing
    # which files appear in it.
    before=$(git diff -- "${staged[@]}" | git hash-object --stdin)

    _git_run_pre_commit && return 0

    after=$(git diff -- "${staged[@]}" | git hash-object --stdin)

    # The retry stops being offered after a few passes, so a hook that rewrites
    # the same files on every run cannot loop here forever.
    if [[ "$before" != "$after" ]] && ((pass < 3)); then
      dirty=(${(f)"$(git diff --name-only -- "${staged[@]}")"})
      echo
      echo "Checks failed after rewriting:"
      printf '  %s\n' "${dirty[@]}"
      # Staging by path takes the whole file, so say so: anything deliberately
      # left out of the index with git add -p comes along too.
      if gum confirm "Stage these files in full and run again?"; then
        git add -A -- "${dirty[@]}" || return 1
        continue
      fi
    fi

    gum confirm "Pre-commit checks failed. Commit anyway?" || return 1
    return 0
  done
}

# The type is the first field of each line, so the picker can hand the line
# straight to awk instead of carrying a separate label/value delimiter.
_GIT_COMMIT_TYPES=(
  "feat      A new feature"
  "fix       A bug fix"
  "docs      Documentation only changes"
  "style     Styling changes (white-space, formatting, etc)"
  "refactor  Refactoring code"
  "perf      Performance improvements"
  "test      Test additions or fixes"
  "build     Build system or dependency changes"
  "ci        CI configuration changes"
  "chore     Other non-code changes"
  "revert    Reverting changes"
)

function gcm() {
  _check_gum_cmd || return 1

  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    echo "Not a git repository." >&2
    return 1
  }

  local -i all=0
  while (($#)); do
    case "$1" in
      -a | --all) all=1 ;;
      -h | --help)
        echo "usage: gcm [-a|--all]"
        echo "  -a, --all  stage every change instead of picking files"
        return 0
        ;;
      *)
        echo "gcm: unknown option '$1'" >&2
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "$(git status --porcelain)" ]]; then
    echo "Nothing to commit."
    return 1
  fi

  _git_stage_for_commit "$all" || return 1

  if git diff --cached --quiet 2> /dev/null; then
    echo "Nothing staged."
    return 1
  fi

  _git_pre_commit_flow || return 1

  # Reference only, so the summary can be written with the diff at hand: a
  # summary on screen, and the full diff on the clipboard (as the lazygit `<c>`
  # command does) for pasting into a PR description, an LLM prompt, etc.
  git diff --cached --stat
  git diff --cached | pbcopy

  local type scope tmpdir msgfile editor message rest
  type=$(printf '%s\n' "${_GIT_COMMIT_TYPES[@]}" \
    | gum filter --limit=1 \
      --height=12 \
      --header="Select the type of change you are committing." \
      --placeholder="" \
    | awk '{print $1}')

  # Cancelling out of gum leaves this empty, and so does the awk on the end,
  # which exits 0 either way.
  [[ -n "$type" ]] || return 1

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
