#!/usr/bin/env bash
# Pick an agent to launch (or re-attach to) for the current pane's directory.
# Args: <client> <pane>   (expanded by run-shell in the binding)
#
# A tmux display-menu - the popup tmux-which-key draws, placed where it places
# its own - with one entry per agent in @hatch_agents, keyed by
# @hatch_<agent>_key, and the picker under them. Built when the key is pressed,
# so an agent added to @hatch_agents needs no binding of its own. With a single
# agent there is nothing to choose, and it launches straight away.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR/helpers.sh"

client="${1:-}"
pane="${2:-}"

read -r -a agents <<<"$(get_tmux_option @hatch_agents 'claude copilot')"
[ "${#agents[@]}" -gt 0 ] || exit 0

if [ "${#agents[@]}" -eq 1 ]; then
  IFS=$'\t' read -r path window <<EOF
$(tmux display-message -p ${pane:+-t "$pane"} $'#{pane_current_path}\t#{window_id}' 2>/dev/null)
EOF
  exec "$DIR/launch.sh" "${agents[0]}" "$path" "$window"
fi

# "##{q:…}", not "#{q:…}": tmux expands a menu item's formats *before* parsing
# it as a command, so a #{q:} escape would be eaten by that parse inside the
# double quotes, and a directory with a space would reach launch.sh in two
# pieces. Doubled, the menu's own expansion leaves a plain #{q:…} for run-shell
# to expand against <pane>, and the escape survives to the shell.
items=()
for agent in "${agents[@]}"; do
  case "$agent" in
  claude) default_key='c' ;;
  copilot) default_key='o' ;;
  gemini) default_key='g' ;;
  *) default_key="${agent:0:1}" ;;
  esac
  items+=(
    "$(agent_title "$agent")"
    "$(get_tmux_option "@hatch_${agent}_key" "$default_key")"
    "run-shell \"$DIR/launch.sh $agent ##{q:pane_current_path} ##{q:window_id}\""
  )
done
items+=(
  ''
  'Picker'
  "$(get_tmux_option @hatch_list_key 'u')"
  "run-shell \"$DIR/list.sh ##{q:client_name}\""
)

tmux display-menu ${client:+-c "$client"} ${pane:+-t "$pane"} -x R -y P \
  -T '#[align=centre,bold] Launch agent ' "${items[@]}"
