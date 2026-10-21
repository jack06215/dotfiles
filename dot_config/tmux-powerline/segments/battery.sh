# shellcheck shell=bash
# The plugin's battery segment, taught to read the battery on Termux.
#
# A segment in this directory wins over the plugin's own of the same name, so
# this file stands in for it - and then sources it, so macOS and plain Linux
# run upstream's code untouched. Termux is the one case upstream cannot
# handle: Android hides /sys/class/power_supply from apps, so its Linux path
# finds no battery and the bar shows 󰚥 forever. termux-battery-status (the
# termux-api package, plus the Termux:API app) asks Android instead.
#
# Termux reports SHELL_PLATFORM "linux", so only __battery_linux is replaced:
# run_segment, the glyphs and the percentage/cute/hearts types all stay
# upstream's. It prints what upstream's __battery_macos prints, so the phone
# and the Mac read the same:
#
#   (nothing)   plugged in and full - run_segment turns this into 󰚥
#   󰂄 64        plugged in and charging
#   󱊣 91 / 󱊢 64  on battery, 80% and up / 50-79%
#   󱊡 31        on battery under 50%, in red
#
# "Full" includes NOT_CHARGING while plugged in. That is Android's battery
# protection holding the charge at 85% or so, and a charge glyph that never
# moves would be four columns of noise.

# shellcheck source=/dev/null
source "${TMUX_POWERLINE_DIR_SEGMENTS}/battery.sh"

command -v termux-battery-status >/dev/null || return 0

__battery_linux() {
	# Every termux-api call takes over a second, since it round-trips through
	# the Termux:API app, and the right side of the bar redraws every 5 seconds;
	# a minute-old reading is plenty for a battery. The file is rewritten even
	# when the call fails, so a broken setup costs one attempt a minute rather
	# than one per redraw. timeout matters for exactly that case: with the
	# package installed but not the app, the call blocks instead of failing.
	local cache="${TMUX_POWERLINE_DIR_TEMPORARY}/battery_termux.json"
	local age=$(($(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0)))
	if [ "$age" -ge 60 ]; then
		timeout 5 termux-battery-status >"$cache.$$" 2>/dev/null
		mv -f "$cache.$$" "$cache"
	fi

	# The output is pretty-printed JSON, one key per line, so a regex per line
	# does the job without depending on jq.
	local line pct="" status="" plugged=""
	local re='"(percentage|status|plugged)": "?([A-Z_0-9]+)'
	while IFS= read -r line; do
		[[ $line =~ $re ]] || continue
		case "${BASH_REMATCH[1]}" in
		percentage) pct="${BASH_REMATCH[2]}" ;;
		status) status="${BASH_REMATCH[2]}" ;;
		plugged) plugged="${BASH_REMATCH[2]}" ;;
		esac
	done <"$cache"
	[ -n "$pct" ] || return 0

	if [ "$plugged" != "UNPLUGGED" ]; then
		if [[ $status == "FULL" || $status == "NOT_CHARGING" || $pct -ge 100 ]]; then
			return 0
		fi
		echo "$BATTERY_CHARGE $pct"
	elif [ "$pct" -lt 50 ]; then
		echo "#[fg=#ff0000]$BATTERY_EMPTY $pct"
	elif [ "$pct" -lt 80 ]; then
		echo "$BATTERY_MED $pct"
	else
		echo "$BATTERY_FULL $pct"
	fi
}
