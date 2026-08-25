# shellcheck shell=bash
# shellcheck disable=SC1091
#
# tock - command-line time tracking. Settings live in ~/.config/tock/tock.yaml;
# this file is only the shell ergonomics on top of the binary, and deliberately
# exports no TOCK_* variables so that the YAML stays the one place a setting is
# decided (TOCK_* would outrank it and the two would drift).
#
# The whole design rests on one behaviour worth knowing before reading further:
#
#   `tock start` while something is already running closes the running activity
#   at the new start time and opens the new one. It is a *switch*, not an error
#   and not a second parallel timer.
#
# So there is no separate switch command below - `tk` covers both "begin" and
# "move on to the next thing", which is what makes it cheap enough to actually
# use. The cost of tracking is remembering to start; everything here exists to
# push that cost toward zero.
#
# Callers must use `_check_gum_cmd || return 1`: on its own the call reports the
# problem but does not stop the caller from running on without gum.
source "$ZDOTDIR/src/functions.zsh"

# The tag vocabulary, and the *only* one - these six must stay identical to
# theme.tag_colors in ~/.config/tock/tock.yaml, which is what gives each of them
# a colour in the calendar view. A tag typed by hand outside this list still
# records fine, it just renders in the default colour and, more to the point,
# starts the drift (meeting/meetings/mtg) that makes tag reports meaningless.
typeset -ga _TOCK_TAGS=(deep meeting review ops admin learning)

# The project name for wherever you are standing. The git repository's root
# directory is the right unit of work far more often than $PWD is: it stays
# constant while you move between src/ and test/, which is exactly the property
# that makes a week of entries aggregate into something readable. Outside a
# repository the current directory is the best guess available.
function _tock_project() {
  local root
  if root=$(git rev-parse --show-toplevel 2> /dev/null) && [[ -n "$root" ]]; then
    print -r -- "${root:t}"
  else
    print -r -- "${PWD:t}"
  fi
}

# tk [description...]   start, or switch to, an activity in the current project
#
#   tk                       ask for a description (and optionally a tag)
#   tk fix the CSV exporter   start immediately, project inferred
#   tk -p Ops -d oncall -t 14:00   passed straight through to `tock start`
#
# The flag form is the escape hatch: as soon as the first argument looks like a
# flag, nothing here interprets anything and `tock start` gets the arguments
# verbatim, so every option the binary grows keeps working without this function
# having to learn about it.
function tk() {
  if [[ "${1-}" == -* ]]; then
    tock start "$@"
    return
  fi

  local project desc tag
  local -a tag_args=()
  project=$(_tock_project)

  if (($#)); then
    # Unquoted `$*` on purpose: `tk fix the CSV exporter` should read as one
    # description rather than needing quotes around it. Quoting still works.
    desc="$*"
  else
    _check_gum_cmd || return 1

    desc=$(gum input --header="Working on what? (${project})" --placeholder="description") || return 1
    [[ -n "$desc" ]] || {
      print -u2 -- "tk: nothing started (empty description)"
      return 1
    }

    # Escape here means "no tag", not "abort" - a tag is the optional half, and
    # having to re-type the description because you did not want one would make
    # the picker cost more than it saves.
    tag=$(gum choose --header="Tag? (esc for none)" -- "${_TOCK_TAGS[@]}") || tag=""
  fi

  # An array rather than ${tag:+--tag "$tag"}: zsh does not word-split the
  # result of a parameter expansion, so that idiom hands tock the single
  # argument `--tag deep` instead of the two it needs. An empty "${array[@]}"
  # expands to no arguments at all, which is the case being guarded.
  [[ -n "$tag" ]] && tag_args=(--tag "$tag")

  tock start -p "$project" -d "$desc" "${tag_args[@]}"
}

# tockpick [n]   pick one of the last n activities and start it again
#
# Exported to non-interactive shells as `tockpick` via ~/.local/bin/tockpick ->
# zshfn, which is what lets the tmux `prefix + Space` menu open it in a popup.
# That symlink is the reason this function has a full name rather than living
# only as the `tkr` alias below - see the header of dot_local/bin/executable_zshfn.
#
# `tock continue N` exists and is one process fewer, but it counts backwards
# through *its own* idea of recent order; re-issuing the project and description
# explicitly means what you picked is what starts, which matters when the list
# has been filtered down to one line.
function tockpick() {
  _check_gum_cmd || return 1
  command -v jq > /dev/null 2>&1 || {
    print -u2 -- "tockpick requires 'jq' to be installed."
    return 1
  }

  local -a rows
  # Tab-separated so the two fields survive a description containing any of the
  # punctuation a nicer-looking separator would use. tock's log is one line per
  # activity, so neither field can contain a newline to begin with.
  #
  # ${(f)…} splits on newlines and nothing else, which is the whole point - the
  # array must not be re-split on the spaces inside a description. shellcheck has
  # no zsh mode and reads it as bash, where the syntax does not exist.
  # shellcheck disable=SC2206,SC2296
  rows=(${(f)"$(tock last --json -n "${1:-20}" 2> /dev/null | jq -r '.[]? | "\(.project)\t\(.description)"')"})

  ((${#rows})) || {
    print -u2 -- "tockpick: nothing tracked yet - start something with 'tk'"
    return 1
  }

  local pick
  pick=$(print -rl -- "${rows[@]}" | gum filter --header="Resume which activity?" --placeholder="type to filter") || return 1
  [[ -n "$pick" ]] || return 1

  tock start -p "${pick%%$'\t'*}" -d "${pick#*$'\t'}"
}

# tkn   one line saying what is running, or that nothing is
#
# `tock current` on its own prints a table with a header, which is the right
# answer at a prompt you typed it at and the wrong one for a shell prompt, a
# notification, or a script. -F is a Go template over the same data.
function tkn() {
  local line
  line=$(tock current -F '{{.Project}} ▸ {{.Description}}  {{.DurationHMS}}' 2> /dev/null)
  if [[ -n "$line" ]]; then
    print -r -- "$line"
  else
    print -r -- "not tracking"
  fi
}

# tkd [--yesterday|--date YYYY-MM-DD]   what today went to
#
# The running activity is counted too, measured up to now, so the total is
# "today so far" rather than "today, banked" - which is why the tmux segment can
# show this number directly without adding the elapsed time to it.
function tkd() {
  if (($#)); then
    tock report "$@"
  else
    tock report --today
  fi
}

# The short forms. `tk` is the one that has to be short - it is typed several
# times a day and every keystroke is friction against tracking at all - and the
# rest follow the same two-letter stem so they are one namespace rather than
# seven unrelated names to recall.
alias tks='tock stop'          # stop, banking the current activity
alias tkc='tock continue'      # start a fresh entry with the last one's details
alias tkr='tockpick'           # resume: pick from history
alias tkl='tock list'          # the interactive calendar TUI
alias tkw='tock watch'         # full-screen stopwatch for the running activity
alias tka='tock analyze'       # deep-work / context-switching / chronotype stats

# Completion, from cobra's own generator (~7 ms, measured).
#
# Two ordering constraints, both silent when broken: compinit must already have
# run, and carapace must have been sourced first. carapace bridges other
# completion systems and would otherwise claim `tock` generically - sourcing
# cobra's `#compdef tock` after it means the tool's own flag-aware completion
# wins. init.zsh sources this file well after both.
if [[ -o interactive ]] && command -v tock > /dev/null 2>&1; then
  # shellcheck disable=SC1090
  source <(tock completion zsh)
fi
