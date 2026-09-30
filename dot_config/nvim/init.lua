-- One path for nvim and vscode-neovim. When vim.g.vscode is set, LazyVim turns
-- on its vscode extra by itself (lazyvim/plugins/xtras.lua), and that extra
-- decides which plugins load there; config/keymaps.lua picks the keymaps.
require("config.general")
require("config.lazy")
require("config.after")
