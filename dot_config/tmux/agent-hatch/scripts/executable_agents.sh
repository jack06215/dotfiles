#!/usr/bin/env bash
# One row per coding agent that hooks/status.sh has recorded on a tmux pane.
#
#   agents.sh            picker rows, whatever needs you first
#   agents.sh --counts   "<waiting> <idle> <busy>", for the status bar segment
#
# All of it comes from one `tmux list-panes`: each agent's hooks keep its state
# on its own pane (see hooks/status.sh), so there is no process scan, no agent
# CLI to ask, and nothing worth caching. A record whose agent is no longer the
# pane's foreground command is stale - the agent exited without its SessionEnd -
# and is skipped.
#
#   Row: rank \t pane_id \t kind \t icon \t agent \t age \t loc \t path
#   rank/pane_id/kind are hidden from the display via fzf's --with-nth.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
. "$DIR/helpers.sh"

mode=rows
[ "${1:-}" = --counts ] && mode=counts

# #{@hatch_dedicated} is a session option, which a pane's format inherits; it
# marks the sessions launch.sh created.
tmux list-panes -a -F $'#{pane_current_command}\t#{pane_id}\t#{@hatch_dedicated}\t#{session_name}:#{window_index}.#{pane_index}\t#{pane_current_path}\t#{@hatch}' 2>/dev/null |
  awk -F'\t' -v mode="$mode" -v now="$(date +%s)" -v home="$HOME" '
    $6 == "" { next }
    {
      # agent|state|seen|session|command - the command last, rejoined in case
      # it holds a "|" of its own.
      n = split($6, r, "|")
      command = r[5]
      for (i = 6; i <= n; i++) command = command "|" r[i]
      if ($1 != command) next

      if (mode == "counts") { count[r[2]]++; next }

      if      (r[2] == "waiting") { icon = "\033[33m●\033[0m waiting"; rank = 0 }  # yellow - needs input
      else if (r[2] == "idle")    { icon = "\033[32m●\033[0m idle   "; rank = 1 }  # green  - done, your turn
      else if (r[2] == "busy")    { icon = "\033[31m●\033[0m working"; rank = 3 }  # red    - busy, leave it
      else                        { icon = "\033[90m●\033[0m   ?    "; rank = 2 }  # grey   - unrecognised status

      secs = (r[3] ~ /^[0-9]+$/) ? now - r[3] : 1e12   # unknown activity sorts last
      mins = int(secs / 60)
      if      (secs == 1e12)  age = "-"
      else if (mins < 60)     age = mins "m"
      else if (mins < 2880)   age = int(mins / 60) "h"
      else                    age = int(mins / 1440) "d"

      # A colour per agent, so the column reads at a glance. 7 is "copilot".
      if      (r[1] == "claude")  colour = "\033[38;5;173m"
      else if (r[1] == "copilot") colour = "\033[38;5;141m"
      else if (r[1] == "gemini")  colour = "\033[38;5;75m"
      else                        colour = "\033[0m"
      name = sprintf("%s%-7s\033[0m", colour, r[1])

      kind = ($3 != "") ? "dedicated" : "loose"

      path = $5
      if (index(path, home) == 1) path = "~" substr(path, length(home) + 1)

      printf "%d\t%s\t%s\t%s\t%s\t%s\t%5s\t%s\t%s\n",
        secs, rank, $2, kind, icon, name, age, $4, path
    }
    END {
      if (mode == "counts")
        printf "%d %d %d\n", count["waiting"], count["idle"], count["busy"]
    }
  ' |
  if [ "$mode" = counts ]; then
    cat
  else
    # status: rank asc (what needs you floats up), then age asc so whatever just
    # went idle sits at the top of its group. recent: age asc alone. The age
    # column mixes units ("5m", "3h", "2d"), so the sort runs on a leading
    # seconds column, cut off once it has served.
    if [ "$(get_tmux_option @hatch_sort 'status')" = recent ]; then
      sort_keys='-k1,1n'
    else
      sort_keys='-k2,2n -k1,1n'
    fi
    # shellcheck disable=SC2086 # deliberate split into separate sort keys
    sort -t$'\t' $sort_keys | cut -f2-
  fi
