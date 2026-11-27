# VS Code

chezmoi installs this folder as `~/.config/vscode`. VS Code does not read that
path, so a script on each platform puts the two files where VS Code reads them.

| File | Purpose |
| --- | --- |
| [`settings.json.tmpl`](settings.json.tmpl) | The user settings. On a machine with the monorepo venv, it also sets that venv's Python as the Python command for nvicode. |
| [`keybindings.json`](keybindings.json) | The user keybindings. |

## How the files reach VS Code

| Platform | Script | Method |
| --- | --- | --- |
| macOS | [`run_onchange_after_link-vscode-config.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_link-vscode-config.sh.tmpl) | Symlinks the two files in `~/Library/Application Support/Code/User` to the files in `~/.config/vscode`. If VS Code already has a regular file there, the script keeps it as a copy with a timestamp. |
| Windows | [`run_onchange_after_link-vscode-config.ps1.tmpl`](../../.chezmoiscripts/run_onchange_after_link-vscode-config.ps1.tmpl) | Copies the two files into `%APPDATA%\Code\User`, because a symlink needs admin rights or Developer Mode. The script runs again when the files change. |
| WSL2 | [`run_onchange_after_push-windows-configs.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_push-windows-configs.sh.tmpl) | Copies the two files into the Windows VS Code user folder, which Remote-WSL also uses. chezmoi does not install `~/.config/vscode` on WSL2. |

## Extensions

[`.chezmoidata/vscode.toml`](../../.chezmoidata/vscode.toml) lists the
extension IDs in groups. On macOS and WSL2,
[`run_onchange_after_install-vscode-extensions.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_install-vscode-extensions.sh.tmpl)
installs each extension that is missing. On WSL2, it uses the `code` command of
the Windows VS Code. The script runs again when the list changes, and when VS
Code becomes available.

- chezmoi reads the list on each apply, so an edit needs no `chezmoi init`.
- When you delete an entry, the script does not uninstall the extension.
- `bazel run //tools/setup:export_vscode_extensions` adds the installed
  extensions that the list does not have. It puts them under a marker at the
  end of the list. Move them into a group.
- nvicode (`jack06215.nvim-in-vscode`) is not in the list. The monorepo
  installs it from its own `.vsix` file.
