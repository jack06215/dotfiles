# shellcheck shell=bash
# What you are tracking right now, and how much today has banked.
#
#    󰅐 dotfiles ▸ wire up the segment 45m · 2h15 today
#      │          │                   │      └─ everything logged today,
#      │          │                   │         the running activity included
#      │          │                   └──────── how long this one has been going
#      │          └──────────────────────────── description (truncated)
#      └─────────────────────────────────────── project
#
# With nothing running it collapses to a dim "󰅐 —", which is the half of this
# segment that actually changes behaviour: a time tracker fails by being
# forgotten, and forgetting is invisible unless something says so. Set
# TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE="false" to hide it instead, at which
# point tmux-powerline drops the segment and its separator entirely.
#
# The elapsed time changes colour as it grows: yellow past WARN_MINUTES (a block
# this long is either deep work worth noticing or a break you skipped) and red
# past STALE_MINUTES (almost certainly an activity nobody stopped). The red one
# pairs with `working_hours` in ~/.config/tock/tock.yaml - that setting stops a
# forgotten activity, this one lets you see it before it gets that far.
#
# Two `tock` calls per refresh, ~7 ms each (measured), so there is no cache here
# the way claude_agents.sh needs one for its ~200 ms Node query. tock is a
# single Go binary reading one plaintext file; this costs less than the one git
# call vcs_status.sh makes on the other side of the bar.

# shellcheck source=/dev/null
source "${TMUX_POWERLINE_DIR_LIB}/util.sh"

# 󰅐 is a Nerd Font Material Design glyph (U+F0150, clock-outline), the same
# family as the robot in claude_agents.sh. "tk" stands in without a patched
# font - it is also the command you type to start tracking, so the fallback
# still points at what the segment is about.
if tp_patched_font_in_use; then
	TMUX_POWERLINE_SEG_TOCK_SYMBOL_DEFAULT="󰅐"
else
	TMUX_POWERLINE_SEG_TOCK_SYMBOL_DEFAULT="tk"
fi
TMUX_POWERLINE_SEG_TOCK_MAX_LEN_DEFAULT="28"
TMUX_POWERLINE_SEG_TOCK_WARN_MINUTES_DEFAULT="90"
TMUX_POWERLINE_SEG_TOCK_STALE_MINUTES_DEFAULT="300"
TMUX_POWERLINE_SEG_TOCK_SHOW_TODAY_DEFAULT="true"
TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE_DEFAULT="true"

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Leading glyph for the segment.
export TMUX_POWERLINE_SEG_TOCK_SYMBOL="${TMUX_POWERLINE_SEG_TOCK_SYMBOL_DEFAULT}"
# Truncate "project ▸ description" longer than this many columns.
export TMUX_POWERLINE_SEG_TOCK_MAX_LEN="${TMUX_POWERLINE_SEG_TOCK_MAX_LEN_DEFAULT}"
# Elapsed time turns yellow past this many minutes, red past the next.
export TMUX_POWERLINE_SEG_TOCK_WARN_MINUTES="${TMUX_POWERLINE_SEG_TOCK_WARN_MINUTES_DEFAULT}"
export TMUX_POWERLINE_SEG_TOCK_STALE_MINUTES="${TMUX_POWERLINE_SEG_TOCK_STALE_MINUTES_DEFAULT}"
# Append today's running total. Costs one extra tock call per refresh.
export TMUX_POWERLINE_SEG_TOCK_SHOW_TODAY="${TMUX_POWERLINE_SEG_TOCK_SHOW_TODAY_DEFAULT}"
# Show a dim placeholder when nothing is being tracked, rather than nothing.
export TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE="${TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE_DEFAULT}"
# Colours, in Catppuccin Mocha by default. Any tmux colour spec works.
export TMUX_POWERLINE_SEG_TOCK_SYMBOL_COLOUR="#cba6f7"
export TMUX_POWERLINE_SEG_TOCK_WARN_COLOUR="#f9e2af"
export TMUX_POWERLINE_SEG_TOCK_STALE_COLOUR="#f38ba8"
export TMUX_POWERLINE_SEG_TOCK_TODAY_COLOUR="#a6adc8"
export TMUX_POWERLINE_SEG_TOCK_IDLE_COLOUR="#6c7086"
EORC
	echo "$rccontents"
}

run_segment() {
	__process_settings

	tp_command_exists tock || return 0

	local fg="$TMUX_POWERLINE_CUR_SEGMENT_FG"
	local symbol_colour="$TMUX_POWERLINE_SEG_TOCK_SYMBOL_COLOUR"

	# One process for the running activity. A literal tab separates the fields:
	# Go's text/template does not interpret escape sequences, so "\t" inside the
	# format would arrive as a backslash and a t, and $'\t' is the way to put a
	# real tab there without leaving an invisible one in this file — the same
	# reason themes/mocha.sh spells its separators as escape sequences.
	#
	# With nothing running tock prints nothing at all and exits 0, which is what
	# distinguishes idle from an error here.
	local tab=$'\t' current
	if ! current=$(tock current -F "{{.Project}}${tab}{{.Description}}${tab}{{.DurationHMS}}" 2>/dev/null); then
		return 0
	fi
	current=${current%%$'\n'*}

	if [ -z "$current" ]; then
		[ "$TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE" = "true" ] || return 0
		echo "#[fg=${TMUX_POWERLINE_SEG_TOCK_IDLE_COLOUR}]${TMUX_POWERLINE_SEG_TOCK_SYMBOL} —#[fg=${fg}]"
		return 0
	fi

	local project description hms
	IFS=$'\t' read -r project description hms <<<"$current"

	local elapsed_min
	elapsed_min=$(__hms_to_minutes "$hms")

	# Colour by how long this one activity has been open.
	local elapsed_colour="$fg"
	if [ "$elapsed_min" -ge "$TMUX_POWERLINE_SEG_TOCK_STALE_MINUTES" ]; then
		elapsed_colour="$TMUX_POWERLINE_SEG_TOCK_STALE_COLOUR"
	elif [ "$elapsed_min" -ge "$TMUX_POWERLINE_SEG_TOCK_WARN_MINUTES" ]; then
		elapsed_colour="$TMUX_POWERLINE_SEG_TOCK_WARN_COLOUR"
	fi

	local label="${project} ▸ ${description}"
	if [ "${#label}" -gt "$TMUX_POWERLINE_SEG_TOCK_MAX_LEN" ]; then
		label="${label:0:$((TMUX_POWERLINE_SEG_TOCK_MAX_LEN - 1))}…"
	fi

	local out="#[fg=${symbol_colour}]${TMUX_POWERLINE_SEG_TOCK_SYMBOL} "
	out+="#[fg=${fg}]${label} "
	out+="#[fg=${elapsed_colour}]$(__humanize_minutes "$elapsed_min")"

	if [ "$TMUX_POWERLINE_SEG_TOCK_SHOW_TODAY" = "true" ]; then
		# `tock report --total-only` counts the running activity too, measured up
		# to now — so this is genuinely "today so far" and the elapsed minutes
		# above must NOT be added to it. (Verified rather than assumed: a 2h
		# closed entry plus one running since 22:30 reports 3h17 at 23:47.)
		out+=" #[fg=${TMUX_POWERLINE_SEG_TOCK_TODAY_COLOUR}]· $(__humanize_minutes "$(__today_total_minutes)") today"
	fi

	echo "${out}#[fg=${fg}]"
	return 0
}

# HH:MM:SS -> whole minutes. The hour field keeps counting past 24 rather than
# wrapping, so no date arithmetic is needed to catch an activity left running
# overnight — it just arrives as a large number and trips STALE_MINUTES.
__hms_to_minutes() {
	IFS=: read -r h m _ <<<"$1"
	echo $((10#${h:-0} * 60 + 10#${m:-0}))
}

# Minutes -> "45m" under an hour, "2h15" at or above one. Two characters shorter
# than "2h15m" in the place where the bar is most likely to be cramped, and the
# h is already doing the work the trailing m would.
__humanize_minutes() {
	local total=${1:-0}
	if [ "$total" -lt 60 ]; then
		printf '%dm' "$total"
	else
		printf '%dh%02d' $((total / 60)) $((total % 60))
	fi
}

# Everything logged today, in minutes, the running activity included.
# `--total-only` prints "2h 15m", or a line with neither field when the day is
# empty — awk yields 0 for that and for no output at all.
__today_total_minutes() {
	tock report --today --total-only 2>/dev/null |
		awk '{ for (i = 1; i <= NF; i++) { if ($i ~ /h$/) h = $i + 0; else if ($i ~ /m$/) m = $i + 0 } }
		     END { print h * 60 + m + 0 }'
}

__process_settings() {
	: "${TMUX_POWERLINE_SEG_TOCK_SYMBOL:=$TMUX_POWERLINE_SEG_TOCK_SYMBOL_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_TOCK_MAX_LEN:=$TMUX_POWERLINE_SEG_TOCK_MAX_LEN_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_TOCK_WARN_MINUTES:=$TMUX_POWERLINE_SEG_TOCK_WARN_MINUTES_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_TOCK_STALE_MINUTES:=$TMUX_POWERLINE_SEG_TOCK_STALE_MINUTES_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_TOCK_SHOW_TODAY:=$TMUX_POWERLINE_SEG_TOCK_SHOW_TODAY_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE:=$TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_TOCK_SYMBOL_COLOUR:=#cba6f7}"
	: "${TMUX_POWERLINE_SEG_TOCK_WARN_COLOUR:=#f9e2af}"
	: "${TMUX_POWERLINE_SEG_TOCK_STALE_COLOUR:=#f38ba8}"
	: "${TMUX_POWERLINE_SEG_TOCK_TODAY_COLOUR:=#a6adc8}"
	: "${TMUX_POWERLINE_SEG_TOCK_IDLE_COLOUR:=#6c7086}"
}
