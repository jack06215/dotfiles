return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({
            cwd = require("lazy.core.config").options.root,
          })
        end,
        desc = "Find Plugin File",
      },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",               desc = "Find buffers",       noremap = true },
      { "<leader>ff", "<cmd>Telescope find_files<cr>",            desc = "Find files",         noremap = true },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",             desc = "Live grep",          noremap = true },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",             desc = "Help tags",          noremap = true },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>",               desc = "Keymaps",            noremap = true },
      { "<leader>fm", "<cmd>Telescope marks<cr>",                 desc = "Marks",              noremap = true },
      { "<leader>fr", "<cmd>Telescope resume<cr>",                desc = "Resume last search", noremap = true },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>",  desc = "Document symbols",   noremap = true },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols",  noremap = true },
      { "<leader>ft", "<cmd>Telescope treesitter<cr>",            desc = "Treesitter symbols", noremap = true },
      { "<leader>fo", "<cmd>Telescope oldfiles<cr>",              desc = "Old files",          noremap = true },
      { "<leader>fC", "<cmd>Telescope commands<cr>",              desc = "Commands",           noremap = true },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },
}
