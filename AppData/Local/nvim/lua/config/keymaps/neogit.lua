local M = {}

M.create_keymaps = function()
  vim.keymap.set("n", "<leader>gg", function()
    require("neogit").open()
  end, { desc = "Open Neogit" })
end

return M
