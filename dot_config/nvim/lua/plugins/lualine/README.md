# lualine

[nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) is
the status line. [`config.lua`](config.lua) keeps the LazyVim layout, makes one
status line for all windows, and replaces the right section (`lualine_x`) with
these items:

| Item | Shows |
| --- | --- |
| SKK mode | The skkeleton mode: `あ` (hiragana), `ア` (katakana), `ｱ` (half-width katakana), `Ａ` (full-width) or `aA` (abbreviation). Empty when skkeleton is off. |
| Python env | In a Python buffer, the name of the active virtual env or conda env. |
| LSP | The names of the LSP clients on the buffer, or `none`. |
| Directory | The current directory as `parent/current`, or `~/` for the home directory. |

The SKK mode item exists because the `▽` and `▼` markers show only a
conversion in progress, not the mode for the next key.
