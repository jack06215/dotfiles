return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },

    opts = function(_, opts)
      local extra_packages = {
        "bash",
        "bibtex",
        "cmake",
        "cpp",
        "cuda",
        "glsl",
        "html",
        "javascript",
        "json",
        "json5",
        "jsonc",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "nim",
        "nim_format_string",
        "proto",
        "python",
        "rust",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "vue",
        "yaml",
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, extra_packages)

      opts.highlight = opts.highlight or {}
      opts.highlight.disable = {
        "latex",
        "tex",
        "markdown",
        "sh",
        "bash",
        "zsh",
      }

      opts.indent = opts.indent or {}
      opts.indent.disable = { "python", "yaml" }

      return opts
    end,
  },

  -- wildfire (Treesitter selection 拡張)
  {
    "sustech-data/wildfire.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      keymaps = {
        init_selection = "gn",
        node_incremental = "]]",
        node_decremental = "[[",
      },
      matchup = {
        enable = true,
        disable_virtual_text = false,
        include_match_words = true,
      },
    },
  },
}
