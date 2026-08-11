local M = {}

M.create_keymaps = function()
  -- Both halves of `<CR>` are no-ops unless the line is a romaji search:
  -- `expand_ex()` returns immediately unless the cmdline type is `:` and the
  -- command is `:s` / `:g` / `:v`, and `<Plug>(kensaku-search-replace)` unless
  -- it is `/` or `?`. The trailing `<CR>` then runs whatever is on the line.
  vim.keymap.set(
    "c",
    "<CR>",
    "<Cmd>lua require('plugins.kensaku.cmdline').expand_ex()<CR><Plug>(kensaku-search-replace)<CR>",
    { desc = "Execute command line (romaji -> Japanese)" }
  )

  -- For the pattern-taking commands `<CR>` deliberately skips -- `:vimgrep`,
  -- `:helpgrep`, plugin commands.
  vim.keymap.set("c", "<C-x>", function()
    require("plugins.kensaku.cmdline").expand()
  end, { desc = "Expand romaji to Japanese pattern" })
end

return M
