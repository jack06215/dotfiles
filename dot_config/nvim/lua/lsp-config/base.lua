local M = {}

-- List of all LSP servers to register
-- Foloow https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#jsonnet_ls to use jsonnet_ls
M.lsp_list = {
  "bashls",
  "clangd",
  "denols",
  "dockerls",
  "gopls",
  "helm_ls",
  "jsonls",
  "jsonnet_ls",
  "lua_ls",
  "marksman",
  "pyright",
  "regols",
  "rubocop",
  "ruby_lsp",
  "sqlls",
  "terraformls",
  -- No tsserver/ts_ls: typescript-tools.nvim (plugins/typescript) is the
  -- TypeScript server. Running both puts two clients on every TS buffer, and
  -- lspsaga's peek_definition opens one float per client that answers.
  "yamlls",
}

-- PowerShellEditorServices runs from the Windows module path in
-- settings/powershell_es.lua (C:/Users/...), under pwsh.exe: native Windows
-- only. On macOS and WSL2 it failed to spawn on every .ps1 buffer.
if vim.fn.has("win32") == 1 then
  table.insert(M.lsp_list, "powershell_es")
end

-- Enhanced capabilities (e.g., for nvim-cmp)
M.capabilities = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  local ok, cmp = pcall(require, "cmp_nvim_lsp")
  if ok then
    capabilities = cmp.default_capabilities(capabilities)
  end

  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = false,
  }

  return capabilities
end

-- Called when any LSP attaches to a buffer
M.on_attach = function(client, bufnr)
  -- Keymaps
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

  -- Optional: LSP formatting
  -- require("lsp-format").on_attach(client)

  -- Optional: navic
  if client.server_capabilities.documentSymbolProvider then
    local ok, navic = pcall(require, "nvim-navic")
    if ok then
      navic.attach(client, bufnr)
    end
  end
end

return M
