# vim-matchup

[andymass/vim-matchup](https://github.com/andymass/vim-matchup) extends `%` to
words such as `if` and `end`, and to tags, through tree-sitter. It also adds
`g%`, `[%`, `]%` and the `a%` and `i%` text objects.

- When the match is off the screen, a popup shows it.
- The match highlight waits for a short time after the cursor moves: 300 ms in
  normal mode and 60 ms in insert mode.
- Surround operations on match pairs are on.

## vscode-neovim

`vscode = true` makes the plugin load in vscode-neovim. The motions and the
text objects work there. The match highlight is off, because VS Code shows its
own bracket match and cannot show the highlight or the popup of matchup.

The config is in [`config.lua`](config.lua).
