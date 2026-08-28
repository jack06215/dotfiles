local M = {}

M.create_keymaps = function()
  -- <C-j> is the SKK convention. LazyVim binds it in normal mode for window
  -- navigation, but insert and cmdline are free, and those are the only two
  -- modes skkeleton has anything to say in.
  vim.keymap.set({ "i", "c" }, "<C-j>", "<Plug>(skkeleton-toggle)", { desc = "Toggle SKK Japanese input" })
end

return M
