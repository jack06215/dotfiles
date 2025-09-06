# CodeCompanion.nvim

CodeCompanion.nvim is a Neovim plugin designed to extend your development experience by integrating helpful extensions such as adapters, strategies, and additional tools.

## Dependencies

- `j-hui/fidget.nvim`
- `ravitemer/codecompanion-history.nvim`
- `ravitemer/mcphub.nvim`
- `Davidyz/VectorCode`
- `HakonHarnes/img-clip.nvim`

## Installation

Use your preferred plugin manager to install CodeCompanion.nvim:

```lua
use {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "j-hui/fidget.nvim",
    "ravitemer/codecompanion-history.nvim",
    { "ravitemer/mcphub.nvim", cmd = "MCPHub", build = "npm install -g mcp-hub@latest" },
    { "Davidyz/VectorCode", build = "pip install vectorcode" },
    { "HakonHarnes/img-clip.nvim", event = "VeryLazy", cmd = "PasteImage" }
  }
}
```

## Configuration

CodeCompanion.nvim provides various configurations to tailor the plugin to your needs. Below is an example of the default configuration:

```lua
require("plugins.codecompanion").setup {
  extensions = {
    history = {
      enabled = true,
      opts = {
        keymap = "gh",
        save_chat_keymap = "sc",
        auto_save = false,
        auto_generate_title = true,
        continue_last_chat = false
      }
    },
    mcphub = {
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true
      }
    },
    vectorcode = {
      opts = {
        add_tool = true
      }
    }
  },
  strategies = {
    chat = {
      adapter = {
        name = "copilot",
        model = "claude-sonnet-4"
      }
    }
  }
}
```

## Keymaps

- `<C-a>`: Open the action palette
- `<Leader>a`: Toggle a chat buffer
- `<LocalLeader>a`: Add code to a chat buffer

