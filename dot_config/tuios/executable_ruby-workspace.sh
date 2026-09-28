#!/bin/sh
# Create (or re-attach to) the "ruby" workspace: the top/bottom split that
# WezTerm's second tab used to build with its own multiplexer, now a tuios
# session.
#
#   +--------------------------------------+
#   |                                      |
#   |                 top                  |
#   |                                      |
#   +--------------------------------------+
#   |                bottom                |
#   +--------------------------------------+
#
# Usage:
#   ruby-workspace.sh [session-name]
#
#   The session defaults to "ruby" and opens in the current directory. If the
#   session already exists, this attaches to it instead of building another,
#   so the panes and what runs in them survive closing the tab or quitting
#   WezTerm. The tuios daemon also saves each session's layout to disk and
#   restores it when it starts, so the split survives a reboot too (with new
#   shells). `tuios kill-session ruby` discards the session, and the next run
#   builds a fresh one.
#
# THE SPLIT STARTS AT 50/50, NOT THE 70/30 THE WEZTERM TAB HAD. Nothing in
# tuios 0.8.0 can set a split ratio from a script. The one way to do it from
# outside, `tuios send-keys` with the layout prefix's resize_height_70, makes
# the client retile on its own: the panes come out side by side, and the client
# no longer agrees with the layout the daemon reports. Real keypresses do not
# do this. So in a fresh session, press Ctrl-S L Shift-7 once with the top pane
# focused (it is focused already). The session keeps the ratio from then on,
# through detaches and restores.
#
# Leader (prefix) is Ctrl-S, as in tmux; see config.toml next to this file.

set -eu

if ! command -v tuios > /dev/null 2>&1; then
  echo "ruby-workspace.sh: tuios is not installed or not on PATH" >&2
  # Drop to a shell rather than let the tab close at once with no clue why.
  exec "${SHELL:-/bin/sh}"
fi

# 0.8.0 added split-window and focus-window, which build the layout below, and
# the [startup] table in config.toml. On 0.7.0 the tab opened on tuios's empty
# welcome screen instead, with nothing to say why. This tests for the command
# rather than parsing the version, so a HEAD build passes too.
if ! tuios split-window --help > /dev/null 2>&1; then
  found=$(tuios --version 2> /dev/null | sed -n '1s/^tuios version \([^ ]*\).*/\1/p')
  echo "ruby-workspace.sh: needs tuios 0.8.0 or newer, found ${found:-an unknown version}." >&2
  # kill-server as well: a 0.7.0 daemon cannot serve a 0.8.0 client.
  echo "Upgrade with: brew update && brew upgrade tuios && tuios kill-server" >&2
  exec "${SHELL:-/bin/sh}"
fi

session=${1:-ruby}

# Start the daemon before asking about the session. Only a running daemon
# restores the sessions saved on disk, so without this a ruby session saved
# before a reboot would look missing, and `tuios new` would fail on the name
# as soon as its own daemon restored it. The call does nothing when a daemon
# is already running.
tuios start-server > /dev/null 2>&1 || true

if tuios session-info -s "$session" > /dev/null 2>&1; then
  exec tuios attach "$session"
fi

# `until` with a cap of about 10 seconds. The commands below talk to the
# attached client, and none exists until `tuios new` at the bottom has created
# the session and attached, so each one retries instead of sleeping a guessed
# amount. Giving up leaves whatever was built so far.
retry() {
  tries=0
  until "$@" > /dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -lt 100 ] || return 1
    sleep 0.1
  done
}

build() {
  retry tuios split-window horizontal -s "$session" || return 0
  # The split focuses the new bottom pane. With two panes, the previous one is
  # the top pane. Not `--direction up`: right after the split the new pane is
  # not in the layout yet, so its first try always failed, and the client
  # showed each failure as a "Remote error: no window up" toast.
  retry tuios focus-window -s "$session" --relative prev || return 0
}

# Detached from the terminal: tuios is about to take the screen over, and
# nothing this prints should draw over it.
build < /dev/null > /dev/null 2>&1 &

exec tuios new "$session"
