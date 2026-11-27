# Neovim plugins

Each folder here is one plugin, or a small set of plugins for one job.
[`lua/config/lazy.lua`](../config/lazy.lua) imports all the folders with
`{ import = "plugins" }`, on top of the LazyVim plugins.

## Folder pattern

| File | Purpose |
| --- | --- |
| `init.lua` | Returns the spec. Most folders return `require("plugins.<name>.config")`. |
| `config.lua` | The lazy.nvim spec: plugin, load event, options and setup. |
| `keymaps.lua` | Keys for the plugin, in some folders only. |
| `README.md` | What the plugin does here and why. |

Most keys are in [`lua/config/keymaps/`](../config/keymaps/), not in the
folders. See [`dot_config/nvim/README.md`](../../README.md#keymaps).

## Plugins

| Folder | Plugin | Job |
| --- | --- | --- |
| [`avante`](avante/) | yetone/avante.nvim | AI side panel through GitHub Copilot. |
| [`blink`](blink/) | saghen/blink.cmp | Completion, with English and Japanese word sources. |
| [`bufferline`](bufferline/) | akinsho/bufferline.nvim | Buffer tabs, in groups by file type. |
| [`codecompanion`](codecompanion/) | olimorris/codecompanion.nvim | AI chat and inline edits (`<leader>C`). |
| [`comment`](comment/) | numToStr/Comment.nvim | Comment keys. |
| [`conform`](conform/) | stevearc/conform.nvim | Formatting. |
| [`copilot`](copilot/) | zbirenbaum/copilot.lua, CopilotChat.nvim | Copilot suggestions and chat. |
| [`dashboard-nvim`](dashboard-nvim/) | nvimdev/dashboard-nvim | Start screen. |
| [`extras`](extras/) | LazyVim | The TypeScript and JSON extras. |
| [`find-git-root`](find-git-root/) | yyk/find-git-root.nvim | `:CdGitRoot`. |
| [`firevim`](firevim/) | glacambre/firenvim | Neovim in browser text fields. Not on WSL2. |
| [`flash`](flash/) | folke/flash.nvim | Jump by label (`s`). |
| [`fuzzy-motion`](fuzzy-motion/) | yuki-yano/fuzzy-motion.vim | Fuzzy jump on `<CR>`, also with romaji. |
| [`fzf-lua`](fzf-lua/) | ibhagwan/fzf-lua | fzf picker. |
| [`garbage-day`](garbage-day/) | zeioth/garbage-day.nvim | Stops idle LSP clients. |
| [`gitsigns`](gitsigns/) | lewis6991/gitsigns.nvim | Git signs in the sign column. |
| [`goyo`](goyo/) | junegunn/goyo.vim, limelight.vim | Prose mode. |
| [`gruvbox`](gruvbox/) | ellisonleao/gruvbox.nvim | The default color scheme (`NVIM_COLOR` overrides it). |
| [`hardtime`](hardtime/) | m4xshen/hardtime.nvim | Blocks inefficient key habits. |
| [`kensaku`](kensaku/) | lambdalisue/kensaku-search.vim | Search Japanese text with romaji. |
| [`lspconfig`](lspconfig/) | neovim/nvim-lspconfig | Starts each LSP server that the machine has. |
| [`lspsage`](lspsage/) | nvimdev/lspsaga.nvim | LSP windows: peek, rename, line diagnostics. |
| [`lualine`](lualine/) | nvim-lualine/lualine.nvim | Status line, with the SKK mode. |
| [`mason`](mason/) | mason-org/mason.nvim | Installs linters and formatters. |
| [`mcphub`](mcphub/) | ravitemer/mcphub.nvim | MCP servers for the AI chats. |
| [`neogit`](neogit/) | NeogitOrg/neogit | Git interface (`<leader>gg`). |
| [`neotest`](neotest/) | nvim-neotest/neotest | Python tests (`<leader>t`). |
| [`noice`](noice/) | folke/noice.nvim | Message and command line UI. |
| [`nui`](nui/) | MunifTanjim/nui.nvim | UI library for other plugins. |
| [`nvim-colorizer`](nvim-colorizer/) | NvChad/nvim-colorizer.lua | Colors color codes. |
| [`nvim-coverage`](nvim-coverage/) | andythigpen/nvim-coverage | Test coverage in the sign column. |
| [`nvim-hlslens`](nvim-hlslens/) | kevinhwang91/nvim-hlslens | Search match position. |
| [`nvim-lint`](nvim-lint/) | mfussenegger/nvim-lint | Linters. |
| [`nvim-neo-tree`](nvim-neo-tree/) | nvim-neo-tree/neo-tree.nvim | File tree. |
| [`nvim-pet`](nvim-pet/) | pets.nvim (local) | **Off.** The spec is a comment. |
| [`nvim-treesitter`](nvim-treesitter/) | nvim-treesitter/nvim-treesitter | Parsers, and node selection with wildfire. |
| [`nvim-window-picker`](nvim-window-picker/) | s1n7ax/nvim-window-picker | Jump to a window by letter (`<leader>wp`). |
| [`octo`](octo/) | pwntester/octo.nvim | GitHub issues and pull requests. |
| [`owner-code-search`](owner-code-search/) | local | Search the code that one team owns, from `CODEOWNERS`. |
| [`package-info`](package-info/) | vuki656/package-info.nvim | Versions in `package.json`. |
| [`python`](python/) | py-requirements.nvim, pyright | Python env for pyright, and requirements files. |
| [`render-markdown`](render-markdown/) | MeanderingProgrammer/render-markdown.nvim | Formatted Markdown in the buffer. |
| [`skkeleton`](skkeleton/) | vim-skk/skkeleton | SKK Japanese input (`<C-j>`). |
| [`snacks`](snacks/) | folke/snacks.nvim | Image settings. |
| [`sort`](sort/) | sQVe/sort.nvim | Sort lines. |
| [`summarize-commit`](summarize-commit/) | local | **Off.** The keys are comments. |
| [`telescope`](telescope/) | nvim-telescope/telescope.nvim | Picker keys. |
| [`todo-comments`](todo-comments/) | folke/todo-comments.nvim | `TODO` and `FIXME` highlights. |
| [`typescript`](typescript/) | pmizio/typescript-tools.nvim | TypeScript LSP. |
| [`ui`](ui/) | actions-preview.nvim, dim.lua | LSP hover, code actions with a diff preview (`<leader>ca`), dimmed unused code. |
| [`vim-matchup`](vim-matchup/) | andymass/vim-matchup | `%` for words and tags. |
| [`vim-surround`](vim-surround/) | tpope/vim-surround | Surround text (`ys`, `cs`, `ds`). |
| [`which-key`](which-key/) | folke/which-key.nvim | Key popup, and the LazyVim default keys. |

## Add a plugin

1. Make a folder with the plugin name.
2. Write the spec in `config.lua`, and return it from `init.lua`.
3. Put the keys in a file in [`lua/config/keymaps/`](../config/keymaps/), and
   call it from `keymaps.lua`.
4. Add a `README.md` and a row in the table above.
