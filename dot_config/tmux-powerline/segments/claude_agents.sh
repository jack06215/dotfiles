# shellcheck shell=bash
# How many Claude Code sessions are running, split by what they want from you.
#
#    󰚩 ●2 ●1 ●3
#      │  │  └─ red    — working, leave it alone
#      │  └──── green  — idle, finished and handed back to you
#      └─────── yellow — waiting, blocked on your answer right now
#
# The dot colours are deliberately the same three used by the picker that
# tmux-claude-session-manager opens on `prefix + u`, so the bar and the picker
# agree at a glance: the bar says *how many* need you, `prefix + u` says *which*.
# Groups with a count of zero are omitted, and with no Claude running at all the
# segment produces nothing and tmux-powerline drops it.
#
# Status comes from `claude agents --json`, the same source the picker uses —
# Claude self-reports, so this needs no Claude Code hooks. Unlike the picker,
# this does not join pid -> tty -> pane, so a Claude running *outside* tmux is
# still counted; that costs two subprocesses less per refresh and in practice
# every Claude here is launched into a pane anyway.
#
# The result is cached in the tmux-powerline temp dir because the query is a
# Node process (~200 ms) and the bar redraws on window renames and pane focus
# changes as well as on the interval.

# shellcheck source=/dev/null
source "${TMUX_POWERLINE_DIR_LIB}/util.sh"

# 󰚩 is a Nerd Font glyph; "CC" stands in when the terminal font has none, so the
# dots still say what they belong to.
if tp_patched_font_in_use; then
	TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL_DEFAULT="󰚩"
else
	TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL_DEFAULT="CC"
fi
TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL_DEFAULT="10"
TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT_DEFAULT="5"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Leading glyph for the segment.
export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL="${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL_DEFAULT}"
# Seconds to cache the agent list for.
export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL="${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL_DEFAULT}"
# Seconds to allow the query before giving up (needs timeout(1)/gtimeout(1)).
export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT="${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT_DEFAULT}"
# Dot colours, matching the prefix+u picker.
export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_WAITING_COLOUR="#f9e2af"
export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_IDLE_COLOUR="#a6e3a1"
export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_BUSY_COLOUR="#f38ba8"
EORC
	echo "$rccontents"
}

run_segment() {
	__process_settings

	tp_command_exists claude || return 0
	tp_command_exists jq || return 0

	local counts
	counts=$(__cached_counts)
	[ -n "$counts" ] || return 0

	local waiting idle busy
	read -r waiting idle busy <<<"$counts"
	[ $((waiting + idle + busy)) -gt 0 ] || return 0

	local fg="$TMUX_POWERLINE_CUR_SEGMENT_FG"
	local out="${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL}"

	[ "$waiting" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_WAITING_COLOUR}]●#[fg=${fg}]${waiting}"
	[ "$idle" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_IDLE_COLOUR}]●#[fg=${fg}]${idle}"
	[ "$busy" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_BUSY_COLOUR}]●#[fg=${fg}]${busy}"

	echo "$out"
	return 0
}

# Echo "<waiting> <idle> <busy>", from the cache when it is fresh enough.
#
# The cache stores its own write time on the first line rather than relying on
# the file's mtime, so this needs neither stat(1) (whose flags differ between
# BSD and GNU) nor bc(1).
__cached_counts() {
	local cache="${TMUX_POWERLINE_DIR_TEMPORARY}/claude_agents.cache"
	local now stamp payload
	now=$(date +%s)

	if [ -r "$cache" ]; then
		{
			read -r stamp
			read -r payload
		} <"$cache"
		if [[ "$stamp" =~ ^[0-9]+$ ]] &&
			[ $((now - stamp)) -lt "$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL" ]; then
			echo "$payload"
			return 0
		fi
	fi

	payload=$(__query_counts) || return 1
	# Write via a temp file and rename so a second client reading the cache at
	# the same moment never sees a half-written one.
	printf '%s\n%s\n' "$now" "$payload" >"${cache}.$$" 2>/dev/null &&
		mv -f "${cache}.$$" "$cache" 2>/dev/null
	echo "$payload"
}

__query_counts() {
	local timeout_cmd=()
	if tp_command_exists timeout; then
		timeout_cmd=(timeout "$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT")
	elif tp_command_exists gtimeout; then
		timeout_cmd=(gtimeout "$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT")
	fi

	# `kind == "interactive"` drops Claude's own background subagents, which are
	# not something you can switch to.
	"${timeout_cmd[@]}" claude agents --json 2>/dev/null |
		jq -r '
			[.[]? | select(.kind == "interactive") | .status] as $s
			| "\($s | map(select(. == "waiting")) | length) \($s | map(select(. == "idle")) | length) \($s | map(select(. == "busy")) | length)"
		' 2>/dev/null
}

__process_settings() {
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL:=$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL:=$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT:=$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_WAITING_COLOUR:=#f9e2af}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_IDLE_COLOUR:=#a6e3a1}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_BUSY_COLOUR:=#f38ba8}"
}
