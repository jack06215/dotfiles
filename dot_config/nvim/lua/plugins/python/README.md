# python

Python support on top of the LazyVim defaults. [`config.lua`](config.lua) sets
`vim.g.lazyvim_python_lsp = "pyright"`, so LazyVim uses pyright as the Python
LSP server.

## pyright and the Python env

pyright gets its `pythonPath` from
[`lua/utils/python_env.lua`](../../utils/python_env.lua) when the server
starts. The helper finds the project root by `.git`, `pyproject.toml` or
`.venv`, then uses the first Python that it finds:

1. `.venv` in the project root (a uv venv, or a Poetry venv in the project).
2. The Poetry venv of the project (`poetry env info`).
3. On WSL2, the Linux Python, never a Windows shim.
4. On Termux, the Termux Python.

The lookup runs when pyright starts, not at Neovim start. `poetry env info`
took about 300 ms, also in sessions with no Python file.

## Requirements files

[MeanderingProgrammer/py-requirements.nvim](https://github.com/MeanderingProgrammer/py-requirements.nvim)
shows the latest version of each package in `requirements*.txt` and
`pyproject.toml`. This folder also installs the tree-sitter parser for
`requirements` files.

| Key | Action |
| --- | --- |
| `<leader>pyu` | Update the package on the cursor line. |
| `<leader>pya` | Update all packages. |
| `<leader>pyi` | Show the package description. |

- In `pyproject.toml`, hover (`K`) and diagnostics work, but updates do not.
  The plugin cannot edit Poetry tables.
- [`config.lua`](config.lua) reads Poetry constraints such as `^1.2.3` and
  `~1.2.3` itself, because the plugin reads them as invalid PEP 508 lines.
- `config.lua` limits the plugin to 16 version requests at a time. Without
  the limit, a large `pyproject.toml` started one curl for each package at the
  same time, and on macOS this used all file descriptors.
- The plugin compares only final releases, because an `rc` or `post` version
  causes an error in its version comparison.

## Other keys

[`lua/config/keymaps/python.lua`](../../config/keymaps/python.lua) binds
`<leader>pym`, which copies the dotted module name of the file, for example
`pkg.mod.file`.
