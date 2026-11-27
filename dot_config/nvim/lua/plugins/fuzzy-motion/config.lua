return {
  "yuki-yano/fuzzy-motion.vim",
  cmd = { "FuzzyMotion" },
  keys = require("plugins.fuzzy-motion.keymaps").keys,
  dependencies = {
    "vim-denops/denops.vim",
    "lambdalisue/vim-kensaku",
  },
  init = function()
    vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
  end,
}
