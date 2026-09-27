#!/usr/bin/env zsh
# vim: filetype=zsh
#
# Shared gum helpers. Modules that call them source this file themselves, the
# way they source functions.zsh, so they still work when zshfn runs them
# without init.zsh.

function _check_gum_cmd() {
  command -v gum > /dev/null 2>&1 || {
    # funcstack[2] is the calling function, so the message names it.
    echo "${funcstack[2]:-gum} requires 'gum' to be installed." >&2
    return 1
  }
}

# _gum_spin <title> <command...>
#
# gum spin, then clear whatever the terminal sent back meanwhile. gum probes
# the terminal on startup (see _bazel_spin_while in bazel.zsh) but spin never
# reads the replies, so they wait in the input queue and the next reader takes
# them for keystrokes: fzf gets `?2026;2$y?2027;0$y` in its query, and a
# prompt gets it typed in. With min 0 / time 1, cat takes what is queued and
# stops after a tenth of a second with nothing more. Keys typed ahead during
# the spin go the same way.
#
# The exit status is the command's, and its stdout passes through, so
# `out=$(_gum_spin ...)` captures it as with gum spin. Without a controlling
# terminal there is nothing to clear, and /dev/tty would fail to open.
function _gum_spin() {
  local title=$1 rc saved
  shift

  gum spin --spinner=minidot --show-error --title="$title" -- "$@"
  rc=$?

  # The braces carry the 2>: zsh reports a failed open of /dev/tty outside
  # the command's own redirections, so a 2> on stty itself would not hide it.
  if { saved=$(stty -g < /dev/tty); } 2> /dev/null; then
    stty -icanon -echo min 0 time 1 < /dev/tty
    cat < /dev/tty > /dev/null
    stty "$saved" < /dev/tty
  fi
  return $rc
}

# _gum_menu <header> <title> <description> <callback> [...] [-- <arg>...]
#
# A search menu over title/description/callback triples: typing filters on
# the title and the description, and Enter runs the picked entry's callback
# with the args after `--`. A callback is a command line, split into words the
# way the shell would - quotes honoured, nothing expanded - so it can carry
# arguments of its own. It runs in the current shell rather than a subshell,
# so it can cd or export. Returns the callback's status, or gum filter's when
# the menu is escaped.
function _gum_menu() {
  local header=$1 pick row sep=--
  shift
  # $sep rather than a literal --: shfmt reads a bare -- in a subscript as a
  # decrement and refuses the file, and a quoted "--" is matched quotes and
  # all. Not found, end is one past the last argument.
  local -i end=${argv[(ie)$sep]} i width=0
  local -a entries=("${(@)argv[1,end-1]}") args=("${(@)argv[end+1,-1]}") rows cmd

  ((${#entries} % 3 == 0)) || {
    print -u2 "_gum_menu: entries come in threes: title, description, callback"
    return 2
  }

  for ((i = 1; i < ${#entries}; i += 3)); do
    ((${#entries[i]} > width)) && width=${#entries[i]}
  done
  # gum filter hands back the row, not an index, so each row has to be
  # findable again - and a padded title with no description after it would
  # end in spaces gum may not return.
  for ((i = 1; i < ${#entries}; i += 3)); do
    row=${entries[i]}
    [[ -n ${entries[i + 1]} ]] && row="${(r:width:)row}  ${entries[i + 1]}"
    rows+=("$row")
  done

  pick=$(print -rl -- "${rows[@]}" \
    | gum filter --header="$header" --placeholder="Search...") || return
  i=${rows[(ie)$pick]}
  ((i <= ${#rows})) || return 1

  cmd=("${(@Q)${(z)entries[3 * i]}}")
  "${cmd[@]}" "${args[@]}"
}
