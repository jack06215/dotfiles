--- Main module entry for Comment.nvim plugin configuration.
--- This module integrates utility functions, key mappings, and the plugin setup.

local U = require("plugins.comment.utils")
local Keymaps = require("plugins.comment.keymaps")
local Config = require("plugins.comment.config")

return {
  "numToStr/Comment.nvim",
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  keys = Keymaps.get_keymaps(), -- Load key mappings.
  config = Config.setup, -- Setup plugin configuration.
}

