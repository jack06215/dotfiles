return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opt = { log_level = "warn" },
    config = function()
      local events = require("neo-tree.events")

      require("neo-tree").setup({
        sources = { "filesystem" },
        filesystem = {
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_gitignored = false,
          },
          follow_current_file = {
            enabled = false,
          },
        },
        git_status = {
          enabled = false, -- 🔥 biggest speedup
        },
        -- neo-tree forces nonumber/norelativenumber on its own window on
        -- every buffer enter; re-enable them right after so the tree gets
        -- the same hybrid number/relativenumber style as the main editor
        event_handlers = {
          {
            event = events.NEO_TREE_BUFFER_ENTER,
            handler = function()
              vim.wo.number = true
              vim.wo.relativenumber = true
            end,
          },
        },
      })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim", -- makes sure that this loads after Neo-tree.
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          -- filter using buffer options
          bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            -- if the buffer type is one of following, the window will be ignored
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
}
