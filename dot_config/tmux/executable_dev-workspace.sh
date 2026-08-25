#!/bin/sh
# Create (or re-attach to) the "opal" coding workspace: the six-pane
# arrangement build_opal_layout() makes in wezterm.lua, rebuilt in tmux.
#
#   +------+----------------------------+-------+
#   |      |                            | 2     |
#   |      |         1 editor           | agent |
#   |      |         85% x 90%          +-------+
#   |      |                            | 3 aux |
#   |      |                            |       |
#   +------+----------------------------+-------+
#   | 4    |         5 shell            | 6 srv |  <- full width, 10% tall
#   | logs |                            |       |
#   +------+----------------------------+-------+
#
# Usage:
#   dev-workspace.sh [-r] [session-name] [directory]
#
#   -r rebuilds: it kills an existing session of that name first, so a change to
#   the pane *structure* below takes effect. Sizes do not need it — see the hook.
#
#   Both are optional. The session defaults to the current directory's name and
#   every pane opens in that directory, so running this inside a repo gives you
#   a workspace named after it. Running it again re-attaches instead of
#   rebuilding, so the panes and whatever is running in them survive detaching,
#   closing the terminal tab, and quitting WezTerm entirely.
#
# Optional auto-start commands (empty by default — panes are plain shells):
#   TMUX_WS_EDITOR=nvim   TMUX_WS_AGENT=claude   TMUX_WS_AUX=codex
#   TMUX_WS_SHELL=...     TMUX_WS_LOGS='...'     TMUX_WS_SRV='kubectl port-forward ...'
#
# Sizes mirror the WezTerm layout: the strip is 10% of the height and spans the
# full width, the right column is 15% of the width and stops above the strip,
# and the strip's outer panes are 15% of what is left of it — so srv ends up the
# same 15% as the column above it and the two borders line up.
#
# WHY THE SIZES ARE RE-APPLIED ON EVERY ATTACH (relayout + set-hook, below):
# splitting at build time is not enough. WezTerm spawns this tab at its default
# 80x24 and only maximizes it a moment later, so `tput` here reports 80x24 no
# matter how big the display is. tmux then *scales* the finished layout when the
# client attaches at the real size rather than re-deriving it, and the result is
# proportionally wrong in a way no amount of care in the splits can prevent:
# a 318x94 window came out with the editor at 168x52 (53% of the width) instead
# of 270x83 (85%), because the 30-column floor was 37% of an 80-column window.
# Re-deriving on client-attached and client-resized fixes that, and also means
# moving between a laptop screen and an external monitor re-normalizes instead
# of accumulating drift.
#
# Caveat inherited from opal: 15% of the width is 30-ish columns on most
# displays, and Claude Code / Codex wrap badly below ~80. If you actually run an
# agent in pane 2, raise the 15 in `right_w` inside relayout().

set -eu

# Absolute path to this file, so the tmux hook can re-invoke it later from a
# working directory that has nothing to do with where it was launched from.
self=$0
case "$self" in
  /*) ;;
  *) self=$(cd "$(dirname "$self")" && pwd)/$(basename "$self") ;;
esac

if ! command -v tmux > /dev/null 2>&1; then
  echo "dev-workspace.sh: tmux is not installed or not on PATH" >&2
  # Drop to a shell rather than let the pane close instantly with no clue why.
  exec "${SHELL:-/bin/sh}"
fi

# Re-derive every pane size from the window's *current* size. Idempotent, so it
# is safe to run on every attach and every resize.
relayout() {
  win=$1

  # Pane ids are recorded at build time rather than looked up by title: a shell
  # prompt that sets the terminal title overwrites pane_title, and then a
  # title-based lookup silently resizes nothing.
  ids=$(tmux show-option -w -qv -t "$win" @opal_panes 2> /dev/null) || return 0
  [ -n "$ids" ] || return 0

  size=$(tmux display-message -p -t "$win" '#{window_width} #{window_height}' 2> /dev/null) || return 0
  w=${size%% *}
  h=${size##* }
  case "$w$h" in '' | *[!0-9]*) return 0 ;; esac
  # Below this there is no arrangement worth forcing; leave tmux's own alone.
  [ "$w" -ge 60 ] && [ "$h" -ge 20 ] || return 0

  right_w=$((w * 15 / 100))
  [ "$right_w" -ge 30 ] || right_w=30
  bottom_h=$((h * 10 / 100))
  [ "$bottom_h" -ge 5 ] || bottom_h=5

  # -1 for the border between editor and the column, -2 for the border above the
  # strip plus the editor's own pane-border-status title row.
  editor_w=$((w - right_w - 1))
  editor_h=$((h - bottom_h - 2))

  set -- $ids
  # $1 editor  $2 agent  $3 aux  $4 logs  $5 shell  $6 srv
  [ $# -eq 6 ] || return 0

  tmux resize-pane -t "$1" -x "$editor_w" -y "$editor_h"
  tmux resize-pane -t "$2" -y $(((editor_h - 1) / 2))
  tmux resize-pane -t "$6" -x "$right_w"
  tmux resize-pane -t "$4" -x $((editor_w * 15 / 100))
}

# Hook entry point. Kept before the interactive path so it never tries to attach.
if [ "${1:-}" = "--relayout" ]; then
  relayout "${2:?dev-workspace.sh --relayout needs a window target}"
  exit 0
fi

rebuild=0
case "${1:-}" in
  -r | --rebuild)
    rebuild=1
    shift
    ;;
esac

start_dir=${2:-$PWD}
session=${1:-${start_dir##*/}}
# tmux treats "." and ":" as separators inside target specifiers, so a session
# named after a directory like "my.project" becomes unaddressable. Fold them.
session=$(printf '%s' "$session" | tr ' .:' '___')
[ -n "$session" ] || session=dev

autostart() {
  [ -n "$2" ] || return 0
  tmux send-keys -t "$1" "$2" C-m
}

# Kill before the has-session check, so the build path below runs. Anything
# still running in the old panes dies with it, which is why this is opt-in.
[ "$rebuild" -eq 0 ] || tmux kill-session -t "=$session" 2> /dev/null || true

# "=name" is an exact match. Without it tmux accepts a prefix, so an existing
# "dotfiles-old" would satisfy the check and this would attach to the wrong one.
if ! tmux has-session -t "=$session" 2> /dev/null; then
  # A best guess only. It is usually wrong (see the note at the top), and the
  # relayout below is what actually gets the proportions right.
  cols=$(tput cols 2> /dev/null || echo 200)
  lines=$(tput lines 2> /dev/null || echo 50)

  # -P -F prints each new pane's id so every split targets an exact pane
  # instead of depending on which one happens to be active.
  editor=$(tmux new-session -d -s "$session" -n opal -c "$start_dir" \
    -x "$cols" -y "$lines" -P -F '#{pane_id}')

  # A split that fails for want of space would otherwise leave a half-built
  # session behind, which every later run then cheerfully re-attaches to.
  trap 'tmux kill-session -t "=$session" 2> /dev/null || true' EXIT

  # Order matters, and it is the whole difference from the old cockpit layout.
  # The strip is split off the untouched window first, so it runs the full
  # width; everything after it divides only what is above. Splitting the agent
  # column off first (what the cockpit did) gives that column the full height
  # and stops the strip short of the window edge instead.
  shell=$(tmux split-window -t "$editor" -v -c "$start_dir" -P -F '#{pane_id}')
  agent=$(tmux split-window -t "$editor" -h -c "$start_dir" -P -F '#{pane_id}')
  aux=$(tmux split-window -t "$agent" -v -c "$start_dir" -P -F '#{pane_id}')
  srv=$(tmux split-window -t "$shell" -h -c "$start_dir" -P -F '#{pane_id}')
  # -b puts the new pane before the target, i.e. to its left.
  logs=$(tmux split-window -t "$shell" -h -b -c "$start_dir" -P -F '#{pane_id}')

  trap - EXIT

  tmux set-option -w -t "$session:opal" pane-border-status top
  tmux set-option -w -t "$session:opal" pane-border-format ' #P #{pane_title} '
  tmux set-option -w -t "$session:opal" @opal_panes "$editor $agent $aux $logs $shell $srv"

  tmux select-pane -t "$agent" -T ai_chat
  tmux select-pane -t "$aux" -T aux
  tmux select-pane -t "$logs" -T logs
  tmux select-pane -t "$shell" -T shell
  tmux select-pane -t "$srv" -T srv

  # Quoted so a path with spaces survives tmux's own parsing of the hook body.
  hook="run-shell -b \"'$self' --relayout '$session:opal'\""
  tmux set-hook -t "$session" client-attached "$hook"
  tmux set-hook -t "$session" client-resized "$hook"
  relayout "$session:opal"

  autostart "$agent" "${TMUX_WS_AGENT:-}"
  autostart "$aux" "${TMUX_WS_AUX:-}"
  autostart "$logs" "${TMUX_WS_LOGS:-}"
  autostart "$shell" "${TMUX_WS_SHELL:-}"
  autostart "$srv" "${TMUX_WS_SRV:-}"
  autostart "$editor" "${TMUX_WS_EDITOR:-}"

  tmux select-pane -t "$editor" -T editor
  # `select-pane -T` only sets the title, it does not move focus, so this
  # second call is what actually lands you in the editor rather than in logs
  # (the last pane split, which tmux leaves active).
  tmux select-pane -t "$editor"
fi

exec tmux attach-session -t "=$session"
