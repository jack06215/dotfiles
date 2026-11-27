# lspconfig

[neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) starts the
LSP servers. [`config.lua`](config.lua) sets up each server in `lsp_list` in
[`lua/lsp-config/base.lua`](../../lsp-config/base.lua):

`bashls`, `clangd`, `denols`, `dockerls`, `gopls`, `helm_ls`, `jsonls`,
`jsonnet_ls`, `lua_ls`, `marksman`, `pyright`, `regols`, `rubocop`, `ruby_lsp`,
`sqlls`, `terraformls`, `yamlls`, and `powershell_es` on Windows only.

## How config.lua sets up a server

1. The options start from `capabilities` and `on_attach` in `base.lua`.
2. If `lua/lsp-config/settings/<server>.lua` exists, its table goes on top.
3. If the program of the server is not installed, `config.lua` skips the
   server.
   The list covers servers from brew, npm and gem, and no machine has all of
   them. Without this check, each buffer of that filetype showed a "Spawning
   language server failed" error.

## Notes

- There is no `ts_ls`. `typescript-tools.nvim` is the TypeScript server, see
  [`../typescript/`](../typescript/). Two servers on one buffer make lspsaga's
  peek definition open two windows.
- `powershell_es` runs from a Windows module path under `pwsh.exe`, so it works
  only on native Windows.
- [`../ui/`](../ui/) turns off inlay hints for this plugin.
