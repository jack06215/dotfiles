return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = function()
    return {
      jump = {
        jumplist = true,
      },
      label = {
        uppercase = false,
        rainbow = { enabled = true },
      },
      modes = {
        search = { enabled = false },
        char = { enabled = false },
      },
    }
  end,
  keys = require("plugins.flash.keymaps"),
}
