-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
require("config.keymaps.general").create_keymaps()
require("config.keymaps.buffer").create_keymaps()
require("config.keymaps.bufferline").create_keymaps()

-- Language specific
require("config.keymaps.python").create_keymaps()

-- Plugins
require("config.keymaps.lazyvim").create_keymaps()
require("config.keymaps.neogit").create_keymaps()
-- require("config.keymaps.codecompanion").create_keymaps()
require("config.keymaps.package-info").create_keymaps()
