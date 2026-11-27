# WezTerm

One config for WezTerm on macOS and on Windows. On Windows, the shell runs in
WSL2.

| File | Purpose |
| --- | --- |
| [`wezterm.lua`](wezterm.lua) | The config. It is plain Lua, not a chezmoi template, and it selects the OS behavior at run time from `wezterm.target_triple`. |
| [`machine.lua.tmpl`](machine.lua.tmpl) | The facts that WezTerm cannot find itself: the WSL2 distro and the login shell in it. chezmoi writes them from its machine data. They are empty on macOS. |

## Where the files go

| Platform | Location | How |
| --- | --- | --- |
| macOS | `~/.config/wezterm` | `chezmoi apply` |
| WSL2 | `%USERPROFILE%\.config\wezterm` | [`run_onchange_after_push-windows-configs.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_push-windows-configs.sh.tmpl) copies both files to Windows, because WezTerm runs there. chezmoi does not install `~/.config/wezterm` in WSL2. |

On Windows, WezTerm opens the WSL2 distro through its `WSL:<distro>` domain.
Thus a new tab or split opens in the same distro, in the directory of the pane.

## Startup

A plain start opens two tabs:

1. `opal`: the tmux coding workspace from
   [`dot_config/tmux/executable_dev-workspace.sh`](../tmux/executable_dev-workspace.sh).
2. `ruby`: a top and bottom split, as a tuios session from
   [`dot_config/tuios/`](../tuios/).

If another WezTerm window already has one of these sessions, the new window
opens a plain shell instead. A second window on the same session would resize
it and break the layout of the first window.

## Appearance

Window opacity, the macOS blur and the Windows backdrop are not in the config
files. WezTerm reads them from `~/.local/state/wezterm/appearance.json` and
loads them again when the file changes. Without the file, it uses the defaults
at the top of `wezterm.lua`.

To change them, run `wezterm_config` from
[`dot_config/zsh/src/wezterm.zsh`](../zsh/src/wezterm.zsh). It writes the
file. On WSL2, it writes the file in the Windows home. The change shows at
once, without `chezmoi apply`.

## Keys

WezTerm binds its own keys to `Cmd` on macOS and to `Ctrl-Shift` on Windows.
Plain `Ctrl` would take `Ctrl-C`, `Ctrl-W` and other keys from the shell, Neovim
and tmux. On macOS, both Option keys send `Alt`, because tmux uses many `Alt`
bindings. Thus Option does not type special characters in WezTerm.

## Links

WezTerm makes these text patterns clickable:

- URLs, also in brackets, and `file://` URLs.
- Email addresses.
- A branch name such as `TICKET-123/branch-name`, which opens that branch in the
  Flywheel monorepo on GitHub.
- `owner/repo`, which opens that repository on GitHub.
