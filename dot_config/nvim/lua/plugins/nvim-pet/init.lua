return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/vendor/pets.nvim",
    name = "pets.nvim",
    lazy = false,
    dependencies = {
      "edluffy/hologram.nvim",
    },
    config = function()
      local pets = require("pets")
      require("pets").setup({
        row = 1,
        col = 10,
        speed_multiplier = 1,
        default_pet = "dog",
        default_style = "brown",
        random = false,
        death_animation = true,
        popup = {
          width = "30%",
          winblend = 100,
          hl = {
            Normal = "Normal",
          },
          avoid_statusline = false,
        },
      })
      pets.create_pet("doge", "dog", "brown")
    end,
  },
}
