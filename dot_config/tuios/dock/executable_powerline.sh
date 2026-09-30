#!/usr/bin/env bash
# One side of the tmux status bar, drawn as a tuios dock cell.
#
#   powerline.sh left|right
#
# config.toml next to this directory wires the two sides in as custom/left and
# custom/right, so the ruby tab's dock carries the same bar as the opal tab:
#
#   ┌ mode ┬ user ┬ host ┬ git ┬ tock ┐   ┌ windows ┐   ┌ claude ┬ pwd ┬ battery ┬ clock ┐
#    tuios   └──────── custom/left ───┘      tuios        └──────── custom/right ─────────┘
#
# This is not a copy of the segments. It runs tmux-powerline itself, with
# dot_config/tmux-powerline/config.sh and themes/mocha.sh, and only turns tmux's
# #[fg=…,bg=…] markup into the SGR escapes a dock cell keeps. A segment added,
# dropped or recoloured in the theme shows up in both bars.
#
# Three things in that code only work inside tmux, and this script stands in for
# them:
#
# - The focused pane's directory. vcs_status and pwd ask tmux for
#   #{pane_current_path}; a `tmux` function below answers with the directory of
#   the pane focused in this tuios session. Every other tmux call goes to the
#   real tmux, which is how claude_agents still counts the parked claude-*
#   sessions in the opal tab, so both bars show the same numbers.
# - The session tile. tmux_session_info prints a #{…} format for tmux to
#   expand as it draws. Here it prints your user name. That is what the tile
#   reads in tmux too, but only by way of the opal tab's session being named
#   after its start directory, ~. The tuios session is always "ruby", which the
#   tab title already says.
# - The mode tile. mode_indicator is made of #{?client_prefix,…} formats that
#   only tmux can evaluate, so it is left out. The dock's built-in "mode" pill
#   takes its place.
#
# A dock component that exits non-zero is hidden, and `tuios list-dock-components`
# shows its exit code and stderr. That is the first place to look when a side
# goes missing.

side=${1:-}
case $side in
left | right) ;;
*)
	echo "usage: ${0##*/} left|right" >&2
	exit 2
	;;
esac

# Where TPM puts it (tmux.conf sets the plugin path under XDG_DATA_HOME).
TMUX_POWERLINE_DIR_HOME=${TMUX_POWERLINE_DIR_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins/tmux-powerline}
if [ ! -f "$TMUX_POWERLINE_DIR_HOME/lib/headers.sh" ]; then
	echo "tmux-powerline is not installed at $TMUX_POWERLINE_DIR_HOME (prefix + I in tmux installs it)" >&2
	exit 1
fi
export TMUX_POWERLINE_DIR_HOME

# shellcheck source=/dev/null
source "$TMUX_POWERLINE_DIR_HOME/lib/headers.sh"
# Reads config.sh, which sources the theme. Everything below overrides it.
tp_process_settings

# Asked once, here, rather than inside the `tmux` function: every segment runs
# in a subshell of its own, so an answer cached inside one would not reach the
# next. No focused pane (or no daemon) leaves it empty, and vcs_status and pwd
# then draw nothing, which beats describing some other directory.
pane_cwd=""
if [ -n "${TUIOS_SESSION:-}" ]; then
	pane_cwd=$(tuios list-windows -s "$TUIOS_SESSION" --json 2>/dev/null |
		jq -r '.windows[]? | select(.focused) | .cwd // empty' 2>/dev/null)
fi

tmux() {
	case "$*" in
	*'#{pane_current_path}'*) printf '%s\n' "$pane_cwd" ;;
	*) command tmux "$@" ;;
	esac
}

# shellcheck disable=SC2034 # read by the tmux_session_info segment
TMUX_POWERLINE_SEG_TMUX_SESSION_INFO_FORMAT=${USER:-$(id -un)}

# tuios kills a component after three seconds and hides it until the next run,
# so a slow `claude agents --json` would take the clock and everything else on
# the right side with it. Two seconds leaves room for the other segments.
if [ "${TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT:-5}" -gt 2 ]; then
	TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT=2
fi

# The theme puts mode_indicator on the left.
kept=()
for segment in "${TMUX_POWERLINE_LEFT_STATUS_SEGMENTS[@]}"; do
	[ "${segment%% *}" = mode_indicator ] || kept+=("$segment")
done
TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=("${kept[@]}")

# Appends the SGR for one tmux colour to $sgr. $1 is 38 for the foreground or
# 48 for the background. A colour this does not know is skipped, which leaves
# the previous one in force rather than breaking the line.
__sgr_colour() {
	local base=$1 colour=$2 code i=0 name
	case $colour in
	'#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])
		printf -v code '\e[%d;2;%d;%d;%dm' "$base" "0x${colour:1:2}" "0x${colour:3:2}" "0x${colour:5:2}"
		;;
	# "default" is the dock's own colour: transparent for the background, which
	# is what keeps WezTerm's translucent window showing through, as in tmux.
	default) printf -v code '\e[%dm' $((base + 1)) ;;
	colour[0-9]* | color[0-9]*) printf -v code '\e[%d;5;%dm' "$base" "${colour##*[!0-9]}" ;;
	*)
		for name in black red green yellow blue magenta cyan white; do
			if [ "$colour" = "$name" ]; then
				printf -v code '\e[%dm' $((base - 8 + i))
				break
			elif [ "$colour" = "bright$name" ]; then
				printf -v code '\e[%dm' $((base + 52 + i))
				break
			fi
			i=$((i + 1))
		done
		[ -n "${code:-}" ] || return 0
		;;
	esac
	sgr+=$code
}

# tmux's #[…] style markup to SGR, left in $sgr, with the number of columns it
# draws in $columns. Covers what tmux-powerline and the segments in
# dot_config/tmux-powerline emit: fg= and bg= as #rrggbb, colourN, a name or
# default, the text attributes and their no- forms, and default. A #{…} format
# would pass through as text, which is why the two segments that emit one are
# handled above.
#
# $columns counts characters, which is columns for everything the segments
# draw (the Nerd Font glyphs are one cell wide) but undercounts a CJK name.
__tmux_to_sgr() {
	local rest=$1 style attr attrs text plain=""
	sgr=""
	while [[ $rest == *'#['*']'* ]]; do
		text=${rest%%'#['*}
		sgr+=$text
		plain+=$text
		rest=${rest#*'#['}
		style=${rest%%']'*}
		rest=${rest#*']'}
		IFS=', ' read -r -a attrs <<<"$style"
		for attr in "${attrs[@]}"; do
			case $attr in
			fg=*) __sgr_colour 38 "${attr#fg=}" ;;
			bg=*) __sgr_colour 48 "${attr#bg=}" ;;
			default | none) sgr+=$'\e[0m' ;;
			bold | bright) sgr+=$'\e[1m' ;;
			dim) sgr+=$'\e[2m' ;;
			nobold | nodim) sgr+=$'\e[22m' ;;
			italics) sgr+=$'\e[3m' ;;
			noitalics) sgr+=$'\e[23m' ;;
			underscore) sgr+=$'\e[4m' ;;
			nounderscore) sgr+=$'\e[24m' ;;
			reverse) sgr+=$'\e[7m' ;;
			noreverse) sgr+=$'\e[27m' ;;
			esac
		done
	done
	sgr+=$rest$'\e[0m'
	plain+=$rest
	columns=${#plain}
}

# tuios cuts a custom cell at 80 columns (DockCustomMaxWidthLimit; config.toml
# asks for all of it) and drops what is past the end. On the right the end is
# the clock, and pwd alone can take 45 of the 80. pwd is also the one segment
# made to shrink, so a right side that does not fit is drawn again with pwd
# shorter by the difference. On the left the end is tock, which the theme puts
# last so that it is the first thing to go, as in tmux.
dock_max_width=80

line=$(tp_print_powerline_side "$side")
# Every segment empty: print nothing, so the dock drops the cell and its gap.
[ -n "$line" ] || exit 0
__tmux_to_sgr "$line"

if [ "$side" = right ] && [ "$columns" -gt "$dock_max_width" ]; then
	# pwd.sh never goes below the last directory's own name, however low this is.
	TMUX_POWERLINE_SEG_PWD_MAX_LEN=$((${TMUX_POWERLINE_SEG_PWD_MAX_LEN:-40} - (columns - dock_max_width)))
	__tmux_to_sgr "$(tp_print_powerline_side "$side")"
fi

printf '%s\n' "$sgr"
