# flash

[folke/flash.nvim](https://github.com/folke/flash.nvim) jumps to any place on
the screen: type a few characters, then the label of the target.

| Key | Mode | Action |
| --- | --- | --- |
| `s` | normal, visual, operator-pending | Jump. |
| `S` | normal, visual, operator-pending | Select a tree-sitter node. |
| `r` | operator-pending | Remote flash: run the operator at a target, then come back. |
| `R` | visual, operator-pending | Tree-sitter search. |
| `<c-s>` | command line | Turn flash on or off in a `/` search. |

- A jump goes into the jump list, so `<C-o>` returns.
- Labels are lowercase, with rainbow colors.
- flash does not change `/` search or `f`/`t`. Those modes are off.

## Japanese search

`search.mode` is the function in [`kensaku.lua`](kensaku.lua). It uses
[vim-kensaku](https://github.com/lambdalisue/vim-kensaku) to make a Vim regex
from romaji. Press `s`, type `nihongo`, and 日本語 gets a label.

```
kensaku#query("nihongo")
=> \m\%(nihongo\|にほんご\|ニホンゴ\|日本\%(語\|…\)\|ｎｉｈｏｎｇｏ\|ﾆﾎﾝｺﾞ\)
```

The pattern covers romaji, hiragana, katakana, kanji, and the full-width and
half-width forms. It also contains the raw input, so `s` then `hello` still
finds `hello`. Thus the mode is safe to keep on. All flash keys that search
use it.

When kensaku does not answer, `kensaku.lua` uses the exact match of flash. That
happens while denops starts, when Deno is not installed, or when the plugin is
not loaded. [`../kensaku/`](../kensaku/) uses the same query for `/` and `:s`.

### Requirements

- [Deno](https://deno.land) on `$PATH`, for denops.
- `vim-denops/denops.vim` and `lambdalisue/vim-kensaku`. They are dependencies
  of flash, so the Deno process already runs when you first press `s`. If it
  did not, the first search would wait for denops to start.

### Turn it off

To go back to the exact match, delete the `search.mode` line in
[`config.lua`](config.lua). To use romaji search on one key only, leave
`search.mode` out and give the mode to that key:

```lua
require("flash").jump({ search = { mode = require("plugins.flash.kensaku").mode } })
```
