local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

-- Detect platform and set shell
local os_name = wezterm.target_triple
local default_prog = nil

if os_name:find("windows") then
	default_prog = { "pwsh.exe" }
elseif os_name:find("darwin") then
	default_prog = { "/bin/zsh", "--login" }
elseif os_name:find("linux") then
	if os.getenv("PREFIX") and os.getenv("PREFIX"):find("com.termux") then
		default_prog = { "pwsh" } -- assume pwsh is installed in Termux
	else
		default_prog = { "pwsh" } -- regular Linux (Ubuntu, Arch, etc.)
	end
else
	default_prog = { "bash" } -- fallback
end

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
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
	is_maximized = true
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

-- Common keybindings shared across OSes
local keys_common = {
	{
		key = "p",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(wezterm.action.ActivateCommandPalette, pane)
		end),
	},
	-- Show debug overlay
	{ key = "L", mods = "CTRL", action = act.ShowDebugOverlay },

	-- Switch to next tab (ALT + →)
	{ key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) },

	-- Switch to previous tab (ALT + ←)
	{ key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) },

	-- New tab fallback (CTRL + N)
	{ key = "n", mods = "CTRL", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
}

-- OS-specific keybindings
local keys = {}

if os_name:find("windows") or os_name:find("linux") then
	keys = {
		-- Close current tab
		{ key = "w", mods = "CTRL", action = act.CloseCurrentTab({ confirm = false }) },

		-- New tab
		{ key = "n", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },

		-- Switch tabs
		{ key = "RightArrow", mods = "CTRL", action = act.ActivateTabRelative(1) },
		{ key = "LeftArrow", mods = "CTRL", action = act.ActivateTabRelative(-1) },

		-- Search
		{ key = "f", mods = "CTRL", action = act.Search({ CaseSensitiveString = "" }) },

		-- Copy / Paste
		{ key = "c", mods = "CTRL", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },

		-- Reset font and window size
		{ key = "0", mods = "CTRL", action = act.ResetFontAndWindowSize },

		-- Toggle maximize
		{ key = "m", mods = "CTRL", action = act.EmitEvent("toggle_maximize") },

		-- Quit
		{ key = "q", mods = "CTRL", action = act.QuitApplication },

		-- Increase font size
		{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },

		-- Decrease font size
		{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
		-- Disable this key
		{ key = "w", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
		-- Disable this key
		{ key = "q", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
	}
elseif os_name:find("darwin") then
	keys = {
		-- Close current tab
		{ key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = false }) },

		-- New tab
		{ key = "n", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },

		-- Switch tabs
		{ key = "RightArrow", mods = "CMD", action = act.ActivateTabRelative(1) },
		{ key = "LeftArrow", mods = "CMD", action = act.ActivateTabRelative(-1) },

		-- Search
		{ key = "f", mods = "CMD", action = act.Search({ CaseSensitiveString = "" }) },

		-- Copy / Paste
		{ key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },

		-- Reset font and window size
		{ key = "0", mods = "CMD", action = act.ResetFontAndWindowSize },

		-- Toggle maximize
		{ key = "m", mods = "CMD", action = act.EmitEvent("toggle_maximize") },

		-- Quit
		{ key = "q", mods = "CMD", action = act.QuitApplication },

		-- Increase font size
		{ key = "=", mods = "CMD", action = act.IncreaseFontSize },

		-- Decrease font size
		{ key = "-", mods = "CMD", action = act.DecreaseFontSize },
	}
end

-- Merge OS-specific keys with common keys
for _, k in ipairs(keys_common) do
	table.insert(keys, k)
end

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
	window_background_opacity = 0.65, -- Set window transparency
	text_background_opacity = 0.65, -- Set text background transparency
	macos_window_background_blur = 30, -- blur for macOS
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
