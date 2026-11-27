# mcphub

[ravitemer/mcphub.nvim](https://github.com/ravitemer/mcphub.nvim) connects
MCP servers to the AI chat plugins in this config.

- It uses the global `mcp-hub` program, not a bundled one. After an install or
  an update, lazy.nvim runs `npm install -g mcp-hub@latest`. The npm config
  puts that program in `$XDG_DATA_HOME/npm/bin`.
- It makes slash commands for avante from the MCP server prompts.
- It gives the MCP tools and resources to CopilotChat as functions.

> [!WARNING]
> `auto_approve = true`: an AI chat can call an MCP tool without asking you.
> `auto_toggle_mcp_servers = true`: the chat can also start and stop MCP
> servers.

The log level is `DEBUG` when `vim.g.personal_options.debug.avante` is true,
and `WARN` in other cases.

The config is in [`config.lua`](config.lua).
