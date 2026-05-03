local M = {}

local function safe_del(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

M.create_keymaps = function()
  local keys = {
    "<leader>gG",
    "<leader>K",
    "<leader>l",
    "<leader>ll",
    "<leader>lL",
    "<leader>li",
    "<leader>lR",
    "<leader>lS",
  }

  for _, key in ipairs(keys) do
    safe_del("n", key)
  end
end

return M
