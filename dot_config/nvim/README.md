# Neovim

A config on top of [LazyVim](https://github.com/LazyVim/LazyVim), started from
the LazyVim starter (fork: `jack06215/lazyvim-starter`). chezmoi installs this
folder as `~/.config/nvim`. The same config also runs in VS Code through
vscode-neovim.

> [!IMPORTANT]
> Neovim writes three files that chezmoi manages. After a change, copy the
> file back into the repository. If you do not, the next `chezmoi apply`
> reports that the file changed, and if you let it overwrite the file, the
> change is lost:
>
> | Change | Command |
> | --- | --- |
> | `zg` adds a spell word | `chezmoi add ~/.config/nvim/spell/en.utf-8.add` |
> | skkeleton learns a word | `chezmoi add ~/.config/nvim/skk/user-jisyo` |
> | `:Lazy update` changes plugin versions | `chezmoi add ~/.config/nvim/lazy-lock.json` |

## Layout

| Path | Purpose |
| --- | --- |
| [`init.lua`](init.lua) | The entry point for Neovim and vscode-neovim. It loads `config.general`, `config.lazy` and `config.after`. |
| [`lua/config/`](lua/config/) | Options, autocommands, the lazy.nvim setup ([`lazy.lua`](lua/config/lazy.lua)) and general settings, for example the spell file and the navi `cheat` filetype. |
| [`lua/config/keymaps.lua`](lua/config/keymaps.lua), [`keymaps/`](lua/config/keymaps/) | Keymaps, one file for each area or plugin. See [Keymaps](#keymaps). |
| [`lua/plugins/`](lua/plugins/) | One folder for each plugin. Most folders have an `init.lua` that returns the spec from `config.lua`. lazy.nvim imports all of them. |
| [`lua/lsp-config/`](lua/lsp-config/) | LSP settings, with one file for each server in `settings/`. |
| [`lua/utils/`](lua/utils/) | Helper modules for the plugins and keymaps. |
| [`lua/vendor/`](lua/vendor/) | Local copies of `pets.nvim` and `pokemon.nvim`. |
| [`after/ftplugin/`](after/ftplugin/) | Settings for each filetype. |
| [`syntax/cheat.vim`](syntax/cheat.vim) | Syntax for navi cheatsheets, which have no tree-sitter grammar. |
| [`spell/en.utf-8.add`](spell/en.utf-8.add) | Your spell words. |
| [`skk/user-jisyo`](skk/user-jisyo) | The words that skkeleton learned. |
| [`lazy-lock.json`](lazy-lock.json) | The plugin versions that lazy.nvim installs. |

## Keymaps

[`lua/plugins/which-key/lazyvim-defaults.lua`](lua/plugins/which-key/lazyvim-defaults.lua)
holds the stock LazyVim keymaps as which-key entries. which-key applies them
late, so `keymaps.lua` waits for which-key, and then applies the files in
`keymaps/` on top. A new keymap goes in a file in `keymaps/`, not in the `keys`
block of a plugin spec.

In vscode-neovim, which-key and most plugins do not load. `keymaps.lua` then
applies only `general.lua`, `lazyvim.lua` and
[`vscode.lua`](lua/config/keymaps/vscode.lua), which binds the same keys to VS
Code commands.

## English word completion

`blink-cmp-dictionary` completes English words in prose. Its words have a lower
score than all code sources, so they never come before an LSP item.

- [`.chezmoiscripts/run_onchange_after_generate-dictionary.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_generate-dictionary.sh.tmpl)
  writes the word list to `$XDG_DATA_HOME/dict/words.txt` on apply. It uses
  the first source that it finds: `/usr/share/dict/words`, the Debian
  `american-english` file, or the WordNet index files. If it finds none, it
  writes nothing, and the source uses only the spell file.
- The spell file also feeds the source, so a word that you add with `zg`
  completes at once.
- The documentation window shows definitions only when `wn` (WordNet) is
  installed.

## Japanese input

Two plugins share the work:

| Plugin | Keys | Job |
| --- | --- | --- |
| `blink-cmp-im` | `<leader>uj` (normal mode), `<M-j>` (insert mode) | Completes a word from romaji in the blink menu. `nihongo` gives 日本語. It covers nouns, compounds and proper nouns, not verb or adjective forms. It is off until you turn it on, because romaji such as `no` and `to` are also normal identifiers. |
| skkeleton | `<C-j>` (insert mode, command line) | An SKK input method in the buffer, for any text, including conjugated forms. lualine shows あ or ア while it is on, and blink is off while you compose. See [`lua/plugins/skkeleton/README.md`](lua/plugins/skkeleton/README.md). |

[`.chezmoiscripts/run_onchange_after_generate-jisyo.sh.tmpl`](../../.chezmoiscripts/run_onchange_after_generate-jisyo.sh.tmpl)
makes the data for both plugins on apply:

- It reads SKK-JISYO from a system package (`apt install skkdic`). If there is
  none, it downloads the file one time to `$XDG_CACHE_HOME/skk`. With no
  package and no network, it writes nothing.
- It writes `$XDG_DATA_HOME/dict-ja/skk.txt` (romaji to word, for
  `blink-cmp-im`) and `SKK-JISYO.utf8` (for skkeleton).
- It writes both Hepburn and Kunrei romaji, so `shinbun` and `sinbun` both find
  新聞.
- Set `SKK_JISYO_SIZE=M` before `chezmoi apply` to use about a tenth of the
  words. `blink-cmp-im` reads the whole table at the first Japanese completion
  of a session, so use `M` if that pause is too long.

## Links

- [ASCII art generator](https://patorjk.com/software/taag/#p=display&f=BlurVision%20ASCII&t=)
