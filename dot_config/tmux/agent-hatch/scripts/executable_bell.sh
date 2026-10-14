#!/usr/bin/env bash
# Forward a bell from a dedicated agent session to its origin window's pane, so
# tmux's bell machinery picks it up even though the ringing session is separate.
#
#   bell.sh <session-name>   bound to the alert-bell hook via #{hook_session_name}
set -uo pipefail

session="${1:-}"
[ -n "$session" ] || exit 0

# The trailing colon makes "=name" an exact session match; without it a pane
# target looks the name up as a window.
IFS=$'\t' read -r dedicated origin <<EOF
$(tmux display-message -p -t "=$session:" $'#{@hatch_dedicated}\t#{@hatch_origin}' 2>/dev/null)
EOF
[ -n "$dedicated" ] && [ -n "$origin" ] || exit 0

# The origin window's active pane, and whether the origin is itself a dedicated
# session — skipped, to avoid a forwarding loop.
IFS=$'\t' read -r tty origin_dedicated <<EOF
$(tmux display-message -p -t "$origin" $'#{pane_tty}\t#{@hatch_dedicated}' 2>/dev/null)
EOF
[ -n "$tty" ] && [ -z "$origin_dedicated" ] && printf '\a' 2>/dev/null >"$tty"
exit 0
