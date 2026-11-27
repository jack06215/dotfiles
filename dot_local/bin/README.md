# ~/.local/bin

chezmoi installs this folder as `~/.local/bin` (`$XDG_BIN_HOME`).
[`dot_zshenv.tmpl`](../../dot_zshenv.tmpl) puts it at the front of `PATH`.

## zshfn: zsh functions as commands

A zsh function exists only in an interactive shell. Neovim's `!cmd`, xargs,
Makefiles and git aliases run `$SHELL -c`, which reads only `.zshenv`. For them,
the function does not exist.

[`executable_zshfn`](executable_zshfn) solves this. Each symlink to it is a
command. `zshfn` reads the symlink name, sources the library for that name from
`$ZDOTDIR/src`, and calls the function with the same arguments.

| Command | Library in [`dot_config/zsh/src/`](../../dot_config/zsh/src/) |
| --- | --- |
| `s3_fetch_blob` | `aws.zsh` |
| `claude_cmds` | `claude.zsh` |
| `jqc`, `jqf` | `jq.zsh` |
| `tk`, `tockpick` | `tock.zsh` |

To make a zsh function a command:

1. Add `<name> <library>.zsh` to the `funcs` map in `executable_zshfn`.
2. In this folder, create `symlink_<name>` with the text `zshfn`. chezmoi makes
   `~/.local/bin/<name>` a symlink to `zshfn`.
3. Run `chezmoi apply`.

Do not copy the function body into a script in this folder. The symlink runs
the one copy in `src/`.

A `pycli` tool from the monorepo needs no symlink, because
[`pycli.zsh.tmpl`](../../dot_config/zsh/src/pycli.zsh.tmpl) makes a zsh
function for each tool. Add a symlink only when a non-interactive caller needs
the tool.

chezmoi does not delete a file that leaves the source. When you delete a
`symlink_<name>`, also delete `~/.local/bin/<name>` by hand.

## Shims

[`.chezmoiignore`](../../.chezmoiignore) installs each shim only on the
platforms that need it.

| File | Platform | Purpose |
| --- | --- | --- |
| [`executable_pbcopy.tmpl`](executable_pbcopy.tmpl), [`executable_pbpaste.tmpl`](executable_pbpaste.tmpl) | WSL2, Termux | The macOS clipboard commands, for tmux, lazygit and scripts. On WSL2 they use `win32yank.exe`. On Termux they use `termux-clipboard-set` and `termux-clipboard-get`, which need the Termux:API app. macOS has the real commands in `/usr/bin`. |
| [`symlink_powershell.exe`](symlink_powershell.exe) | WSL2 | Puts the Windows `powershell.exe` on `PATH`. `appendWindowsPath=false` keeps Windows programs off `PATH`, but some tools look for this one by name, for example the image paste in Neovim. |
| [`executable_pinentry-wslg`](executable_pinentry-wslg) | WSL2 | The pinentry for gpg-agent. It runs `pinentry-qt` on the Wayland platform of Qt, because the X11 window draws black under WSLg. |

On Termux, Android drops a copy of about 1 MB or more without an error. For a
copy over 512 KB, `pbcopy` reads the clipboard back and exits with an error if
the copy did not arrive.
