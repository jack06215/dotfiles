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
        make_vars = false,
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

## Recorder

`recorder.lua` is a local extension that saves every chat turn and inline request to
`~/.local/share/nvim/codecompanion/history.db`, with one row per request: `request`, `code`, `result`
and metadata. It needs `sqlite3` on `PATH`, and warns once if it's missing or a write fails.

```sh
sqlite3 ~/.local/share/nvim/codecompanion/history.db \
  'SELECT created_at, kind, model, status, request FROM interactions ORDER BY id DESC LIMIT 20'
```

- The database is plain text and can hold anything sent to the model, including secrets from an open
  file. It's `0600`, lives outside this repo, and is never pruned.
- `.chezmoiignore` keeps the extension off machines with `isCompanyMachine` set.
- Inline `result` is a unified diff, or the reply if the model didn't edit. An inline row's status is
  `accepted` once any of its edits are kept. A row still at `proposed` was rejected or never reviewed.
- Inline recording wraps the private `Inline.done` and `Inline.stop`. If an update renames them you get
  one warning and inline stops being recorded, but inline keeps working.
- Not recorded: background requests such as title generation, `:CodeCompanionCLI` sessions, chats that
  fail before they start (such as over the token limit), and chats closed mid-response. A stopped chat
  or inline request keeps its row, but not the partial reply.

## Keymaps

- `<C-a>`: Open the action palette
- `<Leader>a`: Toggle a chat buffer
- `<LocalLeader>a`: Add code to a chat buffer

