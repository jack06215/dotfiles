-- <leader>ff, fb, fg, fr and ft moved to config/keymaps/telescope.lua: each
-- collides with a LazyVim default that plugins/which-key/lazyvim-defaults.lua
-- now binds, and a lazy `keys` entry would be clobbered by which-key's spec.
--
-- NOTE: <leader>fp below is dead -- config/keymaps/general.lua binds it to
-- "Copy Relative Path to Clipboard" and runs later. It predates this change.
return {
  {
    "<leader>fp",
    function()
      require("telescope.builtin").find_files({
        cwd = require("lazy.core.config").options.root,
      })
    end,
    desc = "Find Plugin File",
  },
  { "<leader>fh", "<cmd>Telescope help_tags<cr>",             desc = "Help tags",          noremap = true },
  { "<leader>fk", "<cmd>Telescope keymaps<cr>",               desc = "Keymaps",            noremap = true },
  { "<leader>fm", "<cmd>Telescope marks<cr>",                 desc = "Marks",              noremap = true },
  { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>",  desc = "Document symbols",   noremap = true },
  { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols",  noremap = true },
  { "<leader>fo", "<cmd>Telescope oldfiles<cr>",              desc = "Old files",          noremap = true },
  { "<leader>fC", "<cmd>Telescope commands<cr>",              desc = "Commands",           noremap = true },
}

