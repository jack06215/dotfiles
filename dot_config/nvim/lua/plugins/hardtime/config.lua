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

      -- don't camp in insert mode: bounce back to normal after 10s idle
      force_exit_insert_mode = true,
      max_insert_idle_ms = 10000,

      -- punish low-value habits
      -- NOTE: arrow keys are already fully blocked by hardtime's default
      -- `disabled_keys`, so they don't need an entry here.
      restricted_keys = {
        ["h"] = { "n", "x" },
        ["j"] = { "n", "x" },
        ["k"] = { "n", "x" },
        ["l"] = { "n", "x" },

        ["+"] = { "n" },
        ["-"] = { "n" },

        ["gj"] = { "n" },
        ["gk"] = { "n" },

        -- Phase 2: uncomment to force f/t/flash over word-walking.
        -- Only turn these on once f/t/s are automatic.
        -- ["w"] = { "n", "x" },
        -- ["b"] = { "n", "x" },
        -- ["e"] = { "n", "x" },
        -- ["x"] = { "n" },
      },

      -- extra hints on top of hardtime's defaults
      hints = {
        ["0i"] = { -- default config only covers ^i
          message = function()
            return "Use I instead of 0i"
          end,
          length = 2,
        },
        ["xi"] = {
          message = function()
            return "Use s instead of xi"
          end,
          length = 2,
        },
        ["ggVG"] = {
          message = function()
            return "Use the ag text object (yag/dag/=ag)"
          end,
          length = 4,
        },
        ["gg=G"] = {
          message = function()
            return "Use =ag instead of gg=G"
          end,
          length = 4,
        },
        ["v[ia]%a[dcy]"] = { -- viwd, vipy, vifc ...
          message = function(keys)
            return "Use " .. keys:sub(4, 4) .. keys:sub(2, 3) .. " instead of " .. keys
          end,
          length = 4,
        },
        ["v[ia]%p[dcy]"] = { -- vi"d, va(y ...
          message = function(keys)
            return "Use " .. keys:sub(4, 4) .. keys:sub(2, 3) .. " instead of " .. keys
          end,
          length = 4,
        },
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

      -- NOTE: hardtime has no `disabled_buftypes` option -- terminal buftypes
      -- are handled internally, and `prompt` is covered by disabled_filetypes.

      callback = function(text)
        vim.notify("󰌌 Hardtime: " .. text, vim.log.levels.WARN)
      end,
    },
  },
}
