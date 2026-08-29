return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function(_, opts)
      require("todo-comments").setup(opts)
      require("telescope").load_extension("todo-comments")
    end,
    cmd = { "TodoTrouble", "TodoTelescope", "TodoQuickFix" },
    -- Keymaps live in config/keymaps/todo-comments.lua: all three collide with
    -- a LazyVim default that which-key now binds. `cmd` above (plus the
    -- LazyFile event from LazyVim's own spec) still lazy-loads this.
  },
}
