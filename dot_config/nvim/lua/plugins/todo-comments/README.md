# todo-comments

[folke/todo-comments.nvim](https://github.com/folke/todo-comments.nvim)
highlights `TODO`, `FIX`, `FIXME` and similar comments, and lists them.

| Key | Action |
| --- | --- |
| `<leader>xt` | All todo comments, in Trouble. |
| `<leader>xT` | Only `TODO`, `FIX` and `FIXME`, in Trouble. |
| `<leader>st` | All todo comments, in telescope. |

The keys are in
[`lua/config/keymaps/todo-comments.lua`](../../config/keymaps/todo-comments.lua),
not in the spec. These keys are also LazyVim defaults, so they must come after
which-key applies the LazyVim keys. The plugin loads at the first
`:TodoTrouble`, `:TodoTelescope` or `:TodoQuickFix`, or when a file opens.

[`config.lua`](config.lua) also loads the telescope extension of the plugin.
