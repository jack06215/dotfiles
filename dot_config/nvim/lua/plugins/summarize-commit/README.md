# summarize-commit (off)

This folder has no active spec. [`config.lua`](config.lua) returns an empty
table, and the keys in it are comments:

- `<leader>ail` would summarize a commit with Ollama.
- `<leader>aio` would summarize a commit with OpenAI.

The code is in [`lua/utils/summarize_commit.lua`](../../utils/summarize_commit.lua).
To turn the feature on, remove the comment marks from the `dir` and `keys`
lines in `config.lua`.
