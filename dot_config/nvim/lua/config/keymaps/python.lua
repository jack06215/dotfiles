local M = {}

M.create_keymaps = function()
  vim.keymap.set("n", "<leader>pym", function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      vim.notify("No file associated with current buffer", vim.log.levels.ERROR)
    else
      local rel_root = vim.fn.fnamemodify(path, ":.:r") -- relative path, no extension
      local dot_path = rel_root:gsub("/", ".")
      vim.fn.setreg("+", dot_path) -- copy to system clipboard
      vim.notify("Copied to clipboard: " .. dot_path, vim.log.levels.INFO)
    end
  end, { desc = "Copy Module Name" })
end

return M
