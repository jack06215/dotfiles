# extras

This folder adds two LazyVim extras: `lang.typescript` and `lang.json`. Each
extra brings the LSP server, the formatter and the tree-sitter parsers for that
language. The `ui.mini-starter` extra is in [`config.lua`](config.lua) as a
comment.

`lazyvim.json` lists no extras, so you enable an extra here, not with
`:LazyExtras`. Import each extra in this folder only, so that one file shows
all of them.
