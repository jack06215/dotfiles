local M = {}

-- Moved here from plugins/telescope/keymaps.lua. These five collide with a
-- LazyVim default that plugins/which-key/lazyvim-defaults.lua now binds, and
-- which-key applies that spec after lazy.nvim has installed its key stubs -- so
-- a lazy `keys` entry would be silently clobbered. Applied from config/keymaps
-- instead, which runs last.
--
-- Telescope is lazy = true with `keys` as its only load trigger, so these go
-- through require("telescope.builtin") rather than <cmd>Telescope ...<cr>:
-- lazy.nvim's require hook loads the plugin on first press, and the `Telescope`
-- command does not exist until it has. The non-colliding telescope keys stay in
-- plugins/telescope/keymaps.lua.
local function builtin(name, opts)
  return function()
    require("telescope.builtin")[name](opts)
  end
end

M.create_keymaps = function()
  local map = vim.keymap.set

  map("n", "<leader>ff", builtin("find_files"), { desc = "Find files" })
  map("n", "<leader>fb", builtin("buffers"), { desc = "Find buffers" })
  map("n", "<leader>fg", builtin("live_grep"), { desc = "Live grep" })
  map("n", "<leader>fr", builtin("resume"), { desc = "Resume last search" })
  map("n", "<leader>ft", builtin("treesitter"), { desc = "Treesitter symbols" })
end

return M
