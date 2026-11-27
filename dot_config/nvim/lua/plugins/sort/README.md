# sort

[sQVe/sort.nvim](https://github.com/sQVe/sort.nvim) sorts lines, and the items
in a line between delimiters. The delimiters are `,`, `|`, `;` and space.

| Key (visual mode) | Action |
| --- | --- |
| `<leader>so` | Sort the lines, ascending, with the Vim `:sort` command. |
| `<leader>sO` | Sort the lines, descending, with `:sort!`. |
| `<leader>SD` | Sort with the plugin (`:Sort`). In a selection inside one line, it sorts the items. |

The plugin only changes the lines of the buffer, so it also works in
vscode-neovim (`vscode = true`).

The config is in [`config.lua`](config.lua), and the keys are in
[`keymaps.lua`](keymaps.lua).
