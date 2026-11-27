# copilot

Two plugins for GitHub Copilot:

- [zbirenbaum/copilot.lua](https://github.com/zbirenbaum/copilot.lua) shows
  inline suggestions and the suggestion panel. Both are on. The plugin loads at
  the first `:Copilot` command. After an install or an update, lazy.nvim runs
  `:Copilot auth`.
- [CopilotC-Nvim/CopilotChat.nvim](https://github.com/CopilotC-Nvim/CopilotChat.nvim)
  adds a chat with Copilot. Its model is `claude-sonnet-4`.

The config is in [`config.lua`](config.lua).
