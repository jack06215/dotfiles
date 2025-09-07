local M = {}

-- List of all LSP servers to register
M.lsp_list = {
  "pyright",
  "lua_ls",
  "jsonls",
  "bashls",
  "gopls",
  -- Foloow https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#jsonnet_ls to use jsonnet_ls
  "jsonnet_ls",
  -- Add more as needed
  "powershell_es",
}

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
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
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
