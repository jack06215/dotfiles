local M = {}

---Copy the dotted module name of a file, `pkg/mod/file.py` -> `pkg.mod.file`.
---@param rel_path? string path relative to the project root; defaults to the
---current buffer relative to cwd. config/keymaps/vscode.lua passes its own,
---since nvim's cwd means nothing under vscode-neovim.
M.copy_module_name = function(rel_path)
  if not rel_path then
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      vim.notify("No file associated with current buffer", vim.log.levels.ERROR)
      return
    end
    rel_path = vim.fn.fnamemodify(path, ":.")
  end

  local dot_path = vim.fn.fnamemodify(rel_path, ":r"):gsub("/", ".") -- no extension
  vim.fn.setreg("+", dot_path) -- copy to system clipboard
  vim.notify("Copied to clipboard: " .. dot_path, vim.log.levels.INFO)
end

M.create_keymaps = function()
  vim.keymap.set("n", "<leader>pym", function()
    M.copy_module_name()
  end, { desc = "Copy Module Name" })
end

return M
