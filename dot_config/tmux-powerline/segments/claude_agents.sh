# shellcheck shell=bash
# How many Claude Code sessions are running, split by what they want from you.
#
#    󰚩 ●2 ●1 ●3 ●1
#      │  │  │  └─ grey   — parked, alive but unreported (see below)
#      │  │  └──── red    — working, leave it alone
#      │  └─────── green  — idle, finished and handed back to you
#      └────────── yellow — waiting, blocked on your answer right now
#
# The dot colours are deliberately the same three used by the picker that
# tmux-claude-session-manager opens on `prefix + u`, so the bar and the picker
# agree at a glance: the bar says *how many* need you, `prefix + u` says *which*.
# Groups with a count of zero are omitted, and with no Claude running at all the
# segment produces nothing and tmux-powerline drops it.
#
# Status comes from `claude agents --json`, the same source the picker uses —
# Claude self-reports, so this needs no Claude Code hooks. For the three status
# groups this does not join pid -> tty -> pane, so a Claude running *outside*
# tmux is still counted; in practice every Claude here is launched into a pane.
#
# That list is authoritative about status but not about what is running: it
# drops any session carrying a `parkedJobId` — set when that session moves work
# to the background — for as long as the background job lives. A dedicated
# `claude-*` session that backgrounded a task would otherwise take the whole
# segment away with it while the session is alive and re-attachable. So the
# `claude-*` tmux sessions Claude did not account for are counted separately and
# shown grey, which keeps the bar and `prefix + u` telling the same story.
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
export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_PARKED_COLOUR="#6c7086"
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

	local waiting idle busy parked
	read -r waiting idle busy parked <<<"$counts"
	# A cache written before the parked group existed has only three fields.
	[[ "$parked" =~ ^[0-9]+$ ]] || parked=0
	[ $((waiting + idle + busy + parked)) -gt 0 ] || return 0

	local fg="$TMUX_POWERLINE_CUR_SEGMENT_FG"
	local out="${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL}"

	[ "$waiting" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_WAITING_COLOUR}]●#[fg=${fg}]${waiting}"
	[ "$idle" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_IDLE_COLOUR}]●#[fg=${fg}]${idle}"
	[ "$busy" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_BUSY_COLOUR}]●#[fg=${fg}]${busy}"
	[ "$parked" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_PARKED_COLOUR}]●#[fg=${fg}]${parked}"

	echo "$out"
	return 0
}

# Echo "<waiting> <idle> <busy> <parked>", from the cache when it is fresh enough.
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

	# Queried once and reused: the status counts, and the pids that let the
	# parked join below tell "Claude knows about this pane" from "it does not".
	local json counts pids
	json=$("${timeout_cmd[@]}" claude agents --json 2>/dev/null)

	# `kind == "interactive"` drops Claude's own background subagents, which are
	# not something you can switch to.
	counts=$(printf '%s' "$json" |
		jq -r '
			[.[]? | select(.kind == "interactive") | .status] as $s
			| "\($s | map(select(. == "waiting")) | length) \($s | map(select(. == "idle")) | length) \($s | map(select(. == "busy")) | length)"
		' 2>/dev/null)
	# An unparseable or failed query still leaves the parked count meaningful.
	[[ "$counts" =~ ^[0-9]+\ [0-9]+\ [0-9]+$ ]] || counts="0 0 0"

	pids=$(printf '%s' "$json" | jq -r '.[]? | select(.kind == "interactive") | .pid' 2>/dev/null)
	echo "$counts $(__parked_count "$pids")"
}

# How many `claude-*` tmux sessions hold a Claude that `claude agents --json`
# did not report. tmux tears such a session down when the `claude` it was
# launched with exits, so a session that still exists still has one running.
__parked_count() {
	local prefix
	prefix=$(tmux show-option -gqv @claude_session_prefix 2>/dev/null)
	[ -n "$prefix" ] || prefix="claude-"

	# The known pids arrive as a tagged stream rather than through `awk -v`:
	# a newline inside a -v value is an error in BSD awk ("newline in string").
	{
		[ -n "$1" ] && printf '%s\n' "$1" | sed $'s/^/K\t/'
		tmux list-panes -a -F $'T\t#{session_name}\t#{pane_pid}' 2>/dev/null
	} | awk -F'\t' -v prefix="$prefix" '
		$1 == "K" { known[$2] = 1; next }
		$1 == "T" && index($2, prefix) == 1 && !($3 in known) { c++ }
		END { print c + 0 }
	'
}

__process_settings() {
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL:=$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_SYMBOL_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL:=$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT:=$TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_WAITING_COLOUR:=#f9e2af}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_IDLE_COLOUR:=#a6e3a1}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_BUSY_COLOUR:=#f38ba8}"
	: "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_PARKED_COLOUR:=#6c7086}"
}
