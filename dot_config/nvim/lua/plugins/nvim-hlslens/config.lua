return {
  "kevinhwang91/nvim-hlslens",

  -- Loaded on VeryLazy rather than on `keys`. Two reasons:
  --
  -- 1. `auto_enable` works by hooking CmdlineEnter/CmdlineLeave, so the plugin
  --    has to already be loaded when you press `/` -- a `keys = { "/" }` stub
  --    would only load it *after* the cmdline had opened.
  -- 2. The n/N mappings override LazyVim defaults, so they live in
  --    config/keymaps/nvim-hlslens.lua instead of a `keys` block here. See the
  --    header there for why.
  event = "VeryLazy",

  opts = {
    -- `/` and `?` start the lens on their own; n/N/*/# call `start()` from
    -- config/keymaps/nvim-hlslens.lua.
    auto_enable = true,

    -- Live "3/12" while typing the pattern, before <CR>. See README for how
    -- this reads during a romaji search (kensaku converts on <CR>, so the
    -- count lags until then).
    enable_incsearch = true,

    -- Leave the highlight up until <leader>ur clears it (LazyVim's "Redraw /
    -- Clear hlsearch"; <C-l> is window-nav in this config, not :nohlsearch).
    -- Flip to true to have it drop by itself as soon as the cursor leaves a
    -- match.
    calm_down = false,

    -- Lens on every visible match, not only the one under the cursor.
    nearest_only = false,

    -- Float the nearest lens only when the virtual text would be pushed past
    -- the right edge of the window.
    nearest_float_when = "auto",
  },
}
