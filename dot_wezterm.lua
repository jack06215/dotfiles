local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

default_prog = { "pwsh" }

local hyperlink_rules = {
	{ regex = "\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b", format = "$0" },
	{ regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b", format = "mailto:$0" },
	{ regex = "\\bfile://\\S*\\b", format = "$0" },
	{ regex = "\\((\\w+://\\S+)\\)", format = "$1", highlight = 1 },
	{ regex = "\\[(\\w+://\\S+)\\]", format = "$1", highlight = 1 },
	{ regex = "\\{(\\w+://\\S+)\\}", format = "$1", highlight = 1 },
	{ regex = "<(\\w+://\\S+)>", format = "$1", highlight = 1 },
	{ regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+", format = "$0" },
	{ regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b", format = "mailto:$0" },
	{
		regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
		format = "https://www.github.com/$1/$3",
	},
}
local is_maximized = false

wezterm.on("gui-startup", function(cmd)
	-- Create initial window and pane
	local tab, left, window = mux.spawn_window(cmd or {})

	-- Maximize window
	window:gui_window():maximize()
	is_maximized = true -- optional flag if you use it elsewhere

	-- Split vertically (Right)
	local right = left:split({ direction = "Right", size = 0.5 })

	-- Split horizontally on LEFT
	local bottom_left = left:split({ direction = "Bottom", size = 0.5 })
end)

wezterm.on("toggle_maximize", function(window, pane)
	if is_maximized then
		window:restore()
		is_maximized = false
	else
		window:maximize()
		is_maximized = true
	end
end)

local keys = {
	{
		key = "p",
		mods = "CTRL | SHIFT",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(wezterm.action.ActivateCommandPalette, pane)
		end),
	},
	{ key = "L", mods = "CTRL", action = act.ShowDebugOverlay },
	-- { key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) },
	-- { key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "CTRL", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
	{ key = "w", mods = "CTRL", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "n", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CTRL", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "n", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "RightArrow", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "LeftArrow", mods = "CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "f", mods = "CTRL", action = act.Search({ CaseSensitiveString = "" }) },
	-- { key = "c", mods = "CTRL", action = act.CopyTo("Clipboard") },
	-- { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "0", mods = "CTRL", action = act.ResetFontAndWindowSize },
	{ key = "m", mods = "CTRL", action = act.EmitEvent("toggle_maximize") },
	{ key = "q", mods = "CTRL", action = act.QuitApplication },
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
}

return {
	default_prog = default_prog,
	color_scheme = "Catppuccin Mocha",
	enable_tab_bar = true,
	set_environment_variables = {
		TERM = "wezterm",
	},
	enable_scroll_bar = true,
	disable_default_key_bindings = true,
	font = wezterm.font("PlemolJP Console NF", { weight = "Medium", stretch = "Normal", style = "Normal" }),
	font_size = 12,
	window_background_opacity = 0.9,
	text_background_opacity = 0.65,
	hide_tab_bar_if_only_one_tab = true,
	hyperlink_rules = hyperlink_rules,
	keys = keys,
	scrollback_lines = 10000,
	tab_bar_at_bottom = true,
	use_resize_increments = true,
	use_fancy_tab_bar = false,
	scroll_to_bottom_on_input = true,
	quick_select_patterns = {
		"[0-9a-f]{7,40}",
	},
	front_end = "OpenGL",
	webgpu_power_preference = "HighPerformance",
	window_decorations = "INTEGRATED_BUTTONS|RESIZE",
	window_padding = {
		left = 10,
		right = 5,
		top = 10,
		bottom = 0,
	},
	window_close_confirmation = "NeverPrompt",
	adjust_window_size_when_changing_font_size = false,
}
