return {
  "yuki-yano/fuzzy-motion.vim",
  cmd = { "FuzzyMotion" },
  -- keys moved to keymaps.lua
  dependencies = {
    "vim-denops/denops.vim",
    "lambdalisue/vim-kensaku",
  },
  init = function()
    vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
  end,
}
