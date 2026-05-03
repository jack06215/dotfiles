return {
  "s1n7ax/nvim-window-picker",
  name = "window-picker",
  event = "VeryLazy",
  version = "2.*",

  keys = {
    {
      "<leader>wp",
      function()
        local ok, picker = pcall(require, "window-picker")
        if not ok then
          return
        end

        local picked = picker.pick_window()
        if picked then
          vim.api.nvim_set_current_win(picked)
        end
      end,
      desc = "Pick window",
    },
  },

  config = function()
    require("window-picker").setup({
      hint = "floating-big-letter",

      selection_chars = "ASDFGHJKLQWERTYUIOPZXCVBNM",

      picker_config = {
        handle_mouse_click = false,

        statusline_winbar_picker = {
          use_winbar = "never",
        },

        floating_big_letter = {
          font = "ansi-shadow",
        },
      },

      show_prompt = false,
      prompt_message = "",

      filter_rules = {
        autoselect_one = true,
        include_current_win = false,
        include_unfocusable_windows = false,

        bo = {
          filetype = {
            "neo-tree",
            "neo-tree-popup",
            "notify",
            "snacks_notif",
            "noice",
            "NvimTree",
            "Trouble",
            "lazy",
          },
          buftype = {
            "terminal",
            "quickfix",
            "nofile",
            "prompt",
          },
        },
      },

      highlights = {
        enabled = true,
        floating_big_letter = {
          fg = "#ffffff",
          bg = "#000000",
          bold = true,
        },
      },
    })
  end,
}
