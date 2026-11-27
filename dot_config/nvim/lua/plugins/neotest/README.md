# neotest

[nvim-neotest/neotest](https://github.com/nvim-neotest/neotest) runs tests
from the editor and shows the results in the buffer. The only adapter is
`neotest-python` (pytest). It runs pytest with `-s`, debug logging and the
working directory on `pythonpath`. Debugging steps into library code too
(`justMyCode = false`).

## Keys

[`keymaps.lua`](keymaps.lua) defines these keys:

| Key | Action |
| --- | --- |
| `<leader>tr` | Run the nearest test. |
| `<leader>tf` | Run the tests in the file. |
| `<leader>tw`, `<leader>tW` | Watch the nearest test, or the file. |
| `<leader>tp` | Show or hide the output panel. |
| `<leader>to`, `<leader>tO` | Show the test output, without or with focus. |
| `[E`, `]E` | Go to the previous or next failed test. |

The plugin loads at the first of these keys. There is no `[e` and `]e` pair.
LazyVim binds those keys to the previous and next diagnostic error. lazy.nvim
sets the keys of a plugin again when the plugin loads. Thus a neotest pair
would replace the LazyVim error jumps after the first test run.

In vscode-neovim, [`lua/config/keymaps/vscode.lua`](../../config/keymaps/vscode.lua)
sends the test keys to the Testing view of VS Code.

`nvim-coverage` is a dependency of this spec. See
[`../nvim-coverage/README.md`](../nvim-coverage/README.md).
