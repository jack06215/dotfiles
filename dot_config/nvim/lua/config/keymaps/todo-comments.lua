local M = {}

-- Moved here from plugins/todo-comments/keymaps.lua. Same collision story as
-- config/keymaps/telescope.lua.
--
-- todo-comments declares `cmd = { "TodoTrouble", "TodoTelescope", "TodoQuickFix" }`
-- and LazyVim's own spec adds a LazyFile event, so plain <cmd>...<cr> keeps it
-- lazy -- no explicit load needed here.
M.create_keymaps = function()
  local map = vim.keymap.set

  map("n", "<leader>xt", "<cmd>TodoTrouble<cr>", { desc = "Todo (Trouble)" })
  map("n", "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", { desc = "Todo/Fix/Fixme (Trouble)" })
  map("n", "<leader>st", "<cmd>TodoTelescope<cr>", { desc = "Todo (Telescope)" })
end

return M
