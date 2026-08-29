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
      -- Bufferi
      { "<leader>b", group = "Buffer" },
      -- Python
      { "<leader>py", group = "Python" },
      -- package.json -- buffer-local to json buffers, see
      -- config/keymaps/package-info.lua
      { "<leader>pj", group = "package.json" },
      -- AI -- avante's <leader>a* keys are deleted in
      -- config/keymaps/avante.lua, so nothing sits under this yet
      { "<leader>a", group = "AI" },
      { "<leader>o", group = "Octo" },
      { "<leader>g", group = "git" },
    }, lazyvim_defaults),
  },
}
