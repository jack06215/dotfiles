return {
  "folke/noice.nvim",
  cond = function()
    return not vim.g.vscode
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("noice").setup({
      routes = {
        {
          filter = {
            event = "lsp",
            kind = "progress",
            cond = function(message)
              local client = vim.tbl_get(message.opts, "progress", "client")
              return client == "pyright"
            end,
          },
          opts = { skip = true },
        },
      },
    })
  end,
}
