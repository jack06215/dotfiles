local M = {}

function M.create_keymaps()
  -- Try to load nvim-lint; if it's not installed, just skip without error
  local ok, lint = pcall(require, "lint")
  if not ok then
    -- silently skip setting keymaps if nvim-lint is not available
    return
  end

  local map = vim.keymap.set
  local opts = { silent = true, noremap = true }

  -- Example keymaps – adjust to your liking
  map("n", "<leader>ll", function()
    lint.try_lint()
  end, vim.tbl_extend("force", opts, { desc = "Lint current file" }))

  map("n", "<leader>lL", function()
    -- Re-run lint explicitly
    lint.try_lint()
  end, vim.tbl_extend("force", opts, { desc = "Re-run lint" }))
end

return M
