#!/usr/bin/env bash
# Launch (or re-attach to) an agent's session for a directory, shown in a popup.
# Args: <agent> <dir> [origin-window-id]   (the last two expanded by run-shell
# in the binding)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR/helpers.sh"

agent="${1:-claude}"
path="${2:-$PWD}"
window="${3:-}"

cmd="$(get_tmux_option "@hatch_${agent}_command" "$agent")"
args="$(get_tmux_option "@hatch_${agent}_args" '')"
[ -n "$args" ] && cmd="$cmd $args"
w="$(get_tmux_option @hatch_popup_width '90%')"
h="$(get_tmux_option @hatch_popup_height '90%')"

# One session per agent and directory, so Claude and Copilot in the same
# project each get their own.
session="${agent}-$(session_hash "$path")"

# The key was pressed inside a dedicated session, i.e. inside a popup already.
# Asked of the window the key was pressed in: without a target, tmux would
# answer for whichever session was active last.
if [ -n "$(tmux display-message -p ${window:+-t "$window"} '#{@hatch_dedicated}' 2>/dev/null)" ]; then
  tmux display-message '🫪 Popup window already open'
  exit 0
fi

if ! tmux has-session -t "=$session" 2>/dev/null; then
  [ -d "$path" ] || {
    tmux display-message "agent-hatch: $path no longer exists"
    exit 0
  }
  tmux new-session -d -s "$session" -c "$path" "$cmd"
fi

mark_dedicated "$session" "$agent" "$window"

tmux display-popup -w "$w" -h "$h" -b rounded -T " $(agent_title "$agent") " \
  -E "tmux attach-session -t '=$session'"
