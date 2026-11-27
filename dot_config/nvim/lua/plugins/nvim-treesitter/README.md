# nvim-treesitter

[nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
installs the tree-sitter parsers. LazyVim already installs a set of parsers,
and [`config.lua`](config.lua) adds these:

| Kind | Parsers |
| --- | --- |
| Shell and build | bash, cmake, make |
| C family and GPU | cpp, cuda, glsl |
| Web | html, javascript, typescript, tsx, vue |
| Data | json, json5, jsonc, toml, yaml, proto |
| Documents | markdown, bibtex, vimdoc |
| Other | lua, nim, python, rust, regex, vim |

- **zsh** has no tree-sitter grammar, so zsh files use the bash parser.
- **Highlight** comes from the classic syntax files, not from tree-sitter, for
  LaTeX, TeX, Markdown, sh and bash. zsh uses the bash parser, so this also
  applies to zsh.
- **Indent** from tree-sitter is off for Python and YAML.

## Selection

[sustech-data/wildfire.nvim](https://github.com/sustech-data/wildfire.nvim)
selects tree-sitter nodes:

| Key | Action |
| --- | --- |
| `gn` | Start a selection on the node at the cursor. |
| `]]` | Grow the selection to the parent node. |
| `[[` | Shrink the selection. |

It also selects the match pairs of vim-matchup, for example `if` to `end`.
