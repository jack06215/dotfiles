return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    -- :help conform-formatters for more details
    formatters_by_ft = {
      -- zsh = { "shfmt" },
      bash = { "shfmt" },
      bazel = { "buildifier" },
      bzl = { "buildifier" },
      cpp = { "clang-format" },
      json = { "jq" },
      jsonc = { "jq" },
      jsonnet = { "jsonnetfmt" },
      proto = { "buf" },
      python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
      sh = { "shfmt" },
      zsh = { "shfmt" },
    },
    formatters = {
      shfmt = {
        command = "shfmt",
        args = function(self, ctx)
          local dialect = vim.bo[ctx.buf].filetype == "zsh" and "zsh" or "bash"
          return {
            "-ln",
            dialect,
            "-i",
            "2",
            "-ci",
            "-sr",
            "-bn",
            "--filename",
            ctx.filename,
          }
        end,
        stdin = true,
      },
      proto = {
        command = "buf",
        args = {
          "format",
        },
        stdin = true,
      },
    },
  },
  keys = require("plugins.conform.keymaps"),
}
