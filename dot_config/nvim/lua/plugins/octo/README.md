# octo

[pwntester/octo.nvim](https://github.com/pwntester/octo.nvim) shows GitHub
issues and pull requests in Neovim, and lets you review a pull request there.
It uses `gh` for authentication. The plugin loads at the first `:Octo`.

| Key | Action |
| --- | --- |
| `<leader>or` | Open pull requests that ask for your review, newest first. |
| `<leader>op` | Your open pull requests. |
| `<leader>os` | Start a review of the current pull request. |

The keys are in
[`lua/config/keymaps/octo.lua`](../../config/keymaps/octo.lua).

When you merge from octo, it squashes the commits and deletes the branch
(`default_merge_method` and `default_delete_branch` in
[`config.lua`](config.lua)).
