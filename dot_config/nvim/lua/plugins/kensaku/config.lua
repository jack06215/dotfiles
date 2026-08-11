return {
  "lambdalisue/kensaku-search.vim",

  -- kensaku turns romaji into a Japanese-matching regex; denops is its runtime.
  -- Same pair flash and fuzzy-motion depend on -- lazy.nvim dedupes them.
  dependencies = {
    "vim-denops/denops.vim",
    "lambdalisue/vim-kensaku",
  },

  -- Not lazy-loaded on `keys`: the mapping lives in cmdline mode, where feeding
  -- the key back after a load is unreliable, and it needs `<Plug>` to already
  -- exist. The plugin is ~10 lines of Vim script, so loading it up front costs
  -- nothing.
  config = function()
    require("plugins.kensaku.keymaps").create_keymaps()
    require("plugins.kensaku.preview").setup()
  end,
}
