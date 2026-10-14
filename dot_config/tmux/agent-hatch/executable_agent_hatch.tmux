#!/usr/bin/env bash
# agent-hatch
#
# List, monitor status, and jump across coding agents - Claude Code, Copilot
# CLI, anything else whose hooks report in - from a single popup.
#
# A fork of craftzdog/tmux-claude-hatch (MIT, see LICENSE). Upstream reads
# Claude Code's own session files and is Claude-only by design; here each agent's
# hooks write its status onto its tmux pane (hooks/status.sh), which is what lets
# one picker cover them all. tmux.conf runs this file; it reads user options
# (with defaults) and installs the key bindings.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/helpers.sh
. "$CURRENT_DIR/scripts/helpers.sh"

# One key for every agent: a menu to pick which one to launch (or re-attach
# to) for the current pane's directory. Its entries come from @hatch_agents
# when the key is pressed, so another agent joins with
# `set -g @hatch_agents 'claude copilot gemini'` and no binding of its own.
tmux bind-key "$(get_tmux_option @hatch_launch_key 'y')" \
  run-shell "$CURRENT_DIR/scripts/menu.sh #{q:client_name} #{pane_id}"

# Open the picker. When pressed from inside a session popup, list.sh closes that
# popup first so the picker opens full-size on the outer client.
tmux bind-key "$(get_tmux_option @hatch_list_key 'u')" \
  run-shell "$CURRENT_DIR/scripts/list.sh '#{q:client_name}'"

# Forward a bell from a dedicated session to its origin window's pane, so
# tmux's own bell machinery (window-status-bell-style, and terminal
# passthrough when that window is visible) picks it up even though the
# session that rang is a separate session from the origin.
if [ "$(get_tmux_option @hatch_forward_bell 'on')" = 'on' ]; then
  tmux set-hook -g alert-bell \
    "run-shell -b \"$CURRENT_DIR/scripts/bell.sh '#{q:hook_session_name}'\""
fi
