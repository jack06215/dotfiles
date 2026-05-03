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
    },
    -- tell Conform how to run
    formatters = {
      shfmt = {
        command = "shfmt",
        args = {
          "-ln",
          "bash", -- closest match for zsh
          "-i",
          "2",
          "-ci",
          "-sr",
          "-bn",
        },
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
