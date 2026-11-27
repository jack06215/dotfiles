# nvim-coverage

[andythigpen/nvim-coverage](https://github.com/andythigpen/nvim-coverage)
shows test coverage in the sign column. The `neotest` spec lists it as a
dependency, so it loads with neotest.

[`config.lua`](config.lua) has `opts = {}`. lazy.nvim calls
`require("coverage").setup()` only when a spec has `opts` or `config`, and
`setup()` makes the `:Coverage` commands.
