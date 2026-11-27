# nvim-lint

[mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint) runs
linters and shows their results as diagnostics. It lints when you enter a
buffer, when you save, and when you leave insert mode.

| Filetype | Linters |
| --- | --- |
| JavaScript, TypeScript, JSX, Svelte | `eslint_d` |
| Python | `mypy`, `ruff` |
| C++ | `cpplint` |
| Protocol Buffers | `buf` |
| SQL | `sqlfluff` |
| Markdown | `markdownlint` |
| YAML | `yamllint` |
| Bash | `shellcheck` |
| zsh | `zsh -n` |

[`config.lua`](config.lua) defines two linters itself: `buf` (`buf lint`) and
`zsh` (`zsh -n`, a syntax check).

## Keys

[`lua/config/keymaps/nvim-lint.lua`](../../config/keymaps/nvim-lint.lua) sets
these keys:

| Key | Action |
| --- | --- |
| `<leader>ll` | Lint the current file. |
| `<leader>lL` | Run the lint again. |
