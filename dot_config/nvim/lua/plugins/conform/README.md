# conform

[stevearc/conform.nvim](https://github.com/stevearc/conform.nvim) formats
files. Press `<leader>mp` to format the file, or the selection in visual mode.

| Filetype | Formatter |
| --- | --- |
| Python | `ruff_fix`, `ruff_organize_imports`, `ruff_format` |
| bash, sh, zsh | `shfmt` |
| Bazel (`bazel`, `bzl`) | `buildifier` |
| C++ | `clang-format` |
| JSON, JSONC | `jq` |
| Jsonnet | `jsonnetfmt` |
| Protocol Buffers | `buf` |

`shfmt` runs with `-i 2 -ci -sr -bn`, and with `-ln zsh` for zsh files and
`-ln bash` for the others.

The config is in [`config.lua`](config.lua), and the key is in
[`keymaps.lua`](keymaps.lua).
