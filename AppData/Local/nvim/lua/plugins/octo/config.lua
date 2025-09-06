return {
  "pwntester/octo.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    -- OR 'ibhagwan/fzf-lua',
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = { "Octo" },
  keys = require("plugins.octo.keymaps"),
  config = function()
    require("octo").setup()
  end,
  opts = {
    default_merge_method = "squash",
    default_delete_branch = true,
  },
}
