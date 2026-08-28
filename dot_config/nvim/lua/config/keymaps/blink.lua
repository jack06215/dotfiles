local M = {}

local jisyo = (vim.env.XDG_DATA_HOME or vim.fn.expand("~/.local/share")) .. "/dict-ja/skk.txt"

-- Japanese romaji completion is off by default (see lua/plugins/blink/config.lua
-- for why), so it needs a way back on. Bound in both normal and insert mode
-- because the decision is usually made mid sentence, where leaving insert to
-- flip it would defeat the point.
local function toggle()
  -- blink is lazy-loaded on InsertEnter, and until it loads, its dependencies
  -- are not on the runtimepath and the `im.setup()` in its opts has not run --
  -- so in normal mode this has to pull it in first, or the require below fails
  -- on a plugin that is in fact installed.
  pcall(function()
    require("lazy").load({ plugins = { "blink.cmp" } })
  end)

  local ok, im = pcall(require, "blink_cmp_im")
  if not ok then
    vim.notify("blink-cmp-im not available -- run `:Lazy sync`", vim.log.levels.ERROR)
    return
  end

  -- The provider is only registered when the generated table exists, so
  -- without it the toggle would flip a flag that nothing reads.
  if vim.fn.filereadable(jisyo) == 0 then
    vim.notify("No jisyo at " .. jisyo .. " -- run `chezmoi apply`", vim.log.levels.WARN)
    return
  end

  vim.notify(string.format("Japanese IM %s", im.toggle() and "enabled" or "disabled"))
end

M.create_keymaps = function()
  -- `<leader>u` is LazyVim's toggle namespace, so this shows up in which-key
  -- alongside spell, wrap and the rest.
  vim.keymap.set("n", "<leader>uj", toggle, { desc = "Toggle Japanese IM completion" })
  vim.keymap.set("i", "<M-j>", toggle, { desc = "Toggle Japanese IM completion" })
end

return M
