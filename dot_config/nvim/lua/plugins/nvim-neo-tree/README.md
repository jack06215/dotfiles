# nvim-neo-tree

[nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)
(v3) is the file tree. [`lua/config/lazy.lua`](../../config/lazy.lua) imports
the LazyVim neo-tree extra, and [`config.lua`](config.lua) sets up the plugin.

## Settings

- The log level is `warn`.
- The tree shows only the file system (no buffers or git source).
- It shows the files that `.gitignore` excludes.
- It does not move to the current file.
- Git status is off, because it was the largest cost.
- A file watcher updates the tree when files change.
- Line numbers and relative line numbers are on. neo-tree turns them off at each
  buffer enter, so a handler turns them on again.

## Keys in the tree

| Key | Action |
| --- | --- |
| `i` | Show the File Details popup, with extra actions. In the popup, `cp` copies the path. |
| `Y` | Copy the path of the node to the system clipboard and the unnamed register. |

To add a popup action, add an entry to `M.file_detail_actions` in
`config.lua`: `key`, `label`, `handler`, and optionally `keep_open` or
`hint_only`. A command name in `commands` must not be the name of a built-in
neo-tree command, or neo-tree uses the built-in command.

## Other specs in this folder

- [antosha417/nvim-lsp-file-operations](https://github.com/antosha417/nvim-lsp-file-operations)
  tells the LSP server when you rename or move a file in the tree, so the server
  can update the imports.
- `lazydev.nvim` loads the type annotations of nui when a file mentions a
  neo-tree type.

The window picker that neo-tree uses has its own folder:
[`../nvim-window-picker/`](../nvim-window-picker/). Configure it there only.
lazy.nvim merges all the specs of one plugin, and only one `config` function
runs.
