local M = {}

local function get_bundle_path()
  -- Run PowerShell to find the PSES module base dir (first match)
  local out = vim.fn.systemlist({
    "pwsh",
    "-NoProfile",
    "-Command",
    [[
        Split-Path -Parent (
          (Get-Module -ListAvailable PowerShellEditorServices | Select-Object -First 1).ModuleBase
        )
    ]],
  })
  return out[1]
end

-- local bundle = get_bundle_path()

-- bundle = bundle or "C:/Users/jack0/Documents/PowerShell/Modules/PowerShellEditorServices/4.3.0"
bundle = "C:/Users/jack0/Documents/PowerShell/Modules/PowerShellEditorServices/4.3.0"
M.filetypes = { "ps1", "psm1", "psd1" }

M.settings = {
  powershell = {
    codeFormatting = {
      Preset = "OTBS",
      UseConstantStrings = true,
    },
    -- Example: In case you want to toggle docs
    -- pester = { enable = true },
  },
}

M.init_options = {
  enableProfileLoading = false,
  additionalModules = {}, -- keep empty unless needed
}

-- nvim-lspconfig expects either `bundle_path` (preferred) or `cmd`.
-- If `bundle` is nil, you can still let lspconfig discover defaults on some setups.
M.bundle_path = bundle

return M
