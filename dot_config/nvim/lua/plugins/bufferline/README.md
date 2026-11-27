# bufferline

[akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim) shows
the open buffers as tabs at the top of the window.

- Each tab shows the buffer number and its position, and the LSP error or
  warning count.
- A new buffer opens next to the current one.
- Tabs have no close buttons. The close button shows when the mouse is on a
  tab.
- Above the neo-tree window, the bar shows `File Explorer`.

## Groups

[`config.lua`](config.lua) puts each buffer in a group by its file name and
path. Each group has a priority and an underline color:

| Group | Examples of matching files |
| --- | --- |
| Tests | `*_test.*`, `*.test.*`, `*.spec.*`, files in a `test/` or `tests/` folder |
| Docs | documentation files |
| Build / Bazel | build files |
| Infrastructure as Code | infrastructure files |
| Neovim | Neovim config files |
| Backend | backend source files |
| Config | config files |
| Frontend | web source files |
| SQL / Data | SQL and data files |

`config.lua` holds the exact match rules for each group. When you enter a
group, the other groups collapse (`toggle_hidden_on_enter`).

[`lua/config/keymaps/bufferline.lua`](../../config/keymaps/bufferline.lua)
defines no keys now. The LazyVim buffer keys apply.
