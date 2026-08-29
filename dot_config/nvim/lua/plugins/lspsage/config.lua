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
    -- Keymaps live in config/keymaps/lspsaga.lua: all five collide with a
    -- LazyVim default that which-key now binds, so they have to be applied
    -- after which-key's spec rather than as lazy `keys`. With no `keys` left,
    -- lazy = true has to be explicit -- lua/config/lazy.lua sets
    -- defaults.lazy = false, which would otherwise make this load at startup.
    lazy = true,
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
