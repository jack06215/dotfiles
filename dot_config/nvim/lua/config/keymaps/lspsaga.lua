local M = {}

-- Moved here from plugins/lspsage/keymaps.lua, for the same reason as
-- config/keymaps/telescope.lua: each of these collides with a LazyVim default
-- that which-key now binds, and which-key applies its spec after lazy.nvim's
-- key stubs.
--
-- lspsaga declares no `cmd`, so the `Lspsaga` command does not exist until the
-- plugin loads. Loading it explicitly here keeps lspsaga lazy -- its spec is
-- pinned to lazy = true in plugins/lspsage/config.lua now that it has no `keys`
-- of its own left to trigger on.
local function saga(subcommand)
  return function()
    require("lazy").load({ plugins = { "lspsaga.nvim" } })
    vim.cmd("Lspsaga " .. subcommand)
  end
end

M.create_keymaps = function()
  local map = vim.keymap.set

  map("n", "<leader>ca", saga("code_action"), { desc = "Code Action" })
  map("n", "<leader>cd", saga("show_line_diagnostics"), { desc = "Line Diagnostics" })
  map("n", "<leader>cf", saga("lsp_finder"), { desc = "LSP Finder" })
  map("n", "<leader>cr", saga("rename"), { desc = "Rename" })
  map("n", "<leader>cs", saga("signature_help"), { desc = "Signature Help" })
end

return M
