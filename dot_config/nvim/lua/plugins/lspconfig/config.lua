return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre", -- defer loading for performance
    config = function()
      local lspconfig = require("lspconfig")

      local base = require("lsp-config.base")

      -- A server's default command, to check its binary is installed. nil
      -- when that can't be told (a cmd built by a function, an unknown name),
      -- in which case the server is set up as before.
      local function default_cmd(server)
        local ok, cfg = pcall(function()
          return vim.lsp.config[server]
        end)
        if ok and cfg and type(cfg.cmd) == "table" then
          return cfg.cmd
        end
        local legacy = lspconfig[server] and lspconfig[server].document_config
        local cmd = legacy and legacy.default_config and legacy.default_config.cmd
        return type(cmd) == "table" and cmd or nil
      end

      for _, server in ipairs(base.lsp_list or {}) do
        local opts = {
          capabilities = base.capabilities and base.capabilities() or vim.lsp.protocol.make_client_capabilities(),
          on_attach = base.on_attach or function() end,
        }

        local ok, settings = pcall(require, "lsp-config.settings." .. server)
        if ok and type(settings) == "table" then
          opts = vim.tbl_deep_extend("force", opts, settings)
        end

        -- Not every machine has every server (the list spans brew, npm and
        -- gem installs), and one that isn't there failed with "Spawning
        -- language server ... failed" on every buffer of its filetype.
        local cmd = type(opts.cmd) == "table" and opts.cmd or default_cmd(server)
        if not cmd or vim.fn.executable(cmd[1]) == 1 then
          lspconfig[server].setup(opts)
        end
      end
    end,
  },
}
