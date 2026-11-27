# gitsigns

[lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) shows
the git changes of each line in the sign column. It loads when a file opens.

| Sign | Meaning |
| --- | --- |
| `┃` | Added or changed line. |
| `_` | Deleted line below. |
| `‾` | Deleted line above (at the top of the file). |
| `~` | Changed and deleted. |
| `┆` | Untracked. |

- Staged changes show with the same signs.
- The blame of the current line is off. When you turn it on, it shows the
  author, the age and the summary at the end of the line, after 1 second.
- Gitsigns does not attach to untracked files, or to files with more than 40000
  lines.

The config is in [`config.lua`](config.lua).
