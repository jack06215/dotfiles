return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function(_, opts)
      require("todo-comments").setup(opts)
      require("telescope").load_extension("todo-comments")
    end,
    cmd = { "TodoTrouble", "TodoTelescope", "TodoQuickFix" },
    -- Keymaps have been moved to a separate file
    keys = require("plugins.todo-comments.keymaps"),
  },
}
