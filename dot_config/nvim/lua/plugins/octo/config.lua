return {
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    -- OR 'ibhagwan/fzf-lua',
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = { "Octo" },
  opts = {
    default_merge_method = "squash",
    default_delete_branch = true,
  },
}
