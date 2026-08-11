return {
  "folke/flash.nvim",
  event = "VeryLazy",

  -- kensaku turns romaji into a Japanese-matching regex; denops is its runtime.
  -- Listed here (not just under fuzzy-motion) so the Deno process is already up
  -- by the time you hit `s` -- otherwise the first search blocks on the boot.
  dependencies = {
    "vim-denops/denops.vim",
    "lambdalisue/vim-kensaku",
  },

  opts = function()
    return {
      search = {
        -- type romaji, match kana/kanji. Falls back to exact match when
        -- kensaku is unavailable, so this is safe to leave always on.
        mode = require("plugins.flash.kensaku").mode,
      },
      jump = {
        jumplist = true,
      },
      label = {
        uppercase = false,
        rainbow = { enabled = true },
      },
      modes = {
        search = { enabled = false },
        char = { enabled = false },
      },
    }
  end,
  keys = require("plugins.flash.keymaps"),
}
