return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
      jsonnet = { "jsonnetfmt" },
      json = { "jq" },
      shell = { "shfmt" },
      bazel = { "buildifier" },
      bzl = { "buildifier" },
    },
  },
  keys = require("plugins.conform.keymaps"),
}
