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
    keys = {
      { "<leader>ca", "<cmd>Lspsaga code_action<cr>",           desc = "Code Action" },
      { "<leader>cd", "<cmd>Lspsaga show_line_diagnostics<cr>", desc = "Line Diagnostics" },
      { "<leader>cf", "<cmd>Lspsaga lsp_finder<cr>",            desc = "LSP Finder" },
      { "<leader>cr", "<cmd>Lspsaga rename<cr>",                desc = "Rename" },
      { "<leader>cs", "<cmd>Lspsaga signature_help<cr>",        desc = "Signature Help" },
      { "gh",         "<cmd>Lspsaga peek_definition<cr>",       desc = "Peek Definition" },
      { "gd",         "<cmd>Lspsaga goto_definition<cr>",       desc = "Goto Definition" },
    },
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
