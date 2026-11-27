# dashboard-nvim

[nvimdev/dashboard-nvim](https://github.com/nvimdev/dashboard-nvim) is the
start screen. [`config.lua`](config.lua) turns off the snacks dashboard,
which LazyVim uses by default.

The header shows a NEOVIM logo, the host name, the Neovim version and the date.
The footer shows how many plugins loaded and the start time.

| Key | Action |
| --- | --- |
| `p` | Projects |
| `f` | Find a file |
| `n` | New file |
| `r` | Recent files |
| `g` | Find text |
| `c` | Config files |
| `s` | Restore the last session |
| `x` | LazyVim extras |
| `l` | lazy.nvim |
| `q` | Quit |

The plugin is not lazy-loaded, because it must handle stdin at start. The
dashboard opens again when you close the lazy.nvim window.
