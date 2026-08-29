-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- This file is the override layer. plugins/which-key/lazyvim-defaults.lua holds
-- the complete stock LazyVim baseline as which-key spec entries, and which-key
-- applies that spec from a vim.schedule'd callback after VeryLazy -- which is
-- after this file would normally run. So everything below is deferred until
-- which-key has applied its spec; otherwise the baseline would land last and
-- clobber these instead of the other way round.

---Run `fn` once which-key has applied its spec.
---which-key schedules that work, so we hop the scheduler until it reports
---loaded. Bounded so a disabled or failed which-key still gets us our keymaps.
---@param fn fun()
---@param tries? integer
local function after_which_key(fn, tries)
  tries = tries or 20
  local wk = package.loaded["which-key.config"]
  if (wk and wk.loaded) or tries <= 0 then
    return fn()
  end
  vim.schedule(function()
    after_which_key(fn, tries - 1)
  end)
end

local function apply_keymaps()
  -- Window resize
  vim.keymap.set("n", "<leader>w>", function()
    local win = vim.api.nvim_get_current_win()
    local width = vim.api.nvim_win_get_width(win)
    vim.api.nvim_win_set_width(win, width + 20)
  end, { desc = "Increase window width" })

  vim.keymap.set("n", "<leader>w<", function()
    local win = vim.api.nvim_get_current_win()
    local width = vim.api.nvim_win_get_width(win)
    vim.api.nvim_win_set_width(win, width - 10)
  end, { desc = "Increase window width" })

  vim.keymap.set("n", "<leader>w+", function()
    local win = vim.api.nvim_get_current_win()
    local height = vim.api.nvim_win_get_height(win)
    vim.api.nvim_win_set_height(win, height + 10)
  end, { desc = "Increase window width" })

  require("config.keymaps.general").create_keymaps()
  require("config.keymaps.buffer").create_keymaps()
  require("config.keymaps.bufferline").create_keymaps()

  -- Language specific
  require("config.keymaps.python").create_keymaps()
  require("config.keymaps.typescript").create_keymaps()

  -- Plugins
  require("config.keymaps.blink").create_keymaps()
  require("config.keymaps.lazyvim").create_keymaps()
  require("config.keymaps.neogit").create_keymaps()
  require("config.keymaps.octo").create_keymaps()
  -- require("config.keymaps.codecompanion").create_keymaps()
  require("config.keymaps.package-info").create_keymaps()
  require("config.keymaps.nvim-lint").create_keymaps()
  require("config.keymaps.nvim-window-picker").create_keymaps()

  -- Overrides of LazyVim defaults that used to live in plugin `keys` blocks.
  -- Moved here so they land after which-key applies the baseline spec.
  require("config.keymaps.telescope").create_keymaps()
  require("config.keymaps.lspsaga").create_keymaps()
  require("config.keymaps.todo-comments").create_keymaps()
end

after_which_key(apply_keymaps)
