# shellcheck shell=bash
# filetype=sh

# Agent teams are experimental and off by default. Turning them on in
# settings.json would be the obvious move, but it has a side effect worth
# avoiding: while teams are enabled, *any* subagent Claude names launches as a
# full teammate - a separate Claude instance inheriting this config's Opus and
# xhigh effort - so a team can form during ordinary delegation you never framed
# as team work. Opt in per session instead, and leave the global default alone.
#
# teammateMode is already "auto" in settings.json, so a team started this way
# lands in tmux split panes when you are inside tmux, and falls back to the
# in-process agent panel when you are not. Nothing else to pass.
#
#   claude_team                    # one session with teams enabled
#   claude_team --resume           # any claude flag passes straight through
#
# `command` rather than a bare call so this keeps working if claude ever picks
# up an alias elsewhere in the config.
function claude_team() {
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 command claude "$@"
}
