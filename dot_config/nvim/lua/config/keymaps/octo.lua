local M = {}

M.create_keymaps = function()
  local map = vim.keymap.set

  map(
    "n",
    "<Leader>or",
    "<Cmd>Octo search sort:updated-desc is:open is:pr user-review-requested:@me<CR>",
    { desc = "Octo: PRs Requesting My Review" }
  )
  map("n", "<Leader>op", "<Cmd>Octo search is:open is:pr author:@me<CR>", { desc = "Octo: My Open PRs" })
  map("n", "<Leader>os", "<Cmd>Octo review start<CR>", { desc = "Octo: Start Review" })
end

return M
