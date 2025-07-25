return {
  "pwntester/octo.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    -- OR 'ibhagwan/fzf-lua',
    'folke/snacks.nvim',
    "nvim-tree/nvim-web-devicons",
  },
  cmd = { "Octo" },
  keys = {
    { "<Leader>or", "<Cmd>Octo search sort:updated-desc is:open is:pr user-review-requested:@me<CR>" },
    { "<Leader>op", "<Cmd>Octo search is:open is:pr author:@me<CR>" },
    { "<Leader>os", "<Cmd>Octo review start<CR>" },
  },
  config = function()
    require("octo").setup()
  end,
  setup = {
    default_merge_method = "squash",
    default_delete_branch = true,
  },
}
