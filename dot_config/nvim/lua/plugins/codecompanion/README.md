# codecompanion

[olimorris/codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
is an AI chat and inline editor. It loads at the first `:CodeCompanion`,
`:CodeCompanionChat` or `:CodeCompanionActions`. On the command line, `cc`
expands to `CodeCompanion`.

## Models

| Use | Adapter | Model |
| --- | --- | --- |
| Chat | Copilot | `claude-opus-5.5` |
| Inline edit | Copilot | `gpt-6.1-sol` |
| Optional | Ollama | `qwen3.6:35b`, with a context of 20000 tokens |

## Chat keys

| Key (insert mode) | Action |
| --- | --- |
| `<C-CR>`, `<C-s>` | Send the message. |
| `<C-x>` | Completion. |
| `<C-b>` | `/buffer`: add a buffer. |
| `<C-f>` | `/fetch`: add a web page. |
| `<C-i>` | `/image`: add an image. It looks in `~/Documents/Screenshots`, or on WSL2 in the Windows `Pictures/Screenshots` folder. |

## Global keys

[`lua/config/keymaps/codecompanion.lua`](../../config/keymaps/codecompanion.lua)
sets these keys. which-key shows them as the `CodeCompanion` group.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>Cc` | normal, visual | Show or hide the chat. |
| `<leader>Cp` | normal, visual | Open the action palette. |
| `<leader>Ca` | visual | Add the selection to the chat. |

The prefix is `<leader>C`, not `<leader>a`, because the default keys of
[avante](../avante/) use `<leader>a`. `<C-a>` keeps its Vim job, which is to
increment a number.

## Extensions

- **history** (codecompanion-history.nvim). `gh` opens the chat history in a
  snacks picker, and `sc` saves the chat. It does not save automatically, and
  it makes a title for each chat. The chats go to
  `$XDG_DATA_HOME/nvim/codecompanion-history`.
- **mcphub**. MCP server prompts become slash commands, and tool results show
  in the chat. See [`../mcphub/`](../mcphub/).
- **vectorcode**. A code search tool. It is on only when the machine has the
  `vectorcode` program. The build step upgrades it with `uv` or `pipx`.
- **img-clip.nvim** pastes an image into the chat as a Markdown link with an
  absolute path.
- **recorder**. The local extension in [`recorder.lua`](recorder.lua). See
  below.

Diffs use `mini_diff`, and the log level is `DEBUG`.

## Recorder

[`recorder.lua`](recorder.lua) saves each chat turn and each inline request in
`$XDG_DATA_HOME/nvim/codecompanion/history.db`. Each request is one row, with
the request, the code, the result and metadata. It needs `sqlite3` on `PATH`.
It shows one warning if `sqlite3` is missing or if a write fails.

```sh
sqlite3 ~/.local/share/nvim/codecompanion/history.db \
  'SELECT created_at, kind, model, status, request FROM interactions ORDER BY id DESC LIMIT 20'
```

> [!WARNING]
> The database is plain text. It can hold all data sent to the model,
> including secrets from an open file. The file mode is `0600`, the file is
> outside this repository, and the recorder never deletes old rows.
> `.chezmoiignore` does not install `recorder.lua` on a company machine, and
> `config.lua` turns the extension off when the file is not there.

- For an inline request, `result` is a unified diff, or the reply when the
  model did not edit. The status of an inline row becomes `accepted` when you
  keep one of its edits. A row that stays at `proposed` is an edit that you
  rejected or did not review.
- The inline recording wraps the private functions `Inline.done` and
  `Inline.stop`. If an update changes their names, you get one warning, and
  the recorder stops recording inline requests. Inline edits continue to work.
- The recorder does not record these:
  - Background requests, for example title generation.
  - `:CodeCompanionCLI` sessions.
  - Chats that fail before they start, for example over the token limit.
  - Chats that you close during the reply.
- A stopped chat or inline request keeps its row, but not the partial reply.
