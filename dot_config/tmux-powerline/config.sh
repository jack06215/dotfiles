# tmux-powerline configuration.
#
# Only the settings that differ from the plugin defaults are kept here. To see
# every option with its default value and documentation, regenerate the full
# reference (it writes config.sh.default next to this file and never touches
# config.sh):
#
#   ~/.local/share/tmux/plugins/tmux-powerline/generate_config.sh
#
# `~/.local/share/tmux/plugins/tmux-powerline/doctor.sh` prints the resolved
# values plus dependency checks, which is the fastest way to debug a segment
# that renders as nothing.

# General {
	# themes/mocha.sh in this directory. Everything visual lives there.
	export TMUX_POWERLINE_THEME="mocha"

	# These two MUST stay set. They are what makes the plugin look in this
	# directory before its own; unset, "mocha" is searched for only inside the
	# plugin repo, is not found, and the status bar comes up empty. (The plugin
	# ships no default for either — they exist only in the generated config.)
	export TMUX_POWERLINE_DIR_USER_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/themes"
	export TMUX_POWERLINE_DIR_USER_SEGMENTS="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-powerline/segments"

	# The whole left side is one shell process and the whole right side is
	# another, so this is the fork rate of the bar, not a per-segment cost. The
	# plugin default of 1 second is far more than a clock showing %H:%M and a
	# load average need; tmux.conf used to say 15, which made the clock visibly
	# wrong. 5 keeps the git counts feeling live without the churn.
	export TMUX_POWERLINE_STATUS_INTERVAL="5"

	# Window list in the middle, between the two status sides.
	export TMUX_POWERLINE_STATUS_JUSTIFICATION="centre"

	# Truncation limits for each side. tmux measures these in displayed columns
	# (the #[fg=…] markup does not count), and silently cuts anything longer —
	# which looks like "my clock disappeared" rather than like an error, so both
	# are set well above what the segments below actually produce.
	# Left was 120, which was ample until the tock segment joined it: worst case
	# there is ~48 columns (glyph, a 28-column label, elapsed, today's total) on
	# top of mode + session + host + branch.
	export TMUX_POWERLINE_STATUS_LEFT_LENGTH="170"
	export TMUX_POWERLINE_STATUS_RIGHT_LENGTH="140"

	# Keeps the bar transparent. main.tmux takes over `status-style` from
	# tmux.conf, so `set -g status-style bg=default` there no longer has any
	# effect and this is where that setting now lives. bg=default means "the
	# terminal's background", which is what lets wezterm's
	# window_background_opacity show through the bar.
	export TMUX_POWERLINE_STATUS_STYLE="fg=#cdd6f4,bg=default"

	# PlemolJP Console NF (the WezTerm font) has the powerline glyphs, so the
	# themes can use the solid arrow separators rather than ASCII stand-ins.
	export TMUX_POWERLINE_PATCHED_FONT_IN_USE="true"

	# Set these to hide one side of the bar on a keypress (they become
	# `prefix + <key>`). Left unset because nearly every prefix key is already
	# claimed — check `tmux list-keys -T prefix` before picking one.
	#export TMUX_POWERLINE_MUTE_LEFT_KEYBINDING=""
	#export TMUX_POWERLINE_MUTE_RIGHT_KEYBINDING=""

	# Flip to "true" and a failing segment says so in the bar instead of
	# vanishing. Pair with the error log when writing a new segment.
	export TMUX_POWERLINE_DEBUG_MODE_ENABLED="false"
	export TMUX_POWERLINE_ERROR_LOGS_ENABLED="false"
# }

# mode_indicator.sh {
	# The left-most tile. Its background is fixed by the theme, so the text is
	# what changes: tmux evaluates #{?client_prefix,…} on every redraw, while
	# the script that picks the colours only runs once per refresh interval.
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_NORMAL_AND_PREFIX_MODE_ENABLED="true"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_NORMAL_MODE_TEXT="TMUX"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_NORMAL_MODE_TEXT_COLOR="#9399b2"
	# The one that earns the segment: C-s latches, and until you press the next
	# key this says so. Red so it is impossible to miss.
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_PREFIX_MODE_TEXT="PREFIX"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_PREFIX_MODE_TEXT_COLOR="#f38ba8"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_COPY_MODE_ENABLED="true"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_COPY_MODE_TEXT="COPY"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_COPY_MODE_TEXT_COLOR="#f9e2af"
	# tmux-suspend (M-q) parks tmux in the "suspended" key-table so keys reach a
	# nested tmux; this segment reads that table directly. It updates on the
	# refresh interval rather than instantly, unlike the two above.
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_SUSPEND_MODE_TEXT="SUSPEND"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_SUSPEND_MODE_TEXT_COLOR="#fab387"
	# Off: `setw -g mouse on` is permanent in this config, so a permanent
	# "mouse" label would just be four columns of noise.
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_MOUSE_MODE_ENABLED="false"
	export TMUX_POWERLINE_SEG_MODE_INDICATOR_SEPARATOR_TEXT=" • "
# }

# tmux_session_info.sh {
	# Session name only. The window index is already in the window list in the
	# middle of the bar, and the pane index is not worth a column when panes are
	# reached by direction with M-h/j/k/l rather than by number. Use
	# "#S:#I.#P" if you ever want the full address back.
	export TMUX_POWERLINE_SEG_TMUX_SESSION_INFO_FORMAT="#S"
# }

# hostname.sh {
	export TMUX_POWERLINE_SEG_HOSTNAME_FORMAT="short"
# }

# pwd.sh {
	# Truncated from the left, keeping the tail: ···/jack06215/dotfiles.
	export TMUX_POWERLINE_SEG_PWD_MAX_LEN="42"
# }

# battery.sh {
	# On macOS this renders 󰚥 while charged on AC and only spends columns on a
	# number once actually discharging (turning red below 50%).
	export TMUX_POWERLINE_SEG_BATTERY_TYPE="percentage"
# }

# date.sh / time.sh {
	export TMUX_POWERLINE_SEG_DATE_FORMAT="%F"
	export TMUX_POWERLINE_SEG_TIME_FORMAT="%H:%M"
# }

# vcs_status.sh (custom, see segments/vcs_status.sh) {
	export TMUX_POWERLINE_SEG_VCS_STATUS_MAX_LEN="24"
# }

# tock.sh (custom, see segments/tock.sh) {
	# "project ▸ description" is truncated to this; the elapsed time and today's
	# total are appended after it and are not counted in the limit.
	export TMUX_POWERLINE_SEG_TOCK_MAX_LEN="28"
	# Elapsed time turns yellow at 90 minutes and red at 5 hours. The yellow one
	# is a nudge (a block this long has either earned a break or drifted off what
	# you said you were doing); the red one means an activity nobody stopped.
	export TMUX_POWERLINE_SEG_TOCK_WARN_MINUTES="90"
	export TMUX_POWERLINE_SEG_TOCK_STALE_MINUTES="300"
	# Today's total, alongside the current activity. One extra `tock` call per
	# refresh (~7 ms); set "false" to drop it and reclaim ~10 columns.
	export TMUX_POWERLINE_SEG_TOCK_SHOW_TODAY="true"
	# The half that earns the segment: with nothing running it shows a dim
	# "󰅐 —" rather than disappearing, because a tracker that is silently off is
	# a tracker producing wrong numbers. "false" hides it when idle instead.
	export TMUX_POWERLINE_SEG_TOCK_SHOW_WHEN_IDLE="true"
# }

# claude_agents.sh (custom, see segments/claude_agents.sh) {
	# `claude agents --json` is a Node process, so the answer is cached. 10s
	# means at most every other refresh pays for it.
	export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_UPDATE_INTERVAL="10"
	export TMUX_POWERLINE_SEG_CLAUDE_AGENTS_TIMEOUT="5"
# }
