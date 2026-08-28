# skkeleton — Japanese input (SKK)

A Japanese IME inside the buffer, so composing Japanese needs no OS-level input
method. [skkeleton][] is SKK for nvim; it runs on the same denops kensaku
already loads.

Three things here speak Japanese, and they do different jobs:

| | Key | Job |
|---|---|---|
| `plugins/kensaku` | `/`, `:s` | **Find** Japanese by typing romaji |
| `plugins/blink` (`blink-cmp-im`) | `<leader>uj` | **Complete** a known word from a menu |
| **skkeleton** | `<C-j>` | **Compose** anything, including conjugation |

## The idea: capitals mark boundaries

SKK does not guess where a word starts or ends — you say so, with capital
letters. That is the whole interface.

```
nihongo          -> にほんご          lowercase: straight kana, no conversion
Nihongo<Space>   -> ▽にほんご → ▼日本語   leading capital opens conversion
WakaRimashita    -> 分かりました        second capital marks okurigana
```

The second capital is what a completion menu can never replicate. `WakaRi`
tells SKK the stem is わか and り is inflection, so it looks up `わかr` in the
jisyo's okuri-ari half and conjugates from there. Keep typing `mashita` and it
confirms as you go.

## Keys

Once `<C-j>` is on:

- **`<Space>`** — convert, then cycle to the next candidate
- **`x`** — previous candidate; **`X`** — purge a learned candidate
- **`<CR>`** — confirm. Does *not* also break the line, thanks to
  `eggLikeNewline`; without it, accepting 分かり would drop you onto the next
  line mid-sentence
- **`<C-g>`** — cancel the conversion, keep the kana
- **`q`** — katakana; **`<C-q>`** — half-width katakana; **`/`** — abbrev mode
- **`l`** — back to ASCII (the usual way out)
- **`<Esc>`** — disable and leave insert mode

`<C-j>` is bound in insert and cmdline only. LazyVim uses it in normal mode for
window navigation, and those are the only two modes skkeleton has anything to
say in anyway. Note that inside skkeleton `<C-j>` is `<NL>`, which SKK binds to
*confirm* — so it toggles when idle and confirms mid-conversion, as SKK expects.

## Dictionaries

**Global** — `$XDG_DATA_HOME/dict-ja/SKK-JISYO.utf8`, written at `chezmoi apply`
by `run_onchange_after_generate-jisyo.sh.tmpl`, which also builds the romaji
table `blink-cmp-im` uses. UTF-8, so `globalDictionaries` needs no encoding
argument. If it is missing (offline at apply time) skkeleton still enables, but
converts nothing.

**User** — `~/.config/nvim/skk/user-jisyo`, i.e. **inside this repo**, for the
same reason `spellfile` is (see `config/general.lua`): every conversion you pick
reorders your candidates, and that is hand-earned data worth carrying between
machines rather than relearning on each one. `registerConvertResult` is on so
okuri-ari conversions are remembered too.

> **`chezmoi add` after learning words.** skkeleton writes to the chezmoi
> *target*, so new entries need
> `chezmoi add ~/.config/nvim/skk/user-jisyo` or the next apply reverts them.
> Exactly the same caveat as `zg` and the spell file.

## Statusline

`plugins/lualine` shows あ / ア / ｱ / Ａ while skkeleton is on, reading
`g:skkeleton#enabled` and `g:skkeleton#mode` directly — `skkeleton#is_enabled()`
is only `return g:skkeleton#enabled`, and a statusline component runs on every
redraw. The in-buffer ▽/▼ markers show a conversion in progress; this shows the
mode you are about to type *into*.

## blink is suppressed while composing

`skkeleton-enable-pre` sets `vim.b.completion = false`,
`skkeleton-disable-post` clears it back to `nil` (restoring the default rather
than pinning completion on). Both want the keys during conversion and blink
wins ties, so leaving it on means `<CR>` accepts a completion instead of the
candidate under ▼.

`vim.b.completion` is blink's own per-buffer switch, not a custom flag —
see `blink/cmp/config/init.lua`.

## Not lazy-loaded, deliberately

denops discovers `denops/*/main.ts` by scanning the runtimepath **when it
starts**. A plugin added to the runtimepath afterwards — which is exactly what
lazy-loading on `InsertEnter` does — is never registered, and
`skkeleton#handle('enable')` then waits forever on a plugin denops does not
know about. That presents as **the cursor freezing on the first `<C-j>`, with
no error message**.

`denops#plugin#is_loaded('skkeleton')` is the diagnostic: `0` means denops
never saw it, no matter that it is on the runtimepath.

kensaku avoids the same trap for a related reason, and `config/lazy.lua` sets
`defaults = { lazy = false }` — eager is the house default here.

## Requirements

- [Deno][] on `$PATH` — the denops runtime (`brew-formula-*.txt`)
- `vim-denops/denops.vim`, declared here and again under `kensaku`, `flash` and
  `fuzzy-motion`; lazy.nvim dedupes it

## Related

- `plugins/kensaku` — the same romaji→Japanese direction, for searching
- `plugins/blink` — `blink-cmp-im`, romaji→word completion. Covers nouns and
  compounds; anything inflected is skkeleton's job, because SKK stores verb and
  adjective stems as okuri-ari entries and the jisyo cannot even distinguish
  godan from ichidan (分かる and 食べる are both `…r`)

[skkeleton]: https://github.com/vim-skk/skkeleton
[Deno]: https://deno.land
