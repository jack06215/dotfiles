# shellcheck shell=bash disable=SC2034
# Catppuccin Mocha theme for tmux-powerline.
#
# Matched to WezTerm's "Catppuccin Mocha" colour_scheme (see dot_config/wezterm)
# so the status bar reads as part of the terminal rather than a strip pasted on
# top of it. If you switch the WezTerm scheme, swap the palette below and nothing
# else needs to change.
#
# Reading the layout:
#
#   ┌─ mode ─┬─ session ─┬─ host ─┬─ git ─┐   ┌─ windows ─┐   ┌─ claude ─┬─ pwd ─┬─ battery ─┬─ clock ─┐
#   │  TMUX  │  dotfiles │ A0229  │  main │   │ 1 zsh …   │   │ ●2       │ ~/…   │ 󰚥         │ 23:40   │
#
# Left = "where am I / what state is the repo in", centre = window list,
# right = "what needs me / what is the machine doing / what time is it".
#
# NOTE Changes here take effect on the next status refresh, but tmux caches the
# window-status formats, so run `prefix + r` (or `tmux source-file
# ~/.config/tmux/tmux.conf`) after editing.

# Catppuccin Mocha {
rosewater="#f5e0dc"
flamingo="#f2cdcd"
pink="#f5c2e7"
mauve="#cba6f7"
red="#f38ba8"
maroon="#eba0ac"
peach="#fab387"
yellow="#f9e2af"
green="#a6e3a1"
teal="#94e2d5"
sky="#89dceb"
sapphire="#74c7ec"
blue="#89b4fa"
lavender="#b4befe"
text="#cdd6f4"
subtext1="#bac2de"
subtext0="#a6adc8"
overlay2="#9399b2"
overlay1="#7f849c"
overlay0="#6c7086"
surface2="#585b70"
surface1="#45475a"
surface0="#313244"
base="#1e1e2e"
mantle="#181825"
crust="#11111b"
# }

# Powerline separators. These live in the Nerd Font private use area, which
# plenty of editors and pipes silently mangle, so they are written as their UTF-8
# bytes rather than as literal glyphs — the file stays pure ASCII and survives a
# round trip through anything. In order: U+E0B2 solid left arrow, U+E0B3 thin
# left arrow, U+E0B0 solid right arrow, U+E0B1 thin right arrow.
#
# PlemolJP Console NF (the WezTerm font) carries all four. Setting
# TMUX_POWERLINE_PATCHED_FONT_IN_USE="false" in config.sh drops to the plain
# arrows the plugin's own themes fall back to, for a terminal whose font has no
# powerline glyphs.
if tp_patched_font_in_use; then
	TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=$'\xee\x82\xb2'
	TMUX_POWERLINE_SEPARATOR_LEFT_THIN=$'\xee\x82\xb3'
	TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=$'\xee\x82\xb0'
	TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=$'\xee\x82\xb1'
else
	TMUX_POWERLINE_SEPARATOR_LEFT_BOLD="◀"
	TMUX_POWERLINE_SEPARATOR_LEFT_THIN="❮"
	TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="▶"
	TMUX_POWERLINE_SEPARATOR_RIGHT_THIN="❯"
fi

# "default" (rather than a Mocha hex) keeps the bar transparent, which is what
# `set -g status-style bg=default` in tmux.conf used to do on its own before
# tmux-powerline took the option over. It matters because wezterm.lua sets
# window_background_opacity — hardcoding #1e1e2e here would paint an opaque strip
# across an otherwise see-through window. Every segment below that wants the
# bar's own background asks for this variable, and unfilled space at the ends of
# each side falls back to it too.
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR:-'default'}
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR=${TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR:-$text}

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}

##### WINDOW LIST (the centre of the bar)
#
# These replace `window-status-style` / `window-status-current-style` from
# tmux.conf: tmux-powerline renders the window list through
# window-status-format, and inline `#[fg=…]` inside a format beats the *-style
# options, so the old style lines would have had no effect and were removed.
#
# Flags are spelled out one at a time rather than via tmux's `#F`, which
# concatenates every flag with no spacing and gives you names like "build#-".
# What is left is the two that mean "look over here": • for output you have not
# seen (monitor-activity is on) and ! for a bell. `*` (this is the current
# window) and `-` (this is the previous one) are dropped — the highlight below
# already says which window is current, and prefix+Tab is one keypress away.

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_FORMAT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
		"#[fg=${overlay0},bg=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR},nobold,noitalics,nounderscore]"
		"  #I "
		"#[fg=${overlay1}]"
		"#W"
		"#[fg=${yellow}]#{?window_activity_flag,•,}"
		"#[fg=${red}]#{?window_bell_flag,!,}"
		" "
	)
fi

# The current window gets caps on both sides so it reads as a lifted tile even
# though the bar behind it is transparent.
# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_CURRENT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
		"#[fg=${mauve},bg=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR},nobold,noitalics,nounderscore]"
		"${TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}"
		"#[fg=${crust},bg=${mauve},bold]"
		" #I "
		"#[nobold]${TMUX_POWERLINE_SEPARATOR_RIGHT_THIN}#[bold]"
		" #W"
		"#{?window_zoomed_flag, Z,}"
		"#{?window_bell_flag, !,}"
		" "
		"#[fg=${mauve},bg=${TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR},nobold]"
		"${TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}"
	)
fi

# shellcheck disable=SC2128
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_STYLE" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_STYLE=(
		"$(tp_format regular)"
	)
fi

##### SEGMENTS
#
# Format per line:
#   segment_name [bg] [fg] [separator] [separator_bg] [separator_fg] [spacing] [separator_toggle]
# Only the first three matter most of the time; see themes/default.sh in the
# plugin repo for the full option list.
#
# A segment that produces no output is dropped entirely — separators and all —
# so the "only when it matters" segments below (claude_agents, the git counts,
# battery on AC) cost no width when there is nothing to say.

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_LEFT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
		# Deliberately a muted tile: the *text* carries the signal (dim "TMUX",
		# red "PREFIX", yellow "COPY", peach "SUSPEND") because tmux evaluates
		# #{?client_prefix,…} live, while the segment's background colour is
		# fixed when the script runs and could only update once per refresh.
		# Seeing PREFIX light up is the single most useful thing on this bar
		# while the C-s prefix is still new muscle memory.
		"mode_indicator ${surface1} ${overlay2}"
		# The bright tile: session name is the identity you switch between with
		# M-s, and the thing every claude-… popup session is named after.
		"tmux_session_info ${lavender} ${crust}"
		# Which machine. Constant when local, but this config also runs over SSH
		# and under nested tmux (M-q / tmux-suspend), where it stops being
		# obvious. Comment it out if you only ever run tmux on one box.
		"hostname ${surface2} ${subtext1}"
		# Custom segment: branch + ahead/behind + staged/modified/untracked from
		# one git call. See segments/vcs_status.sh.
		"vcs_status ${surface0} ${text}"
	)
fi

# shellcheck disable=SC1143,SC2128
if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		# Custom segment: how many Claude Code sessions are waiting on you.
		# Hidden entirely when none are running. See segments/claude_agents.sh.
		"claude_agents ${surface0} ${text}"
		# Current pane's directory. Complements vcs_status on the left: that one
		# says which branch, this one says where in the tree.
		"pwd ${surface1} ${subtext1}"
		# Shows 󰚥 when charged on AC, and only becomes a percentage (turning red
		# under 50%) once actually on battery. Solid separator rather than thin
		# because pwd before it is a different colour; the thin one is only for
		# splitting tiles that share a background.
		"battery ${surface2} ${text}"
		"date_day ${teal} ${crust}"
		"date ${teal} ${crust} ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
		"time ${teal} ${crust} ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN}"
		# Other segments worth knowing about, all shipped with the plugin:
		#   "load ${surface2} ${subtext0}"       1/5/15-minute load average
		#   "mem_used ${surface2} ${subtext0}"   memory in use
		#   "kubernetes_context ${blue} ${crust}" current kubectl context
		#   "weather ${sky} ${crust}"            needs jq + curl, hits yr.no
		#   "utc_time ${teal} ${crust}"          second clock in UTC
		# `ls ~/.local/share/tmux/plugins/tmux-powerline/segments/` for the rest.
	)
fi
