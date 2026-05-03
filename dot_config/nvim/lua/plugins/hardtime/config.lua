return {
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    enabled = true,

    dependencies = {
      "MunifTanjim/nui.nvim",
    },

    opts = {
      disable_mouse = true,

      -- strict mode
      allow_different_key = false,

      max_time = 800,
      max_count = 3,

      hint = true,
      notification = true,

      -- punish low-value habits
      restricted_keys = {
        ["h"] = { "n", "x" },
        ["j"] = { "n", "x" },
        ["k"] = { "n", "x" },
        ["l"] = { "n", "x" },

        ["+"] = { "n" },
        ["-"] = { "n" },

        ["gj"] = { "n" },
        ["gk"] = { "n" },

        ["<Up>"] = { "n", "x", "i" },
        ["<Down>"] = { "n", "x", "i" },
        ["<Left>"] = { "n", "x", "i" },
        ["<Right>"] = { "n", "x", "i" },
      },

      disabled_filetypes = {
        "neo-tree",
        "NvimTree",
        "lazy",
        "mason",
        "qf",
        "help",
        "checkhealth",
        "noice",
        "notify",
        "Trouble",
        "DiffviewFiles",
        "DiffviewFileHistory",
        "NeogitStatus",
        "dapui_scopes",
        "dapui_breakpoints",
        "dapui_stacks",
        "dapui_watches",
      },

      disabled_buftypes = {
        "nofile",
        "prompt",
        "terminal",
      },

      callback = function(text)
        vim.notify("󰌌 Hardtime: " .. text, vim.log.levels.WARN)
      end,
    },
  },
}
