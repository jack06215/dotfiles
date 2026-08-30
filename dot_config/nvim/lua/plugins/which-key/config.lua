-- which-key.nvim declares `opts_extend = { "spec" }` upstream, so this list is
-- appended to LazyVim's own spec instead of replacing it.
--
-- `lazyvim-defaults` holds every LazyVim v16 <leader> mapping re-declared as a
-- spec entry, so a default can be rebound or removed there rather than hunted
-- down in the LazyVim source. See the legend at the top of that file.
local lazyvim_defaults = require("plugins.which-key.lazyvim-defaults")

return {
  "folke/which-key.nvim",
  opts = {
    spec = vim.list_extend({
      { "<leader><tab>", group = "Tabs" },
      { "<leader>b", group = "Buffer" },
      { "<leader>c", group = "Code" },
      { "<leader>d", group = "Debug" },
      { "<leader>f", group = "File/Find" },
      { "<leader>g", group = "Git" },
      { "<leader>l", group = "Linter" },
      { "<leader>m", group = "Conform" },
      { "<leader>o", group = "Octo" },
      { "<leader>p", group = "Python/Packages" },
      { "<leader>q", group = "Quit/Session" },
      { "<leader>s", group = "Search" },
      { "<leader>u", group = "UI" },
      { "<leader>w", group = "Windows" },
      { "<leader>x", group = "Diagnostics/Quickfix" },

      { "<leader>pj", group = "package.json" },
      { "<leader>py", group = "Python" },
    }, lazyvim_defaults),
  },
}
