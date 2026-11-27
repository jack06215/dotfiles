# gruvbox

[ellisonleao/gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) is the
default color scheme.

[`config.lua`](config.lua) sets the LazyVim `colorscheme` from
`vim.g.personal_options.colorscheme` in
[`lua/config/general.lua`](../../config/general.lua). That value is
`$NVIM_COLOR`, or `gruvbox` when the variable is not set.

To try another installed color scheme for one session, start Neovim with
`NVIM_COLOR=<name> nvim`. If LazyVim cannot load that color scheme, it shows an
error and uses `habamax`.
