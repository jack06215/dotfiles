# ui

Small changes to the LSP interface:

- **Hover.** [`config.lua`](config.lua) replaces the `textDocument/hover`
  handler. The new handler removes empty lines from the hover text, and shows
  nothing when the result is empty.
- **Inlay hints** are off (an option of nvim-lspconfig).
- **Code action preview.**
  [aznhe21/actions-preview.nvim](https://github.com/aznhe21/actions-preview.nvim)
  shows a diff of each code action before you apply it. Press `<leader>ca` in
  normal or visual mode. The diff uses the patience algorithm and ignores
  white space. This plugin owns `<leader>ca`. lspsaga does not bind it, see
  [`../lspsage/`](../lspsage/).
- **Unused code.** [0oAstro/dim.lua](https://github.com/0oAstro/dim.lua) dims
  unused variables and functions, and removes the LSP decorations from them.
