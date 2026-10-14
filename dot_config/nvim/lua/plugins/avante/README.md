# Avante.nvim

Cursor-style AI sidebar, configured for GitHub Copilot (`provider = "copilot"`).

## Setup

1. `:Copilot auth` once (copilot.lua). Avante reads the token from
   `~/.config/github-copilot/{hosts,apps}.json`, no API key needed.
2. `:Lazy sync` (the `build` step downloads the prebuilt binary via `make`).
3. Open the sidebar with `<leader>aa` and pick a model with `<leader>a?` — the
   list comes from your Copilot plan, so set `providers.copilot.model` in
   `config.lua` to one of those IDs.

Project instructions go in `avante.md` at the repo root.

## Key Mappings

Avante's defaults (set only when the key is free):

| Keybinding    | Action                          |
|---------------|---------------------------------|
| `<leader>aa`  | Ask / open sidebar              |
| `<leader>an`  | New ask                         |
| `<leader>ae`  | Edit selected block             |
| `<leader>at`  | Toggle sidebar                  |
| `<leader>af`  | Focus sidebar                   |
| `<leader>ar`  | Refresh                         |
| `<leader>aS`  | Stop request                    |
| `<leader>a?`  | Select model                    |
| `<leader>ah`  | Chat history                    |
| `<leader>ac`  | Add current buffer to context   |
| `<leader>aB`  | Add all buffers to context      |

In the sidebar: `A` apply all, `a` apply at cursor, `r` retry, `e` edit
request, `@` add file, `d` remove file, `<Tab>` switch windows, `q` close.
Diff conflicts: `co` ours, `ct` theirs, `ca` all theirs, `cb` both,
`]x` / `[x` next / previous.

In the input: `@` mentions (`@codebase`, `@diagnostics`, `@file`, `@buffers`),
`/` commands (`/new`, `/clear`, `/compact`, `/commit`), completed by
blink-cmp-avante.
