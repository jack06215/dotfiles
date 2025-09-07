if vim.g.vscode then
  -- VSCode extension
  require("config.general")
  require("config.lazy-vscode")
  require("config.after")
else
  -- Neovim
  require("config.general")
  require("config.lazy")
  require("config.after")
end
