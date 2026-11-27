# yazi

[yazi](https://yazi-rs.github.io/) is a terminal file manager. chezmoi installs
this folder as `~/.config/yazi`. On Windows, yazi reads `%APPDATA%\yazi\config`
instead.

Run `y`, not `yazi`.
[`dot_config/zsh/src/yazi.zsh`](../zsh/src/yazi.zsh) defines `y`: when you
quit with `q`, the shell changes to the directory that you were in. Quit with
`Q` to stay in the old directory.

## Files

Each config file holds only the changes from the yazi preset. yazi merges it
over its built-in defaults, so a setting that is not here follows upstream.

| File | Purpose |
| --- | --- |
| [`yazi.toml.tmpl`](yazi.toml.tmpl) | Openers, previewers and fetchers. On WSL2, `open` uses `wslview` and `reveal` uses Explorer, because `xdg-open` has no Windows desktop. |
| [`keymap.toml.tmpl`](keymap.toml.tmpl) | Keys added in front of the preset keys (`prepend_keymap`), so that they replace a preset binding on the same key. |
| [`theme.toml`](theme.toml) | Selects the Catppuccin Mocha flavor. The flavor itself is a package. |
| [`init.lua.tmpl`](init.lua.tmpl) | Setup for the plugins that need Lua: `full-border` and `git`, and `mactag` on macOS. |
| [`package.toml.tmpl`](package.toml.tmpl) | The plugins and the flavor, each pinned to a revision. |

## Packages

`ya pkg install` clones each package in `package.toml` into `plugins/` and
`flavors/`. [`.chezmoiignore`](../../.chezmoiignore) ignores those two folders,
because they are upstream code.

- macOS, Linux and WSL2:
  [`.chezmoiscripts/run_onchange_after_install-yazi-packages.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_install-yazi-packages.sh.tmpl)
  runs `ya pkg install`. It runs again when `package.toml` changes, and when
  `ya` becomes available. On a new machine, the first apply comes before
  `setup.sh` installs yazi, so the final apply in `setup.sh` installs the
  packages.
- Windows:
  [`.chezmoiscripts/run_onchange_after_install-yazi-packages.ps1.tmpl`](../../.chezmoiscripts/run_onchange_after_install-yazi-packages.ps1.tmpl)
  writes `package.toml` itself and runs `ya pkg install` with the yazi config
  path for Windows. chezmoi does not manage `package.toml` on Windows, because
  `ya` rewrites its hashes there.

> [!IMPORTANT]
> yazi does not start if `init.lua` requires a plugin that `package.toml` does
> not install. When you add or remove a plugin, change both files. `mactag` is
> in both files only on macOS, because it needs the macOS `tag` command.
