local M = {}

M.create_keymaps = function(bufnr)
  local has_exec = false
  for _, client in ipairs(vim.lsp.get_clients(bufnr)) do
    if client.server_capabilities.executeCommandProvider then
      has_exec = true
      break
    end
  end

  if not has_exec then
    return
  end

  -- Organize Imports
  vim.keymap.set("n", "<leader>co", "<cmd>TSToolsOrganizeImports<CR>", {
    desc = "Organize Imports",
    buffer = bufnr,
  })

  -- Rename File
  vim.keymap.set("n", "<leader>cR", "<cmd>TSToolsRenameFile<CR>", {
    desc = "Rename File",
    buffer = bufnr,
  })
end

return M
