local M = {}

M.create_keymaps = function()
  vim.keymap.set("n", "<leader>ul", function()
    vim.opt.relativenumber = not vim.opt.relativenumber:get()
  end, { desc = "Toggle Relative Line Numbers" })

  vim.keymap.set("n", "<leader>fp", function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      vim.notify("No file path", vim.log.levels.WARN)
    else
      local rel_path = vim.fn.fnamemodify(path, ":.p")
      vim.fn.setreg("+", rel_path) -- Copy to system clipboard
      print("Copied: " .. rel_path)
    end
  end, { desc = "Copy Relative Path to Clipboard" })
end

return M
