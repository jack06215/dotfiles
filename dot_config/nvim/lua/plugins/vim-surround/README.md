# vim-surround

[tpope/vim-surround](https://github.com/tpope/vim-surround) adds, changes and
deletes the quotes, brackets and tags around text: `ys` adds, `cs` changes and
`ds` deletes. The plugin loads at the first `ys`.

`vscode = true` makes it load in vscode-neovim too. It only edits text, so it
works there unchanged. The LazyVim vscode extra loads only the specs that set
this field.

The config is in [`config.lua`](config.lua).
