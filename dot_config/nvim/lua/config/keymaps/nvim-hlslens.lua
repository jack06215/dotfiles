local M = {}

-- n/N collide with a LazyVim default, so they land here rather than in a
-- plugins/nvim-hlslens `keys` block -- lazy.nvim installs `keys` stubs before
-- which-key applies the baseline spec, and the baseline would win. Same
-- collision story as config/keymaps/telescope.lua.
--
-- What has to survive the wrapping:
--
--   * LazyVim binds n/N to `'Nn'[v:searchforward].'zv'` -- vim-galore's "saner
--     n/N". `v:searchforward` is 1 after `/` and 0 after `?`, so indexing that
--     pair keeps `n` meaning "down the buffer" even when the last search ran
--     backwards, and `zv` opens a fold the match landed inside.
--   * hlslens wants `start()` called after the motion, to (re)attach the lens.
--
-- hlslens's README snippet is `<Cmd>execute('normal! ' . v:count1 . 'n')<CR>`,
-- which would throw both of those away. So these stay expr mappings that
-- return LazyVim's own expression with the `start()` call appended.

--- Wrap a Vim expression in a Lua `expr` rhs that also restarts hlslens.
---
--- The `<Cmd>` must be appended in Lua, not inside the Vim expression. When the
--- rhs of an `expr` mapping is a Vimscript string, a "<Cmd>...<CR>" in its
--- result is dropped: ordinary keycodes such as <Esc> are still translated, but
--- the command never runs, silently. Returning the identical string from a Lua
--- function does work -- so `vim.fn.eval` computes LazyVim's expression and Lua
--- concatenates the hook. A typed count (`3n`) still applies to the motion.
---
--- The symptom of getting this wrong is subtle, because `auto_enable` hides it:
--- `/foo` lights up the lens from the cmdline hooks, `<Esc>` (LazyVim's
--- `:noh`) stops the renderer, and from then on n/N move the cursor with the
--- match highlighted but no lens, because `start()` was never called.
---
--- `require` sits inside <Cmd> so this file never forces hlslens to load;
--- VeryLazy has already done that before a key can be pressed anyway.
---@param expr string Vim expression producing the motion key(s)
---@return fun(): string
local function with_lens(expr)
  return function()
    return vim.fn.eval(expr) .. "<Cmd>lua require('hlslens').start()<CR>"
  end
end

M.create_keymaps = function()
  local map = vim.keymap.set

  -- Normal mode keeps `zv`; visual mode does not, matching LazyVim. Operator
  -- pending (`dn`, `cN`) is deliberately left on the LazyVim mapping: the
  -- trailing <Cmd> would run after the operator had already consumed the
  -- motion, and a lens is not worth the risk of an odd edit.
  local next_key = "'Nn'[v:searchforward]"
  local prev_key = "'nN'[v:searchforward]"

  map("n", "n", with_lens(next_key .. " . 'zv'"), { expr = true, desc = "Next Search Result" })
  map("n", "N", with_lens(prev_key .. " . 'zv'"), { expr = true, desc = "Prev Search Result" })
  map("x", "n", with_lens(next_key), { expr = true, desc = "Next Search Result" })
  map("x", "N", with_lens(prev_key), { expr = true, desc = "Prev Search Result" })

  -- Unbound by LazyVim, so these are plain (non-expr) wrappers. `*` and `#`
  -- are search commands, so 'foldopen' already contains "search" and no `zv`
  -- is needed.
  local start_cmd = "<Cmd>lua require('hlslens').start()<CR>"
  for _, key in ipairs({ "*", "#", "g*", "g#" }) do
    map("n", key, key .. start_cmd, { desc = "Search Word Under Cursor" })
  end

  -- <leader>uh is LazyVim's inlay hints toggle; uppercase H is free.
  map("n", "<leader>uH", "<Cmd>HlSearchLensToggle<CR>", { desc = "Toggle Search Lens" })

  -- Every match of the last search into the quickfix list, which then feeds
  -- the existing <leader>x workflow (<leader>xq to open, ]q / [q to walk it).
  map("n", "<leader>xs", function()
    require("hlslens").exportLastSearchToQuickfix()
  end, { desc = "Search Matches to Quickfix" })
end

return M
