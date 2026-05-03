local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Bootstrap lazy.nvim if needed
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- VSCode: avoid strict plugin load-order checks
vim.g.lazyvim_check_order = false

require("lazy").setup({
  spec = {
    -- LazyVim core & its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Your custom plugins (these are mostly VSCode-compatible:
    -- LSP, treesitter, Copilot, CodeCompanion, Octo, etc.)
    { import = "plugins" },
  },

  defaults = {
    -- In VSCode we prefer eager loading for simplicity; LazyVim
    -- will still lazy-load its own plugins where appropriate.
    lazy = false,
    version = false,
  },

  -- Colorschemes that work fine in VSCode Neovim terminal
  install = { colorscheme = { "tokyonight", "habamax" } },

  checker = {
    enabled = true,
    notify = false,
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
