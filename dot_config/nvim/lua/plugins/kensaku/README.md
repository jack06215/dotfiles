# kensaku — romaji → Japanese search

Type romaji, match kana/kanji, no IME switch. [vim-kensaku][] converts the input
into a Vim regex covering every reading:

```
kensaku#query("nihongo")
=> \m\%(nihongo\|にほんご\|ニホンゴ\|日本\%(語\|…\)\|ｎｉｈｏｎｇｏ\|ﾆﾎﾝｺﾞ\)
```

romaji, hiragana, katakana, kanji, full- and half-width — all in one pattern.

## Keymaps

- **`/`, `?`, `:s`, `:g`, `:v`:** `<CR>` — converts automatically, nothing to press
- **Any other command:** `<C-x>` (command-line mode) — expands the romaji before
  the cursor in place

## `/` and `?`

[kensaku-search.vim][] rewrites the command line on `<CR>` before the search
runs, so `/nihongo<CR>` jumps to 日本語.

It only fires when the cmdline type is `/` or `?` **and** the whole line parses
as romaji, so `:` commands are untouched and regex searches keep working —
`/foo.*bar` contains characters no romaji syllable can produce, so it is left
alone rather than being escaped into a literal.

The search history and `@/` end up holding the converted regex, not what you
typed. That's what makes the `:%s//` workflow below work.

## Live highlight while typing

Conversion happens on `<CR>`, so Vim's own `incsearch` only ever sees the
literal romaji — type `nihongo` and 日本語 stays dark until you commit.
`preview.lua` closes that gap: on every keystroke it converts the pattern, puts
it in `@/` with `hlsearch` forced on, and redraws, so the real targets light up
as you type. Applies to `/`, `?`, `:s`, `:g` and `:v` alike.

`@/` is restored on `CmdlineLeave`, which fires *before* the command runs, so
nothing here changes what executes — including `:%s//x/g`, which still sees the
search register you actually had.

`<C-c>` needs care: it fires `CmdlineLeave` but sets the interrupt flag, which
aborts the handler partway and would leave the preview pattern in `@/`
poisoning `n`/`N`. So `leave()` queues a retry *before* attempting the
synchronous restore.

It is a highlight, not a full `incsearch` — the cursor does not jump to the
first match, and `inccommand` still cannot preview `:s` replacement text, since
that would need the converted pattern to be in the command line itself.

Cost is one synchronous `kensaku#query` per keystroke, measured at 0.2–1.2 ms
once denops is warm, so it runs inline rather than async.

## `:s`, `:g`, `:v`

`kensaku-search.vim` replaces the *whole* command line, so it cannot help an ex
command where only the pattern argument may change. `expand_ex()` in
`cmdline.lua` does that instead, on the same `<CR>`:

```vim
:%s/nihongo/hello/gc   " 日本語 -> hello, nothing extra to press
:g/nihongo/d
:v/nihongo/d
```

It rewrites the line in place, so the command stays a real `:s` and keeps its
`inccommand` preview — a wrapper command like `:S/foo/bar/` would lose that.
Ranges (`1,5`, `'<,'>`, `.,+3`), the long forms (`:substitute`, `:global`), `!`,
and alternate delimiters (`:%s#nihongo#x#`) all work.

### What it refuses to touch

Two guards, because `<CR>` runs on every `:` command you ever type:

- **The command must be `:s` / `:g` / `:v`.** A blanket rewrite of `:` lines
  would wreck `:e /home/user` — `home` is valid romaji (`ho` + `me`).
- **The pattern must be pure romaji**, per `g:kensaku_search#pattern`, the same
  guard kensaku-search uses on `/`. So `:%s/foo.*bar/X/` keeps its regex,
  `:%s/function/F/` stays literal, and `:%s//x/g` still reuses `@/`.

### Everything else: `<C-x>`

For pattern-taking commands outside that list, expand by hand:

```vim
:vimgrep /nihongo<C-x>/ **/*.md
" -> :vimgrep /\m\%(nihongo\|にほんご\|日本\%(語\|…\)\)/ **/*.md
```

`<C-x>` swaps the trailing run of `[a-zA-Z-]` before the cursor and leaves the
rest of the line alone. No guard — pressing the key is the intent.

Kensaku output is pure `\m` / `\%(...\)` regex containing no delimiter
character, so it drops between `:s` delimiters without re-escaping.

## Requirements

- [Deno][] on `$PATH` — the denops runtime
- `vim-denops/denops.vim` + `lambdalisue/vim-kensaku`

Both are declared as dependencies here, and again under `flash` and
`fuzzy-motion`; lazy.nvim dedupes them.

If kensaku can't answer (denops still booting, Deno missing), `query.lua`
returns `nil` and each caller falls back — `/` searches literally, `<C-x>` does
nothing, flash matches exactly. Nothing errors.

## Related

- `plugins/flash` — `s` accepts romaji through the same `query.lua`
- `plugins/fuzzy-motion` — `<CR>`, via `g:fuzzy_motion_matchers = { "fzf", "kensaku" }`

[vim-kensaku]: https://github.com/lambdalisue/vim-kensaku
[kensaku-search.vim]: https://github.com/lambdalisue/kensaku-search.vim
[Deno]: https://deno.land
