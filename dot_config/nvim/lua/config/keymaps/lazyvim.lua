local M = {}

local function safe_del(mode, lhs)
  pcall(vim.keymap.del, mode, lhs)
end

M.create_keymaps = function()
  -- LazyVim defaults to drop. Only list keys LazyVim actually sets, otherwise
  -- the safe_del is a silent no-op that reads like it is doing something.
  local keys = {
    "<leader>K",
    "<leader>l",
    "<leader>E", -- neo-tree extra's alias for <leader>fE
    "<leader>fe",
    "<leader>fE",
  }

  for _, key in ipairs(keys) do
    safe_del("n", key)
  end
end

return M
