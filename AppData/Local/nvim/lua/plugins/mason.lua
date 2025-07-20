local M = {
  "williamboman/mason.nvim",
  event = "VeryLazy",
  dependencies = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
}

M.tools = {
  -- DAP
  "debugpy",

  -- Linters
  "buf",
  "cmakelang",
  "cpplint",
  "eslint_d",
  -- "flake8", -- if using flake8 instead of ruff
  "markdownlint",
  "mypy",
  "pylint",
  "yamllint",
  "shellcheck",
  "jsonnet-language-server",

  -- Formatters
  "autopep8",
  "black",
  "cmakelang",
  -- "isort",
  "prettier",
  "ruff",
  "shfmt",
  "stylua",
}

M.config = function()
  require("mason").setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
    PATH = "append",
  })

  require("mason-tool-installer").setup({
    ensure_installed = M.tools,
    auto_update = true,
    run_on_start = true,
  })
end

return M
