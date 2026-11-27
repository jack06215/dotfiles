# blink

[saghen/blink.cmp](https://github.com/saghen/blink.cmp) is the completion menu
that LazyVim uses. This folder keeps the LazyVim sources and adds two sources
for prose. Both rank below all code sources, so they never come before an LSP
item.

| Source | Plugin | Score | State |
| --- | --- | --- | --- |
| `dictionary` (English) | [Kaiser-Yang/blink-cmp-dictionary](https://github.com/Kaiser-Yang/blink-cmp-dictionary) | -4 | Always on. |
| `im` (Japanese) | [yehuohan/blink-cmp-im](https://github.com/yehuohan/blink-cmp-im) | -5 | Off until you press `<leader>uj` (normal mode) or `<M-j>` (insert mode). |

## dictionary

The words come from two inputs:

- `$XDG_DATA_HOME/dict/*.txt`, which `run_onchange_after_generate-dictionary`
  writes on apply.
- [`spell/en.utf-8.add`](../../../spell/en.utf-8.add), so a word that you add
  with `zg` completes at once.

The documentation window shows a definition when the machine has `wn`
(WordNet).

## im

You type romaji, and the menu inserts Japanese. The table is
`$XDG_DATA_HOME/dict-ja/skk.txt`, which `run_onchange_after_generate-jisyo`
writes on apply.

- The menu shows the Japanese word first, then the romaji.
- It shows at most 8 items, after at least 3 letters.
- The source is off by default, because romaji such as `no`, `ni` and `to` are
  normal identifiers in code.
- `config.lua` adds the source only if the plugin loads and the table exists.
  A source whose module fails to load breaks the whole menu.

The table is in its own folder, not in `dict/`. The `dictionary` source reads
all `.txt` files in `dict/`, so a table there would join the English words.

[`lua/config/keymaps/blink.lua`](../../config/keymaps/blink.lua) defines the
toggle keys. [`dot_config/nvim/README.md`](../../../README.md) describes the
generators.
