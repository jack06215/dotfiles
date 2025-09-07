local M = {}

M.create_keymaps = function()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function()
      local pkg = require("package-info")
      local map = vim.keymap.set
      local opts = { noremap = true, silent = true, buffer = true }

      map("n", "<leader>pjs", pkg.show, vim.tbl_extend("force", opts, { desc = "Show package versions" }))
      -- map("n", "<leader>pjc", pkg.hide, vim.tbl_extend("force", opts, { desc = "Clear package versions" }))
      map("n", "<leader>pju", pkg.update, vim.tbl_extend("force", opts, { desc = "Update dependency" }))
      map("n", "<leader>pjd", pkg.delete, vim.tbl_extend("force", opts, { desc = "Delete dependency" }))
      map("n", "<leader>pji", pkg.install, vim.tbl_extend("force", opts, { desc = "Install dependency" }))
      map("n", "<leader>pjc", pkg.change_version, vim.tbl_extend("force", opts, { desc = "Change dependency version" }))
    end,
  })
end

return M
