# lspsaga

[nvimdev/lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim) shows LSP
results in windows: diagnostics, rename, signature help and peek. The folder
name is `lspsage`, but the plugin is lspsaga.

| Key | Action |
| --- | --- |
| `<leader>cd` | Diagnostics of the current line. |
| `<leader>cr` | Rename the symbol. |
| `<leader>cs` | Signature help. |
| `gd` | Go to the definition. |
| `gh` | Peek the definition in a window. |

The keys are in
[`lua/config/keymaps/lspsaga.lua`](../../config/keymaps/lspsaga.lua), not in
the spec. These keys are also LazyVim defaults, so they must come after
which-key applies the LazyVim keys. The spec has no `keys`, so it sets
`lazy = true` itself. `lua/config/lazy.lua` sets `defaults.lazy = false`.

- `<leader>ca` (code action) belongs to actions-preview in
  [`../ui/`](../ui/). That plugin loads at the first LSP attach, and lazy.nvim
  then sets its keys again. A lspsaga binding would last only until that time.
- The LSP finder (`<leader>cf`) is a comment in the keymap file, so it is not
  bound.

The lightbulb and the winbar symbols are off, and the windows have round
borders. The config is in [`config.lua`](config.lua).
