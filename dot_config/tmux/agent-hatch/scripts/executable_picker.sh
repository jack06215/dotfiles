#!/usr/bin/env bash
# Interactive picker for running coding agents.
#
#   picker.sh           fzf picker; on enter, jumps to the chosen agent.
#   picker.sh --list    print the rows only (used by fzf's ctrl-x reload).
#   picker.sh --kill <pane>
#                       stop the agent running in <pane> (used by ctrl-x).
#   picker.sh --copy <text>
#                       copy <text> to the clipboard (used by ctrl-y).
#   picker.sh --preview <pane>
#                       capture <pane> without its trailing blank lines, which
#                       would otherwise leave fzf's `follow` scrolled onto padding.
#
# Rows come from agents.sh, one per agent that reported into a tmux pane. Two
# kinds of row jump differently:
#   dedicated  an agent in a session launch.sh created (prefix + y) -
#              resumed in the popup, over the window it was launched from.
#   loose      an agent running in any other pane - focused in place.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR/helpers.sh"

# kill_agent <pane>
# SIGTERM to the pane's foreground process group leader. That is the agent:
# status.sh lets only the agent in the pane's foreground claim it, and the
# record is checked first, so a pane that has moved on to something else since
# the list was drawn is left alone.
kill_agent() {
  local tty command record pid
  IFS=$'\t' read -r tty command record <<EOF
$(tmux display-message -p -t "$1" $'#{pane_tty}\t#{pane_current_command}\t#{@hatch}' 2>/dev/null)
EOF
  # The record's last field, past agent|state|seen|session|.
  [ -n "$record" ] && [ "$command" = "${record#*|*|*|*|}" ] || return 0
  pid="$(ps -o tpgid= -t "${tty#/dev/}" 2>/dev/null | awk 'NR == 1 { print $1 }')"
  [ -n "$pid" ] && [ "$pid" -gt 1 ] && kill "$pid" 2>/dev/null
}

case "${1:-}" in
--list)
  exec "$DIR/agents.sh"
  ;;
--kill)
  kill_agent "${2:-}"
  exit 0
  ;;
--preview)
  # A line holding only escape codes (from -e) is still blank.
  tmux capture-pane -ept "${2:-}" 2>/dev/null |
    awk -v esc="$(printf '\033')" '
      { line = $0; gsub(esc "\\[[0-9;]*m", "", line) }
      line ~ /^[[:space:]]*$/ { held = held $0 "\n"; next }
      { printf "%s", held; held = ""; print }
    '
  exit 0
  ;;
--copy)
  copy_to_clipboard "${2:-}" &&
    tmux display-message "agent-hatch: copied ${2:-}"
  exit 0
  ;;
esac

command -v fzf >/dev/null 2>&1 || {
  tmux display-message "agent-hatch: fzf is required for the picker"
  exit 0
}

self="$DIR/picker.sh"
export FZF_DEFAULT_OPTS=''
# For @hatch_fzf_options binds that want to call back into the picker.
export HATCH_PICKER="$self"

# Arbitrary user fzf options (e.g. custom --bind or --preview-window)
extra_opts=()
fzf_options="$(get_tmux_option @hatch_fzf_options '')"
[ -n "$fzf_options" ] && eval "extra_opts=($fzf_options)"

# ctrl-x stops the agent itself: a dedicated session dies with its last window,
# while a loose pane keeps the shell that hosted it. The reload waits a beat so
# the agent has left the pane by the time agents.sh looks at it.
# ctrl-y copies the agent's location (session:window.pane, e.g.
# claude-88074b0e:1.1) and closes the picker.
sel=$("$DIR/agents.sh" | fzf --ansi --delimiter='\t' --with-nth=4,5,6,7,8 \
  --reverse --cycle --header='Agents · enter: jump · ctrl-x: kill · ctrl-y: copy' \
  --preview="$self --preview {2}" --preview-window='up,70%,follow' \
  --bind="ctrl-x:execute-silent($self --kill {2})+reload(sleep 0.3; $self --list)" \
  --bind="ctrl-y:execute-silent($self --copy {7})+abort" \
  --bind='change:first' \
  ${extra_opts[@]+"${extra_opts[@]}"})

[ -z "$sel" ] && exit 0
pane=$(printf '%s' "$sel" | cut -f2)
kind=$(printf '%s' "$sel" | cut -f3)

parent=$(tmux show-options -gqv @hatch_parent 2>/dev/null)
session=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null)

if [ "$kind" = loose ]; then
  # Focus the pane in place on the outer client. This popup closes on its own
  # when the script exits.
  if [ -n "$parent" ]; then
    tmux switch-client -c "$parent" -t "$session" 2>/dev/null
  else
    tmux switch-client -t "$session" 2>/dev/null
  fi
  tmux select-window -t "$pane" 2>/dev/null
  tmux select-pane -t "$pane" 2>/dev/null
  exit 0
fi

# Move the parent client to the window the session was launched from (best-effort),
# focus the chosen agent's own window inside that session, then resume it in THIS
# popup over the top. Falls back to resuming over the current window when
# origin/parent are unknown.
origin=$(tmux show-options -qv -t "$session" @hatch_origin 2>/dev/null)
[ -n "$origin" ] && [ -n "$parent" ] &&
  tmux switch-client -c "$parent" -t "$origin" 2>/dev/null

tmux select-window -t "$pane" 2>/dev/null
tmux select-pane -t "$pane" 2>/dev/null
tmux attach-session -t "$session"
