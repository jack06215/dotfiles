# shellcheck shell=bash
# How many coding agents (Claude Code, Copilot CLI) are running, split by what
# they want from you.
#
#    󰚩 ●2 ●1 ●3
#      │  │  └─ red    — working, leave it alone
#      │  └──── green  — idle, finished and handed back to you
#      └─────── yellow — waiting, blocked on your answer right now
#
# The dot colours are deliberately the same three used by the agent-hatch picker
# on `prefix + u`, so the bar and the picker agree at a glance: the bar says *how
# many* need you, `prefix + u` says *which* - and which agent each one is.
# Groups with a count of zero are omitted, and with no agent running at all the
# segment produces nothing and tmux-powerline drops it.
#
# The counts come from agent-hatch's own agents.sh, the same source as the
# picker: each agent's hooks keep its status on its tmux pane, so this is one
# `tmux list-panes` - no agent CLI to ask, nothing to cache. An agent running
# outside tmux has no pane to report to and is not counted.

# shellcheck source=/dev/null
source "${TMUX_POWERLINE_DIR_LIB}/util.sh"

# 󰚩 is a Nerd Font glyph; "AI" stands in when the terminal font has none, so the
# dots still say what they belong to.
if tp_patched_font_in_use; then
	TMUX_POWERLINE_SEG_AGENTS_SYMBOL_DEFAULT="󰚩"
else
	TMUX_POWERLINE_SEG_AGENTS_SYMBOL_DEFAULT="AI"
fi

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Leading glyph for the segment.
export TMUX_POWERLINE_SEG_AGENTS_SYMBOL="${TMUX_POWERLINE_SEG_AGENTS_SYMBOL_DEFAULT}"
# Dot colours, matching the prefix+u picker.
export TMUX_POWERLINE_SEG_AGENTS_WAITING_COLOUR="#f9e2af"
export TMUX_POWERLINE_SEG_AGENTS_IDLE_COLOUR="#a6e3a1"
export TMUX_POWERLINE_SEG_AGENTS_BUSY_COLOUR="#f38ba8"
EORC
	echo "$rccontents"
}

run_segment() {
	__process_settings

	local agents="$HOME/.config/tmux/agent-hatch/scripts/agents.sh"
	[ -x "$agents" ] || return 0

	local waiting idle busy
	read -r waiting idle busy <<<"$("$agents" --counts 2>/dev/null)"
	[[ "$waiting $idle $busy" =~ ^[0-9]+\ [0-9]+\ [0-9]+$ ]] || return 0
	[ $((waiting + idle + busy)) -gt 0 ] || return 0

	local fg="$TMUX_POWERLINE_CUR_SEGMENT_FG"
	local out="${TMUX_POWERLINE_SEG_AGENTS_SYMBOL}"

	[ "$waiting" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_AGENTS_WAITING_COLOUR}]●#[fg=${fg}]${waiting}"
	[ "$idle" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_AGENTS_IDLE_COLOUR}]●#[fg=${fg}]${idle}"
	[ "$busy" -gt 0 ] && out+=" #[fg=${TMUX_POWERLINE_SEG_AGENTS_BUSY_COLOUR}]●#[fg=${fg}]${busy}"

	echo "$out"
	return 0
}

__process_settings() {
	: "${TMUX_POWERLINE_SEG_AGENTS_SYMBOL:=$TMUX_POWERLINE_SEG_AGENTS_SYMBOL_DEFAULT}"
	: "${TMUX_POWERLINE_SEG_AGENTS_WAITING_COLOUR:=#f9e2af}"
	: "${TMUX_POWERLINE_SEG_AGENTS_IDLE_COLOUR:=#a6e3a1}"
	: "${TMUX_POWERLINE_SEG_AGENTS_BUSY_COLOUR:=#f38ba8}"
}
