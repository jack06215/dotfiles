# kensaku

Search Japanese text with romaji. You do not need to change the input method.
[vim-kensaku](https://github.com/lambdalisue/vim-kensaku) changes the input
into a Vim regex that matches each reading:

```
kensaku#query("nihongo")
=> \m\%(nihongo\|にほんご\|ニホンゴ\|日本\%(語\|…\)\|ｎｉｈｏｎｇｏ\|ﾆﾎﾝｺﾞ\)
```

The pattern covers romaji, hiragana, katakana, kanji, and the full-width and
half-width forms.

## Keys

| Command | Key | Effect |
| --- | --- | --- |
| `/`, `?`, `:s`, `:g`, `:v` | `<CR>` | Converts the romaji. You press nothing more. |
| All other commands | `<C-x>` (command-line mode) | Converts the romaji before the cursor, in the line. |

## / and ?

[kensaku-search.vim](https://github.com/lambdalisue/kensaku-search.vim)
changes the command line at `<CR>`, before the search runs. Thus
`/nihongo<CR>` goes to 日本語.

It acts only when two conditions are true:

- The command-line type is `/` or `?`. A `:` command does not change.
- The whole line is romaji. `/foo.*bar` has characters that no romaji
  syllable makes, so the search stays a regex.

The search history and `@/` keep the converted regex, not the text that you
typed. Because of this, the `:%s//` workflow below works.

## Live highlight while you type

The conversion happens at `<CR>`. Before that, the Vim `incsearch` sees only
the romaji, so 日本語 stays dark while you type `nihongo`.
[`preview.lua`](preview.lua) closes that gap. At each key, it converts the
pattern, puts it in `@/`, turns `hlsearch` on, and redraws. The real targets
show while you type. This works for `/`, `?`, `:s`, `:g` and `:v`.

- `preview.lua` puts the old `@/` back at `CmdlineLeave`. That event comes
  before the command runs, so the preview does not change what runs. For
  example, `:%s//x/g` still uses your real search register.
- `<C-c>` sends `CmdlineLeave`, but it also sets the interrupt flag. The flag
  stops the handler before it ends, so the preview pattern would stay in `@/`
  and change `n` and `N`. Thus `leave()` schedules a second try before it
  restores `@/`.
- It is a highlight only. The cursor does not jump to the first match, and
  `inccommand` cannot show the `:s` replacement. That would need the converted
  pattern in the command line itself.
- Each key runs one synchronous `kensaku#query`. The query is fast once denops
  runs, so the preview runs inline, not async.

## :s, :g and :v

`kensaku-search.vim` replaces the whole command line, so it cannot help with an
Ex command where only the pattern can change. `expand_ex()` in
[`cmdline.lua`](cmdline.lua) does that job, on the same `<CR>`:

```vim
:%s/nihongo/hello/gc   " 日本語 -> hello, nothing more to press
:g/nihongo/d
:v/nihongo/d
```

It changes the line in place, so the command stays a real `:s` with its
`inccommand` preview. A wrapper command such as `:S/foo/bar/` would lose the
preview. These forms all work:

- ranges: `1,5`, `'<,'>`, `.,+3`
- long names: `:substitute`, `:global`
- `!`
- other delimiters: `:%s#nihongo#x#`

### Guards

`<CR>` runs for each `:` command, so `expand_ex()` has two guards:

- **The command must be `:s`, `:g` or `:v`.** A rewrite of all `:` lines would
  break `:e /home/user`, because `home` is valid romaji (`ho` + `me`).
- **The pattern must be only romaji**, as `g:kensaku_search#pattern` defines.
  kensaku-search uses the same guard on `/`. Thus `:%s/foo.*bar/X/` keeps its
  regex, `:%s/function/F/` stays literal, and `:%s//x/g` still uses `@/`.

### All other commands: <C-x>

For other commands that take a pattern, convert by hand:

```vim
:vimgrep /nihongo<C-x>/ **/*.md
" -> :vimgrep /\m\%(nihongo\|にほんご\|日本\%(語\|…\)\)/ **/*.md
```

`<C-x>` replaces the `[a-zA-Z-]` characters just before the cursor, and does
not change the rest of the line. It has no guard, because you press the key on
purpose.

The kensaku output is a `\m` regex with `\%(...\)` groups, and it contains no
delimiter character. Thus it goes between `:s` delimiters with no extra escape.

## Requirements

- [Deno](https://deno.land) on `$PATH`, for denops.
- `vim-denops/denops.vim` and `lambdalisue/vim-kensaku`.

These two plugins are dependencies here, and also of `flash` and
`fuzzy-motion`. lazy.nvim installs each plugin one time.

The plugin loads at start, not on a key. The mapping is in command-line mode,
where lazy.nvim cannot replay a key reliably, and the `<Plug>` mapping must
exist first.

When kensaku cannot answer (denops still starts, or Deno is missing),
[`query.lua`](query.lua) returns `nil`. Each caller then uses its fallback:
`/` searches the literal text, `<C-x>` does nothing, and flash uses the exact
match. No error shows.

## Related

- [`../flash/`](../flash/): `s` accepts romaji, through the same
  `query.lua`.
- [`../fuzzy-motion/`](../fuzzy-motion/): `<CR>` in normal mode, with
  `g:fuzzy_motion_matchers = { "fzf", "kensaku" }`.
