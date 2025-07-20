return {
  "folke/noice.nvim",
  cond = not vim.g.started_by_firenvim,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("noice").setup({})
  end,
}
