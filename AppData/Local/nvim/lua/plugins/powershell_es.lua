return   {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local bundle_path = vim.fn.systemlist({
        "pwsh", "-NoProfile", "-Command",
        [[
          Split-Path -Parent (
            (Get-Module -ListAvailable PowerShellEditorServices | Select-Object -First 1).ModuleBase
          )
        ]]
      })
      local start_script = bundle_path[1] .. "/PowerShellEditorServices/Start-EditorServices.ps1"
      -- vim.notify(vim.inspect(bundle_path[1]), vim.log.levels.ERROR, { title = "PowerShellEditorServices Path" })
      lspconfig.lua_ls.setup({})
      lspconfig.powershell_es.setup({
        filetypes = {"ps1", "psm1", "psd1"},
        bundle_path = "C:/Users/jack0/Documents/PowerShell/Modules/PowerShellEditorServices/4.3.0",
        settings = { powershell = { codeFormatting = { Preset = 'OTBS' } } },
        init_options = {
          enableProfileLoading = false,
        },
      })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set({ 'n' }, '<leader>ca', vim.lsp.buf.code_action, {})
    end
  }