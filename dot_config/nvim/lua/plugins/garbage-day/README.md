# garbage-day

[zeioth/garbage-day.nvim](https://github.com/zeioth/garbage-day.nvim) stops
LSP clients that are not in use, to free memory. It loads when the first LSP
client attaches, and it shows a notification when it stops or starts a client.

It never stops these clients: `null-ls`, `copilot`, `jdtls`, `lua_ls` and
`pyright`.

The config is in [`config.lua`](config.lua).
