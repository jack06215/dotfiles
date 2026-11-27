# nvim-window-picker

[s1n7ax/nvim-window-picker](https://github.com/s1n7ax/nvim-window-picker)
jumps to a window by a letter. Press `<leader>wp`: each window shows a large
letter, and you type the letter of the window that you want.

- The letters come from the home row first (`ASDFGHJKL…`).
- The current window does not get a letter. If only one other window is
  available, the picker goes to it at once.
- The picker skips these windows: neo-tree, notifications, noice, Trouble and
  lazy.nvim, and terminal, quickfix, prompt and scratch buffers.

Both the spec in [`config.lua`](config.lua) and
[`lua/config/keymaps/nvim-window-picker.lua`](../../config/keymaps/nvim-window-picker.lua)
define `<leader>wp`.

This folder is the only place that configures the picker. neo-tree also uses
it. Do not add a second spec with a `config` function in another folder:
lazy.nvim merges the specs of one plugin, and only one `config` function runs.
