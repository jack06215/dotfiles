# Setup tools (repo only)

These tools maintain this repository. Most of them read a live machine and
write its state back into the checkout: a package manifest, an extension list or
app settings. chezmoi does not install this folder.

| Command | Run on | What it does |
| --- | --- | --- |
| `bazel run //tools/setup:export_brewfile_macos` | macOS | Writes [`brewfiles/darwin`](../../brewfiles/darwin) from the installed Homebrew packages. |
| `bazel run //tools/setup:export_brewfile_linux` | Linux, WSL2 | Writes [`brewfiles/wsl2`](../../brewfiles/wsl2) from the installed Homebrew packages. |
| `bazel run //tools/setup:export_vscode_extensions` | macOS, Linux, WSL2 | Adds the installed VS Code extensions to [`.chezmoidata/vscode.toml`](../../.chezmoidata/vscode.toml). |
| `bazel run //tools/setup:export_powertoys_settings` | Windows | Writes the PowerToys settings of this machine into [`dot_config/powertoys/`](../../dot_config/powertoys/). |
| `bazel run //tools/setup:copy_untrap_settings` | any | Copies the Untrap for YouTube settings to the clipboard, base64-encoded, for the import box of the extension. |
| `pwsh tools/setup/generate-chocofile.ps1` | Windows | Writes the Chocolatey manifest from the installed packages. |
| `"$(chezmoi source-path)/tools/setup/generate-termux-packages.sh"` | Termux | Writes [`pkgfiles/termux`](../../pkgfiles/termux). See [`docs/termux-setup.md`](../../docs/termux-setup.md). |
| [`termux_install_claude_code.sh`](termux_install_claude_code.sh) | Termux | Installs Claude Code. `~/setup.sh` runs it. It comes from claude-code-android. |

## Bazel

[`BUILD.bazel`](BUILD.bazel) defines only `bazel run` targets. Bazel builds
nothing in this folder. Two scripts have no target:

- `generate-chocofile.ps1`, because no Bazel rule in this workspace can run a
  `.ps1` file.
- `generate-termux-packages.sh`, because Bazel is not installed on the phone.

[`generate-brewfile.sh`](generate-brewfile.sh) also runs without Bazel. Outside
Bazel, it asks `chezmoi source-path` where the checkout is.

[`.bazelrc`](../../.bazelrc) sets `--symlink_prefix=/`. Without it, Bazel puts
`bazel-*` symlinks in the repository root, and chezmoi would install them in
`$HOME`.

Bazel in this repository is only for tasks that maintain the repository. A tool
that needs its own Python packages or a build belongs in the monorepo.
