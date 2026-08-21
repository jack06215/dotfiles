#!/bin/sh
# Recreate the WezTerm "opal" pane arrangement inside tmux, then attach to it.
#
# The "tmux" startup tab in wezterm.lua is deliberately a SINGLE WezTerm pane:
# tmux manages its own panes, so splitting in WezTerm as well would stack two
# pane managers in one tab — every tmux keybinding would then apply to only one
# sixth of the screen. build_opal_layout() in wezterm.lua is the WezTerm-side
# equivalent of the splits below; keep the two in step if either changes.
#
#   +-------+------------------+--------+
#   |                          | right  |
#   |          main            +--------+
#   |                          | right2 |
#   +-------+------------------+--------+
#   |  bl   |      bottom      |   br   |  <- 10% of the window height
#   +-------+------------------+--------+
#
# Usage: opal-layout.sh [session-name]        (default session: opal)

set -eu

session="${1:-opal}"

if ! command -v tmux >/dev/null 2>&1; then
  echo "opal-layout.sh: tmux is not installed or not on PATH" >&2
  # Fall back to an interactive shell rather than letting the pane close
  # instantly, which would leave no clue as to what went wrong.
  exec "${SHELL:-/bin/sh}"
fi

# "=name" is an exact match; without it tmux would also accept a prefix, so a
# session called "opalescent" would satisfy the check and never get a layout.
if ! tmux has-session -t "=$session" 2>/dev/null; then
  # Build the session at this terminal's real size. A detached session defaults
  # to 80x24, where the 10% bottom strip rounds down to two rows and the rest of
  # the splits come out badly proportioned; tmux keeps those bad proportions
  # when the client later attaches and resizes.
  cols=$(tput cols 2>/dev/null || echo 200)
  lines=$(tput lines 2>/dev/null || echo 50)

  # -P -F prints the new pane's id, so each split can target an exact pane
  # rather than relying on which pane happens to be active.
  main=$(tmux new-session -d -s "$session" -x "$cols" -y "$lines" -P -F '#{pane_id}')
  bottom=$(tmux split-window -t "$main" -v -l 10% -P -F '#{pane_id}')
  right=$(tmux split-window -t "$main" -h -l 15% -P -F '#{pane_id}')
  tmux split-window -t "$right" -v -l 50%
  tmux split-window -t "$bottom" -h -l 15%
  # -b puts the new pane before the target: with -h that means to its left.
  tmux split-window -t "$bottom" -hb -l 15%

  tmux select-pane -t "$main"
fi

exec tmux attach-session -t "=$session"
