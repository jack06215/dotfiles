# neogit

[NeogitOrg/neogit](https://github.com/NeogitOrg/neogit) is a git interface in
the style of Magit. Press `<leader>gg` to open it. The key is in
[`lua/config/keymaps/neogit.lua`](../../config/keymaps/neogit.lua).

- It opens in a split, not a float. The process buffer also opens in a split,
  because the float window had problems.
- Diffs open in diffview, and selections use telescope.
- The process spinner is off. Line numbers stay on.

The config is in [`config.lua`](config.lua).
