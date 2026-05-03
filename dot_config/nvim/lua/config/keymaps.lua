-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>w>", function()
  local win = vim.api.nvim_get_current_win()
  local width = vim.api.nvim_win_get_width(win)
  vim.api.nvim_win_set_width(win, width + 20)
end, { desc = "Increase window width" })

vim.keymap.set("n", "<leader>w<", function()
  local win = vim.api.nvim_get_current_win()
  local width = vim.api.nvim_win_get_width(win)
  vim.api.nvim_win_set_width(win, width - 10)
end, { desc = "Increase window width" })

vim.keymap.set("n", "<leader>w+", function()
  local win = vim.api.nvim_get_current_win()
  local height = vim.api.nvim_win_get_height(win)
  vim.api.nvim_win_set_height(win, height + 10)
end, { desc = "Increase window width" })

require("config.keymaps.general").create_keymaps()
require("config.keymaps.buffer").create_keymaps()
require("config.keymaps.bufferline").create_keymaps()

-- Language specific
require("config.keymaps.python").create_keymaps()
require("config.keymaps.typescript").create_keymaps()

-- Plugins
require("config.keymaps.lazyvim").create_keymaps()
require("config.keymaps.neogit").create_keymaps()
-- require("config.keymaps.codecompanion").create_keymaps()
require("config.keymaps.package-info").create_keymaps()
require("config.keymaps.nvim-lint").create_keymaps()
require("config.keymaps.nvim-window-picker").create_keymaps()
