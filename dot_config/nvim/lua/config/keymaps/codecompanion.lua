local M = {}

M.create_keymaps = function()
  local map = vim.keymap.set
  local base = { noremap = true, silent = true }

  map(
    { "n", "v" },
    "<C-a>",
    "<cmd>CodeCompanionActions<CR>",
    vim.tbl_extend("force", base, { desc = "Open the action palette" })
  )

  map(
    { "n", "v" },
    "<Leader>a",
    "<cmd>CodeCompanionChat Toggle<CR>",
    vim.tbl_extend("force", base, { desc = "Toggle a chat buffer" })
  )

  map(
    "v",
    "<LocalLeader>a",
    "<cmd>CodeCompanionChat Add<CR>",
    vim.tbl_extend("force", base, { desc = "Add code to a chat buffer" })
  )
end

return M
