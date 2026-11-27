# avante

[yetone/avante.nvim](https://github.com/yetone/avante.nvim) is an AI side panel
in the style of Cursor. It uses GitHub Copilot (`provider = "copilot"`) in
agentic mode.

## Setup

1. Run `:Copilot auth` one time (copilot.lua). avante reads the token from
   `~/.config/github-copilot/{hosts,apps}.json`, so it needs no API key.
2. Run `:Lazy sync`. The build step runs `:AvanteBuild`, which downloads the
   release libraries. On macOS, it also points those libraries at the system
   `libiconv`, because the release links a `/nix/store` path.
3. Press `<leader>aa` to open the panel. Press `<leader>a?` to select a model.
   The list comes from your Copilot plan. Set `providers.copilot.model` in
   [`config.lua`](config.lua) to one of those IDs.

Put project instructions in `avante.md` at the repository root.

## Settings

- Inline suggestions are off. copilot.lua does inline completion, because
  avante with Copilot sends too many API requests.
- The agent cannot read files that git ignores, for example `.env`.
- The agent can use the read-only tools without asking: `view`, `ls`, `glob`,
  `grep` and `get_diagnostics`. It asks before all other tools, for example
  before it runs a command or writes a file.
- MCP tools come from mcphub.nvim. See [`../mcphub/`](../mcphub/).
- The selector (`@file`, models, history) uses snacks through
  [`selector.lua`](selector.lua). It reads the file list one time and builds a
  preview only for the item under the cursor. avante's own snacks selector
  read every matching file at each key.

## Keys

The default keys of avante. avante sets each key only when it is free.

| Key | Action |
| --- | --- |
| `<leader>aa` | Ask, or open the panel. |
| `<leader>an` | New ask. |
| `<leader>ae` | Edit the selected block. |
| `<leader>at` | Show or hide the panel. |
| `<leader>af` | Focus the panel. |
| `<leader>ar` | Refresh. |
| `<leader>aS` | Stop the request. |
| `<leader>a?` | Select a model. |
| `<leader>ah` | Chat history. |
| `<leader>ac` | Add the current buffer to the context. |
| `<leader>aB` | Add all buffers to the context. |

In the panel:

| Key | Action |
| --- | --- |
| `A`, `a` | Apply all changes, or the change at the cursor. |
| `r`, `e` | Retry, or edit the request. |
| `@`, `d` | Add a file, or remove a file. |
| `<Tab>` | Go to the next window. |
| `q` | Close. |

In a diff conflict: `co` ours, `ct` theirs, `ca` all theirs, `cb` both, `]x`
and `[x` next and previous.

In the input, `@` adds a mention (`@codebase`, `@diagnostics`, `@file`,
`@buffers`) and `/` runs a command (`/new`, `/clear`, `/compact`, `/commit`).
blink-cmp-avante completes both.
