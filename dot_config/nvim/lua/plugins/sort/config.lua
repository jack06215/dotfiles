return {
  "sQVe/sort.nvim",
  -- Rewrites buffer lines, which vscode-neovim syncs back, so :Sort and the
  -- <leader>so/sO/SD keys work in VS Code too.
  vscode = true,
  config = function()
    local sort = require("sort")
    sort.setup({
      delimiters = { ",", "|", ";", " " }, -- customizable
    })
  end,
  keys = require("plugins.sort.keymaps"),
  -- Keys have been moved to `keymaps.lua`
}
