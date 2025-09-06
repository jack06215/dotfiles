return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre", -- defer loading for performance
    config = function()
      local lspconfig = require("lspconfig")

      local base = require("lsp-config.base")

      for _, server in ipairs(base.lsp_list or {}) do
        local opts = {
          capabilities = base.capabilities and base.capabilities() or vim.lsp.protocol.make_client_capabilities(),
          on_attach = base.on_attach or function() end,
        }

        local ok, settings = pcall(require, "lsp-config.settings." .. server)
        if ok and type(settings) == "table" then
          opts = vim.tbl_deep_extend("force", opts, settings)
        end

        lspconfig[server].setup(opts)
      end
    end,
  },
}
