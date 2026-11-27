# mason

[mason-org/mason.nvim](https://github.com/mason-org/mason.nvim) installs
linters, formatters and debug adapters into Neovim's data folder.
[mason-tool-installer](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim)
installs the tools in the `M.tools` list of [`config.lua`](config.lua) at each
start, and updates them.

| Kind | Tools |
| --- | --- |
| Python | `ruff`, `mypy`, `pylint`, `black`, `autopep8`, `debugpy` |
| JavaScript, web | `eslint_d`, `prettier` |
| Shell | `shellcheck`, `shfmt` |
| Other | `buf`, `cmakelang`, `cpplint`, `jsonnet-language-server`, `markdownlint`, `yamllint`, `stylua` |

`PATH = "append"` puts the mason tools at the end of `PATH`. Thus a tool from
Homebrew, asdf or the monorepo venv wins over the mason copy.

To add a tool, add its mason name to `M.tools`.
