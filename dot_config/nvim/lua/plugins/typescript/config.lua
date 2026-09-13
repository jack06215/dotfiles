local M = {}

M.settings = {
  separate_diagnostic_server = true,
}

M.plugins = {
  {
    "pmizio/typescript-tools.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {
      settings = M.settings,
      -- Deno projects belong to denols (lsp-config/settings/denols.lua); two
      -- servers on one buffer make lspsaga's peek_definition open two floats.
      root_dir = function(bufnr, on_dir)
        if vim.fs.root(bufnr, { "deno.json", "deno.jsonc" }) then
          return
        end
        on_dir(require("typescript-tools.utils").get_root_dir(bufnr))
      end,
    },
  },

  -- LazyVim default TS extras
  { import = "lazyvim.plugins.extras.lang.typescript" },
}

return M.plugins
