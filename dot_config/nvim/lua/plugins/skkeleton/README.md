# skkeleton

[vim-skk/skkeleton](https://github.com/vim-skk/skkeleton) is SKK for Neovim: a
Japanese input method in the buffer. You do not need the input method of the
OS. It runs on the same denops that kensaku already loads.

Three parts of this config work with Japanese, and each has a different job:

| Plugin | Key | Job |
| --- | --- | --- |
| [`../kensaku/`](../kensaku/) | `/`, `:s` | **Find** Japanese text with romaji. |
| [`../blink/`](../blink/) (`blink-cmp-im`) | `<leader>uj` | **Complete** a known word from a menu. |
| skkeleton | `<C-j>` | **Write** any text, including conjugated forms. |

## Capitals mark the boundaries

SKK does not guess where a word starts or ends. You show it with capital
letters. That is the whole interface.

```
nihongo          -> にほんご              lowercase: kana only, no conversion
Nihongo<Space>   -> ▽にほんご → ▼日本語    a first capital starts a conversion
WakaRimashita    -> 分かりました           a second capital marks the okurigana
```

A completion menu cannot do what the second capital does. `WakaRi` tells SKK
that the stem is わか and that り is inflection. SKK looks up `わかr` in the
okuri-ari part of the jisyo and conjugates from there. Continue to type
`mashita`, and SKK confirms as you go.

## Keys

After `<C-j>`:

| Key | Action |
| --- | --- |
| `<Space>` | Convert, then go to the next candidate. |
| `x` | Go to the previous candidate. |
| `X` | Delete a learned candidate. |
| `<CR>` | Confirm. It does not also start a new line (`eggLikeNewline`). |
| `<C-g>` | Cancel the conversion, and keep the kana. |
| `q` | Katakana. |
| `<C-q>` | Half-width katakana. |
| `/` | Abbreviation mode. |
| `l` | Back to ASCII. This is the usual way out. |
| `<Esc>` | Turn skkeleton off and leave insert mode. |

`<C-j>` works in insert mode and on the command line only. LazyVim uses
`<C-j>` in normal mode to move between windows, and skkeleton has no job in
other modes. In skkeleton, `<C-j>` is `<NL>`, which SKK binds to confirm. Thus
`<C-j>` toggles skkeleton when no conversion is open, and confirms during a
conversion, as SKK expects.

## Dictionaries

- **Global:** `$XDG_DATA_HOME/dict-ja/SKK-JISYO.utf8`. The jisyo generator
  writes it on apply, as described in
  [`dot_config/nvim/README.md`](../../../README.md#japanese-input). The file is
  UTF-8, so `globalDictionaries` needs no encoding. If the file is missing,
  for example after an apply with no network, skkeleton starts but converts
  nothing.
- **User:** `~/.config/nvim/skk/user-jisyo`, which is in this repository,
  for the same reason as the spell file. Each conversion that you select
  changes the order of your candidates. That data takes time to build, so it
  goes to all machines. `registerConvertResult` is on, so skkeleton also learns
  okuri-ari conversions.

> [!IMPORTANT]
> skkeleton writes the user jisyo to the chezmoi target. After it learns new
> words, run `chezmoi add ~/.config/nvim/skk/user-jisyo`. If you do not, the
> next `chezmoi apply` reports that the file changed, and if you let it
> overwrite the file, the new words are lost.

## Status line

[`../lualine/`](../lualine/) shows あ, ア, ｱ or Ａ while skkeleton is on. It
reads `g:skkeleton#enabled` and `g:skkeleton#mode` directly.
`skkeleton#is_enabled()` only returns `g:skkeleton#enabled`, and a status line
item runs at each redraw. The `▽` and `▼` markers in the buffer show a
conversion in progress. The status line shows the mode for the next key.

## blink is off while you compose

`skkeleton-enable-pre` sets `vim.b.completion = false`, and
`skkeleton-disable-post` sets it back to `nil`. `nil` restores the default and
does not force completion on. Both plugins want the keys during a conversion,
and blink wins a tie. If blink stayed on, `<CR>` would accept a completion, not
the candidate under `▼`.

`vim.b.completion` is the per-buffer switch of blink itself, not a custom flag.
See `blink/cmp/config/init.lua` in blink.cmp.

## Not lazy-loaded

denops finds `denops/*/main.ts` when it starts, by a scan of the runtimepath.
It does not register a plugin that joins the runtimepath later, and that is
what lazy-loading on `InsertEnter` does. `skkeleton#handle('enable')` then
waits for a plugin that denops does not know. You see this as a cursor that
freezes at the first `<C-j>`, with no error message.

To diagnose it, run `denops#plugin#is_loaded('skkeleton')`. `0` means that denops
did not find the plugin, even when it is on the runtimepath.

kensaku is not lazy-loaded either, and `lua/config/lazy.lua` sets
`defaults = { lazy = false }`.

## Requirements

- [Deno](https://deno.land) on `$PATH`, for denops. The brewfiles install it.
- `vim-denops/denops.vim`. It is a dependency here, and also of `kensaku`,
  `flash` and `fuzzy-motion`. lazy.nvim installs it one time.

## Related

- [`../kensaku/`](../kensaku/): the same direction, romaji to Japanese, for
  search.
- [`../blink/`](../blink/): `blink-cmp-im` completes words from romaji. It
  covers nouns and compounds. Conjugated forms need skkeleton. SKK keeps verb
  and adjective stems as okuri-ari entries. The jisyo also cannot tell godan
  verbs from ichidan verbs (分かる and 食べる are both `…r`).
