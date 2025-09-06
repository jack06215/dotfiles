local M = {}

M.create_keymaps = function()
  vim.keymap.del("n", "<leader>gG")
end

return M
