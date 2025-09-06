return {
  "NeogitOrg/neogit",
  lazy = false,
  -- cmd = { "Neogit" },
  -- keys = {
  --   {
  --     "<leader>gg",
  --     function() require("neogit").open() end,
  --     desc = "Open Neogit",
  --   },
  -- },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("neogit").setup({
      integrations = {
        diffview = true,
        telescope = true,
      },
    })
  end,
}
