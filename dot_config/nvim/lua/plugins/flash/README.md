# Flash.nvim

## Keymaps

- **Flash:** `s` (normal, visual, operator-pending modes)
- **Flash Treesitter:** `S` (normal, visual, operator-pending modes)
- **Remote Flash:** `r` (operator-pending mode)
- **Flash Treesitter Search:** `R` (visual, operator-pending modes)
- **Toggle Flash Search:** `<c-s>` (command-line mode)

## Japanese search (romaji → kana/kanji)

`search.mode` is wired to [vim-kensaku][] through `kensaku.lua`, so flash targets
Japanese text by typing romaji — no IME switch.

Press `s`, type `nihongo`, and 日本語 gets a jump label. Internally kensaku
expands the input into a Vim regex covering every reading:

```
kensaku#query("nihongo")
=> \m\%(nihongo\|にほんご\|ニホンゴ\|日本\%(語\|…\)\|ｎｉｈｏｎｇｏ\|ﾆﾎﾝｺﾞ\)
```

That covers romaji, hiragana, katakana, kanji, and full-/half-width forms.

**This is always on, and safe.** The raw input stays in the alternation, so the
pattern is a strict superset of flash's default `exact` mode — `s` + `hello`
still matches `hello`. If kensaku can't answer (denops still booting, Deno
missing), `kensaku.lua` falls back to exact matching rather than erroring.

Applies to every flash entry point that searches, so `S` / `r` / `R` accept
romaji too.

### Requirements

- [Deno][] on `$PATH` — the denops runtime
- `vim-denops/denops.vim` + `lambdalisue/vim-kensaku`, declared as flash
  `dependencies` in `config.lua`

They're listed as flash dependencies rather than left lazy so the Deno process is
already running when you first press `s`. Otherwise `kensaku#query` blocks on
`denops#plugin#wait()` and the first search stalls for a second or two. The same
two plugins also back `fuzzy-motion` (`<CR>`).

### Turning it off

Drop the `search.mode` line from `config.lua` to return to `exact`. To keep it
off by default but available on a dedicated key, leave `search.mode` unset and
pass it per-invocation instead:

```lua
require("flash").jump({ search = { mode = require("plugins.flash.kensaku").mode } })
```

[vim-kensaku]: https://github.com/lambdalisue/vim-kensaku
[Deno]: https://deno.land
