# comment

[numToStr/Comment.nvim](https://github.com/numToStr/Comment.nvim) comments and
uncomments lines. The keys come from [`keymaps.lua`](keymaps.lua):

| Key | Mode | Action |
| --- | --- | --- |
| `gcc` | normal | Comment or uncomment the current line. |
| `gc` | visual | Comment or uncomment the selection. |
| `gcb` | normal | Put a commented copy of the current line above it. The cursor stays on the original line. |
| `gC` | normal, visual | Invert the comment state of each line. |
| `gcA` | normal | Add a comment at the end of the line, and start insert mode after it. |

- Comment.nvim skips empty lines.
- In TypeScript React files, `nvim-ts-context-commentstring` selects the
  comment style from the tree-sitter context, for example `{/* */}` in JSX.
- `gcA` uses only `commentstring`, not Comment.nvim. Thus vscode-neovim can
  use the same function, from
  [`lua/config/keymaps/vscode.lua`](../../config/keymaps/vscode.lua).

| File | Purpose |
| --- | --- |
| [`init.lua`](init.lua) | The spec. |
| [`config.lua`](config.lua) | The Comment.nvim setup and the TSX hook. |
| [`keymaps.lua`](keymaps.lua) | The keys. |
| [`utils.lua`](utils.lua) | The line check and the end-of-line comment function. |
