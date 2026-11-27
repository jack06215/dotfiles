local M = {}

-- <leader>C, not <leader>a: avante's default keys use the <leader>a prefix,
-- and maplocalleader is also Space, so <LocalLeader>a is the same key. <C-a>
-- stays Vim's increment.
M.create_keymaps = function()
  local map = vim.keymap.set
  local base = { noremap = true, silent = true }

  map(
    { "n", "v" },
    "<leader>Cc",
    "<cmd>CodeCompanionChat Toggle<CR>",
    vim.tbl_extend("force", base, { desc = "Toggle a chat buffer" })
  )
  map(
    { "n", "v" },
    "<leader>Cp",
    "<cmd>CodeCompanionActions<CR>",
    vim.tbl_extend("force", base, { desc = "Open the action palette" })
  )
  map(
    "v",
    "<leader>Ca",
    "<cmd>CodeCompanionChat Add<CR>",
    vim.tbl_extend("force", base, { desc = "Add code to a chat buffer" })
  )
end

return M
