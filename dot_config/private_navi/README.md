# navi cheatsheets

[navi](https://github.com/denisidoro/navi) shows cheatsheets in fzf. Press
`Ctrl-G` in zsh or nushell, select a command, and fill in its variables. navi
puts the result on the command line. chezmoi installs this folder as
`~/.config/navi`.

The cheatsheets are a port of the pet snippets in
[`dot_config/private_pet/`](../private_pet/). navi does not replace pet. pet
keeps `Ctrl-O`, and navi uses `Ctrl-G`.

| Path | Shell | Purpose |
| --- | --- | --- |
| [`config.yaml.tmpl`](config.yaml.tmpl) | both | The navi config: the cheatsheet path and the fzf options. |
| [`cheats/`](cheats/) | zsh | One `.cheat` file for each topic: aws, chezmoi, claude, gh, git, homebrew, k8s, opencc and shell. `homebrew-macos.cheat` holds the commands that only work on macOS, and chezmoi installs it only there. |
| [`cheats-nu/nu.cheat`](cheats-nu/nu.cheat) | nushell | The nushell pipelines. |

## How each shell finds its cheatsheets

- zsh: [`dot_config/zsh/src/navi.zsh`](../zsh/src/navi.zsh) loads the navi
  widget and binds `Ctrl-G`. navi reads `cheats/`, as `config.yaml` says.
- nushell: the `navi` command in
  [`dot_config/nushell/function.nu`](../nushell/function.nu) adds
  `--path ~/.config/navi/cheats-nu`. This option replaces only the cheatsheet
  path, so the fzf options in `config.yaml` still apply.

## Why the config sets the paths

- **The config file.** navi has a fixed default config path. On macOS, that
  path is in `~/Library/Application Support/navi`.
  [`dot_zshenv.tmpl`](../../dot_zshenv.tmpl) sets `NAVI_CONFIG` to
  `~/.config/navi/config.yaml`.
- **The cheatsheet folder.** navi also has a per-OS default for cheatsheets.
  `config.yaml` sets `cheats.paths` so that all machines read this folder.
  navi does not expand `~` or variables in that list, so chezmoi writes an
  absolute path into it.

## Notes

- `overrides_var` in `config.yaml` has `--no-select-1`. Without it, fzf accepts
  a variable that has only one suggestion and shows no prompt. Each default
  from pet is one suggestion, so you could not edit it.
- navi writes `navi.log` in this folder. `.chezmoiignore` ignores that file.
