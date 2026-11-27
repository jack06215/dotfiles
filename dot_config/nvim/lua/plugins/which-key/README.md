# which-key

[folke/which-key.nvim](https://github.com/folke/which-key.nvim) shows a popup
with the next keys after you press a prefix such as `<leader>`.

[`config.lua`](config.lua) adds its entries to the LazyVim spec. which-key
appends a `spec` list, it does not replace it. The entries are:

- The group names below.
- All the entries of [`lazyvim-defaults.lua`](lazyvim-defaults.lua).

| Prefix | Group |
| --- | --- |
| `<leader><tab>` | Tabs |
| `<leader>b` | Buffer |
| `<leader>c` | Code |
| `<leader>C` | CodeCompanion |
| `<leader>d` | Debug |
| `<leader>f` | File/Find |
| `<leader>g` | Git |
| `<leader>l` | Linter |
| `<leader>m` | Conform |
| `<leader>o` | Octo |
| `<leader>p` | Python/Packages |
| `<leader>pj` | package.json |
| `<leader>py` | Python |
| `<leader>q` | Quit/Session |
| `<leader>s` | Search |
| `<leader>u` | UI |
| `<leader>w` | Windows |
| `<leader>x` | Diagnostics/Quickfix |

## lazyvim-defaults.lua

This file holds all the `<leader>` keys of LazyVim v16 as which-key entries.
To change or remove a LazyVim default key, edit its entry here. You do not
need to find it in the LazyVim source.

The file uses three comment markers. The legend at the top of the file
describes them too:

| Marker | Meaning |
| --- | --- |
| `[removed]` | The LazyVim key is a comment, so it is not bound. |
| `[yours]` | A file in this config binds this key. The comment gives the file and the line. |
| `[lsp]` | LazyVim binds this key for each buffer, only when the LSP server supports the feature. The entry is a comment, for reference. |

which-key applies the spec late.
[`lua/config/keymaps.lua`](../../config/keymaps.lua) waits for it, then
applies the keymaps of this config on top. See
[`dot_config/nvim/README.md`](../../../README.md#keymaps).
