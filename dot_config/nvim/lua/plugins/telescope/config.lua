return {
  {
    "nvim-telescope/telescope.nvim",
    keys = require("plugins.telescope.keymaps"),
    opts = function()
      return {
        defaults = {
          layout_strategy = "horizontal",
          layout_config = { prompt_position = "top" },
          sorting_strategy = "ascending",
          winblend = 0,
        },
      }
    end,
  },
}
