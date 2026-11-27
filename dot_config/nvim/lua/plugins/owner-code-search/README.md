# owner-code-search

A local plugin. It searches only the code that one team owns. It reads
`.github/CODEOWNERS` in the repository, finds the paths whose owners match the
team, and searches those paths with ripgrep or fd.

The code is in
[`lua/utils/owner_code_search.lua`](../../utils/owner_code_search.lua).
[`config.lua`](config.lua) adds the keys and the commands.

| Key | Command | Search | Team match |
| --- | --- | --- | --- |
| `<leader>rg` | `:OwnerCodeGrep` | text, with ripgrep | substring |
| `<leader>rG` | `:OwnerCodeGrepPattern` | text, with ripgrep | regular expression |
| `<leader>fd` | `:OwnerCodeFd` | file names, with fd | substring |
| `<leader>fD` | `:OwnerCodeFdPattern` | file names, with fd | regular expression |

Each key asks for the team, then for the search pattern.
