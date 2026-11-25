#!/usr/bin/env bash
# Resume a past agent conversation from atuin's thread store, in a dedicated
# session shown in a popup: the Resume entry of the prefix + y menu.
#
#   resume.sh <client> <dir> [origin-window-id]    from the menu: opens the popup
#   resume.sh --popup <client> [origin-window-id]  inside it: pick, then attach
#
# atuin's picker (`atuin threads resume`) runs in the popup, which starts in
# <dir> so that the picker's workspace filter opens on that repository's
# threads. The pick is a shell command, `cd -- <cwd> && claude --resume <id>`,
# and it becomes the new session's command.
#
# The session is named after that command, so there is one per thread. A name
# per directory, like launch.sh's, would collide with the agent session that
# directory may already have: the resumed thread would either replace it or be
# swallowed by it.
#
# For a thread that may be open in a running agent, atuin's chooser highlights
# "fork", which resumes a copy under a new session id. If its plain resume line
# is picked anyway and a pane is running that session, the popup jumps to that
# pane instead of starting it twice, because two agents writing one transcript
# would interleave it.
#
# The new session is attached inside this same popup, the way picker.sh
# attaches one, and not in a second popup: a popup opened while another is
# closing can come up without keyboard input (see list.sh).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR/helpers.sh"

if [ "${1:-}" != --popup ]; then
  client="${1:-}"
  path="${2:-$PWD}"
  window="${3:-}"

  # Same guard as launch.sh: the key was pressed inside a dedicated session,
  # i.e. inside a popup already.
  if [ -n "$(tmux display-message -p ${window:+-t "$window"} '#{@hatch_dedicated}' 2>/dev/null)" ]; then
    tmux display-message '🫪 Popup window already open'
    exit 0
  fi

  w="$(get_tmux_option @hatch_popup_width '90%')"
  h="$(get_tmux_option @hatch_popup_height '90%')"
  tmux display-popup ${client:+-c "$client"} -d "$path" -w "$w" -h "$h" -b rounded \
    -T ' Resume ' -E "$(printf '%q ' "$DIR/resume.sh" --popup "$client" "$window")"
  exit 0
fi

client="${2:-}"
window="${3:-}"

# The pick comes back in the shell widgets' protocol, on stderr while the
# picker draws on stdout, hence the swap: "__atuin_accept__:<command>".
# ATUIN_SHELL picks the syntax atuin quotes <cwd> in; tmux runs the command
# with default-shell.
shell="$(tmux show-options -gqv default-shell 2>/dev/null)"
shell="${shell##*/}"
case "$shell" in
zsh | bash | fish) ;;
*) shell=bash ;;
esac
pick="$(ATUIN_SHELL="$shell" atuin threads resume --shell-widget 3>&1 1>&2 2>&3)"
rc=$?
if [ "$rc" -ne 0 ]; then
  [ -n "$pick" ] && tmux display-message ${client:+-c "$client"} "agent-hatch: $(printf '%s\n' "$pick" | head -n 1)"
  exit 0
fi
cmd="${pick#__atuin_accept__:}"
[ -n "$cmd" ] || exit 0

# "cd -- <cwd> && <agent command>". The shell takes atuin's quoting off <cwd>.
dir=''
run="$cmd"
case "$cmd" in
'cd -- '*' && '*)
  eval "set -- ${cmd%% && *}" && dir="${3:-}"
  run="${cmd#* && }"
  ;;
esac
agent="${run%% *}"
agent="${agent##*/}"

# Is a pane already running this thread? Each agent's hooks record its session
# id in the pane's @hatch (agent|state|seen|session|command, see
# hooks/status.sh), and the resume command names that id. A record whose
# command is no longer the pane's foreground command is stale, as in
# agents.sh. The fields are split on \x1f, not a tab: read merges runs of a
# whitespace IFS, so an empty @hatch_dedicated would shift every later field.
while IFS=$'\x1f' read -r pane session dedicated current hatch; do
  [ -n "$hatch" ] || continue
  IFS='|' read -r _ _ _ sid owner <<<"$hatch"
  [ -n "$sid" ] && [ "$current" = "$owner" ] || continue
  case " $run " in
  *" $sid "*) ;;
  *) continue ;;
  esac
  tmux display-message ${client:+-c "$client"} 'agent-hatch: that thread is already open, jumped to it'
  tmux select-window -t "$pane" 2>/dev/null
  tmux select-pane -t "$pane" 2>/dev/null
  if [ -n "$dedicated" ]; then
    exec tmux attach-session -t "=$session"
  fi
  tmux switch-client ${client:+-c "$client"} -t "=$session" 2>/dev/null
  exit 0
done <<EOF
$(tmux list-panes -a -F $'#{pane_id}\x1f#{session_name}\x1f#{@hatch_dedicated}\x1f#{pane_current_command}\x1f#{@hatch}' 2>/dev/null)
EOF

session="${agent}-resume-$(session_hash "$cmd")"
if ! tmux has-session -t "=$session" 2>/dev/null; then
  if [ -n "$dir" ] && [ ! -d "$dir" ]; then
    tmux display-message ${client:+-c "$client"} "agent-hatch: $dir no longer exists"
    exit 0
  fi
  tmux new-session -d -s "$session" ${dir:+-c "$dir"} "$cmd"
fi

mark_dedicated "$session" "$agent" "$window"
exec tmux attach-session -t "=$session"
