-- WezTerm config for macOS and for Windows, where the shell lives in WSL2.
--
-- Plain Lua on purpose, not a chezmoi template: on macOS chezmoi deploys it to
-- ~/.config/wezterm, but on a WSL2 machine the WezTerm that reads it runs on
-- Windows, and a chezmoi run script inside WSL copies it to
-- %USERPROFILE%\.config\wezterm (run_onchange_after_push-windows-configs).
-- So the OS is decided here at runtime from wezterm.target_triple, and the few
-- per-machine facts WezTerm cannot find out itself come from machine.lua,
-- which chezmoi renders next to this file.

local wezterm = require("wezterm")

local mux = wezterm.mux
local act = wezterm.action

local is_macos = wezterm.target_triple:find("darwin") ~= nil
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- machine.lua (dot_config/wezterm/machine.lua.tmpl). The config dir is put on
-- package.path explicitly so this also works when WezTerm was pointed at the
-- file from elsewhere (--config-file).
package.path = wezterm.config_dir .. "/?.lua;" .. package.path
local has_machine, machine = pcall(require, "machine")
if not has_machine or type(machine) ~= "table" then
  machine = {}
end

-- =============================================================
-- Appearance
-- =============================================================
-- Tuned with `wezterm_config` (dot_config/zsh/src/wezterm.zsh), which writes
-- them to this state file - on WSL2 to the Windows side, where this WezTerm
-- runs. Read at runtime and on the reload watch list, so a change shows up
-- immediately without chezmoi. Opacities are authored 0-100.
local appearance = {
  windowBackgroundOpacity = 65,
  textBackgroundOpacity = 50,
  macosWindowBackgroundBlur = 20,
  -- Windows: "Acrylic" blurs like macOS; "Mica"/"Tabbed" only show through
  -- at windowBackgroundOpacity 0; "Disable" turns the backdrop off.
  win32SystemBackdrop = "Acrylic",
}
do
  local path = wezterm.home_dir .. "/.local/state/wezterm/appearance.json"
  wezterm.add_to_config_reload_watch_list(path)
  local file = io.open(path, "r")
  if file then
    local decode = (wezterm.serde and wezterm.serde.json_decode) or wezterm.json_parse
    local ok, saved = pcall(decode, file:read("*a"))
    file:close()
    if ok and type(saved) == "table" then
      for key, value in pairs(saved) do
        if type(value) == type(appearance[key]) then
          appearance[key] = value
        end
      end
    end
  end
end

-- =============================================================
-- Shell
-- =============================================================
-- Windows: the WSL2 distro chezmoi runs in, through the "WSL:<distro>" domain
-- WezTerm creates for every installed distro. A domain rather than a
-- `wsl.exe` default_prog, so new tabs and splits open in the same distro at
-- the pane's directory (the shell reports it with OSC 7, see wsl.zsh).
local wsl_domain = nil
if is_windows and machine.wsl_distro and machine.wsl_distro ~= "" then
  wsl_domain = "WSL:" .. machine.wsl_distro
end

local default_prog = nil
if is_macos then
  default_prog = { "/bin/zsh", "--login" }
elseif is_windows and not wsl_domain then
  default_prog = { "pwsh.exe", "-NoLogo" }
end

-- =============================================================
-- Hyperlink rules
-- =============================================================
-- Order matters: most specific first, most general last.
local hyperlink_rules = {
  -- Bracketed URLs
  { regex = [[\((\w+://[^\s)]+)\)]], format = "$1", highlight = 1 },
  { regex = [=[\[(\w+://[^\s\]]+)\]]=], format = "$1", highlight = 1 },
  { regex = [[\{(\w+://[^\s}]+)\}]], format = "$1", highlight = 1 },
  { regex = [[<(\w+://[^\s>]+)>]], format = "$1", highlight = 1 },

  -- Standard URLs
  { regex = [=[\b\w+://(?:[\w.-]+\.[a-z]{2,15})(?:/[^\s"'<>{}|\\^`\[\]]*)?]=], format = "$0" },

  -- file:// URLs
  { regex = [=[\bfile://[^\s"'<>{}|\\^`\[\]]*]=], format = "$0" },

  -- Email addresses
  { regex = [[\b[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,15}\b]], format = "mailto:$0" },

  -- FW branch: TICKET-123/branch-name --> GitHub monorepo tree link
  -- Must precede GitHub shorthand to avoid owner/repo misfire
  {
    regex = [=[[A-Z]+-[A-Z0-9]+/[\w/.-]+]=],
    format = "https://github.com/flywheel-jp/monorepo/tree/$0",
  },

  -- GitHub shorthand: owner/repo
  {
    regex = [=["?([a-z][\w-]{1,38})/([\w][\w.-]{0,99})"?]=],
    format = "https://github.com/$1/$2",
    highlight = 1,
  },
}

-- =============================================================
-- Key bindings
-- =============================================================
-- The "Cmd" layer. Plain CTRL anywhere but macOS would take Ctrl-C (SIGINT),
-- Ctrl-W, Ctrl-V, Ctrl-N, Ctrl-F and Ctrl-K away from the shell, nvim and
-- tmux - with default bindings off, whatever is bound here never reaches
-- them. CTRL|SHIFT is WezTerm's own non-macOS convention.
local mod_key = is_macos and "CMD" or "CTRL|SHIFT"

local mod_bindings = {
  { key = "w", action = act.CloseCurrentTab({ confirm = false }) },
  { key = "n", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "f", action = act.Search({ CaseSensitiveString = "" }) },
  { key = "c", action = act.CopyTo("Clipboard") },
  { key = "v", action = act.PasteFrom("Clipboard") },
  { key = "k", action = act.ActivateCommandPalette },
  { key = "0", action = act.ResetFontAndWindowSize },
  { key = "m", action = act.EmitEvent("toggle_maximize") },
  { key = "q", action = act.QuitApplication },
  { key = "=", action = act.IncreaseFontSize },
  { key = "-", action = act.DecreaseFontSize },
  { key = "RightArrow", action = act.ActivateTabRelative(1) },
  { key = "LeftArrow", action = act.ActivateTabRelative(-1) },
}
if not is_macos then
  -- With SHIFT held, a US layout reports some keys as their shifted symbol;
  -- bind those too so the font-size keys fire either way.
  table.insert(mod_bindings, { key = "+", action = act.IncreaseFontSize })
  table.insert(mod_bindings, { key = "_", action = act.DecreaseFontSize })
  table.insert(mod_bindings, { key = ")", action = act.ResetFontAndWindowSize })
end

local universal_bindings = {
  { key = "L", mods = "CTRL", action = act.ShowDebugOverlay },
}
if not is_windows then
  -- On Windows GlazeWM owns Alt+arrows globally (dot_glzr/glazewm), so these
  -- would never arrive.
  table.insert(universal_bindings, { key = "RightArrow", mods = "ALT", action = act.ActivateTabRelative(1) })
  table.insert(universal_bindings, { key = "LeftArrow", mods = "ALT", action = act.ActivateTabRelative(-1) })
end

local keys = {}
for _, binding in ipairs(mod_bindings) do
  table.insert(keys, { key = binding.key, mods = mod_key, action = binding.action })
end
for _, binding in ipairs(universal_bindings) do
  table.insert(keys, binding)
end

-- =============================================================
-- Window events
-- =============================================================
local is_maximized = false

wezterm.on("gui-startup", function(cmd)
  -- A plain launch opens the tmux dev workspace in the first tab; `wezterm
  -- start -- prog` (cmd ~= nil) runs what was asked for instead.
  local spawn_args = cmd or {}
  local workspace = false
  if cmd == nil then
    if wsl_domain then
      -- Absolute shell path: WezTerm starts the command inside the distro
      -- without its login PATH, where Homebrew's zsh is not on it yet.
      spawn_args = {
        domain = { DomainName = wsl_domain },
        args = { machine.wsl_shell or "/bin/zsh", "-lc", "exec ~/.config/tmux/dev-workspace.sh" },
      }
      workspace = true
    elseif not is_windows then
      local shell = default_prog or { os.getenv("SHELL") or "/bin/sh", "--login" }
      local argv = { table.unpack(shell) }
      table.insert(argv, "-c")
      table.insert(argv, "exec " .. wezterm.home_dir .. "/.config/tmux/dev-workspace.sh")
      spawn_args = { args = argv }
      workspace = true
    end
  end

  local tab1, _pane1, window1 = mux.spawn_window(spawn_args)
  if workspace then
    tab1:set_title("opal")
  end
  window1:gui_window():maximize()

  wezterm.time.call_after(0.3, function()
    local tab2, pane2 = window1:spawn_tab({})
    tab2:set_title("ruby")
    pane2:split({ direction = "Bottom", size = 0.3 })

    tab1:activate()
  end)
end)

wezterm.on("toggle_maximize", function(window, _pane)
  if is_maximized then
    window:restore()
  else
    window:maximize()
  end
  is_maximized = not is_maximized
end)

-- =============================================================
-- Config
-- =============================================================
local config = wezterm.config_builder()

config.default_prog = default_prog
config.default_domain = wsl_domain

-- Appearance
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("PlemolJP Console NF", { weight = "Medium", stretch = "Normal", style = "Normal" })
-- 22 suits the Mac's Retina panel; Windows scales by DPI itself.
config.font_size = is_macos and 22 or 12
config.window_background_opacity = appearance.windowBackgroundOpacity / 100
config.text_background_opacity = appearance.textBackgroundOpacity / 100
config.window_decorations = "RESIZE"
config.window_padding = { left = 10, right = 5, top = 10, bottom = 0 }

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

-- Scrollback & input
config.enable_scroll_bar = true
config.scrollback_lines = 10000
config.scroll_to_bottom_on_input = true
config.quick_select_patterns = { "[0-9a-f]{7,40}" }

-- Performance. WebGpu on the Mac; OpenGL on Windows, which is what the
-- hand-written Windows config this replaced settled on (WebGpu with
-- HighPerformance also keeps a hybrid laptop's discrete GPU awake).
config.max_fps = 120
config.animation_fps = 1
if is_windows then
  config.front_end = "OpenGL"
else
  config.front_end = "WebGpu"
  config.webgpu_power_preference = "HighPerformance"
end

-- Misc
config.use_resize_increments = false
config.adjust_window_size_when_changing_font_size = false
config.window_close_confirmation = "NeverPrompt"
config.disable_default_key_bindings = true

-- Rules & bindings
config.hyperlink_rules = hyperlink_rules
config.keys = keys

if is_macos then
  config.macos_window_background_blur = appearance.macosWindowBackgroundBlur

  -- Both Option keys must send ESC-prefixed sequences, not composed glyphs.
  -- tmux.conf drives nearly everything off M-* bindings, and by default one
  -- Option key composes (M-j -> "∆", M-l -> "¬"), which both loses the binding
  -- and inserts junk. Pinning both sides makes it deterministic. Trade-off:
  -- Option can no longer type accented/special characters in the terminal.
  config.send_composed_key_when_left_alt_is_pressed = false
  config.send_composed_key_when_right_alt_is_pressed = false
end

if is_windows then
  config.win32_system_backdrop = appearance.win32SystemBackdrop
  -- Matches the hand-written Windows config this replaced: PlemolJP runs a
  -- little wide at Windows' font rendering.
  config.cell_width = 0.9
end

return config
