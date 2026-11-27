# telescope

[nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
is a picker. The prompt is at the top, and results go down from it.

| Key | Picker |
| --- | --- |
| `<leader>ff` | Files |
| `<leader>fb` | Buffers |
| `<leader>fg` | Live grep |
| `<leader>fr` | Resume the last picker |
| `<leader>ft` | Tree-sitter symbols |
| `<leader>fo` | Recent files |
| `<leader>fp` | Files of a plugin |
| `<leader>fh` | Help tags |
| `<leader>fk` | Keymaps |
| `<leader>fm` | Marks |
| `<leader>fs` | Symbols of the document |
| `<leader>fS` | Symbols of the workspace |
| `<leader>fC` | Commands |

The keys come from two files:

- [`keymaps.lua`](keymaps.lua): the keys that LazyVim does not bind, in the
  spec.
- [`lua/config/keymaps/telescope.lua`](../../config/keymaps/telescope.lua):
  `ff`, `fb`, `fg`, `fr` and `ft`. These are also LazyVim keys, so they must
  come after which-key applies the LazyVim keys.
