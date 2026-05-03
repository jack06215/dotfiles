return {
  "mfussenegger/nvim-lint",
  event = {
    "BufReadPre",
    "BufNewFile",
  },
  config = function()
    local lint = require("lint")

    lint.linters.buf = {
      name = "buf",
      cmd = "buf",
      stdin = false,
      args = { "lint" },
      stream = "stderr",
      ignore_exitcode = true,
      parser = require("lint.parser").from_errorformat("%f:%l:%c:%m", {
        source = "buf",
      }),
    }

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      python = { "mypy", "ruff" }, -- Or "ruff" or "flake8" (pick one)
      cpp = { "cpplint" },
      proto = { "buf" },
      sql = { "sqlfluff" },
      markdown = { "markdownlint" },
      yaml = { "yamllint" },
      bash = { "shellcheck" },
      zsh = { "shellcheck" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
