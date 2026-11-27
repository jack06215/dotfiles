# pet snippets

[pet](https://github.com/knqyf263/pet) keeps command snippets. Press `Ctrl-O`
in zsh or nushell to search them in fzf. pet puts the snippet that you select on
the command line. chezmoi installs this folder as `~/.config/pet`.

zsh and nushell have separate snippets, so that nushell pipelines stay out of
the zsh picker.

| File | Shell | Purpose |
| --- | --- | --- |
| [`config.toml.tmpl`](config.toml.tmpl) | zsh | The pet config. It reads `snippet.toml`, and on macOS also every `.toml` file in `snippets-macos/`. |
| [`snippet.toml`](snippet.toml) | zsh | The zsh snippets. `pet new` writes here. |
| [`snippets-macos/homebrew.toml`](snippets-macos/homebrew.toml) | zsh (macOS) | Snippets that only work on macOS. They are in a separate folder, so `snippet.toml` stays a plain file that `pet new` can write. |
| [`config.nu.toml.tmpl`](config.nu.toml.tmpl) | nushell | The same config, but it reads only `snippet.nu.toml`. |
| [`snippet.nu.toml`](snippet.nu.toml) | nushell | The nushell snippets. |
| [`scripts/gh_pr_reviews.py`](scripts/gh_pr_reviews.py) | any | Prints the pull requests that one author opened in a repository between two dates, with their reviews, as JSON. It uses `gh api graphql`. |

## How each shell finds its snippets

- zsh: [`dot_config/zsh/src/pet.zsh`](../zsh/src/pet.zsh) binds `Ctrl-O` to
  `pet search`, which reads the default config.
- nushell: the `pet` command in
  [`dot_config/nushell/function.nu`](../nushell/function.nu) adds
  `--config ~/.config/pet/config.nu.toml`. Thus `pet new`, `pet edit` and
  `pet list` in nushell use the nushell snippets.

To add a snippet, run `pet new` in the shell that the snippet is for.

## Notes

- The binding is `Ctrl-O`, not `Ctrl-S`, because `Ctrl-S` is the tmux prefix.
  `pet.zsh` also turns off flow control (`stty -ixon`). In tmux, `Ctrl-S`
  `Ctrl-S` sends a literal `^S`, which would otherwise stop the terminal output.
- `private_` makes the folder readable only by you. The config contains token
  fields for Gist and GitLab sync.
- [`dot_config/private_navi/`](../private_navi/) has the same snippets as navi
  cheatsheets, on `Ctrl-G`.
