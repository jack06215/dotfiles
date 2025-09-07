return {
  {
    "nvimdev/lspsaga.nvim",
    config = function()
      require("lspsaga").setup({})
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    -- Keymaps have been moved to a separate file
    keys = require("plugins.lspsage.keymaps"),
    opts = {
      lightbulb = {
        enable = false, -- Disable the lightbulb feature
      },
      ui = {
        border = "rounded", -- Use rounded borders for the UI
      },
      symbol_in_winbar = {
        enable = false, -- Disable symbol in winbar
      },
    },
  },
}
