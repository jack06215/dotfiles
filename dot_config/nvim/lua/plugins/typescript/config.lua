local M = {}

M.settings = {
  separate_diagnostic_server = true,
}

M.tsserver_keys = function(bufnr)
  local map = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr })
  end

  map("n", "gd", vim.lsp.buf.definition)
  map("n", "gr", vim.lsp.buf.references)
  map("n", "K", vim.lsp.buf.hover)
  -- 必要に応じて追加
end

M.plugins = {
  {
    "pmizio/typescript-tools.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {
      settings = M.settings,
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {
          keys = M.tsserver_keys,
        },
      },
    },
  },

  -- LazyVim default TS extras
  { import = "lazyvim.plugins.extras.lang.typescript" },
}

return M.plugins
