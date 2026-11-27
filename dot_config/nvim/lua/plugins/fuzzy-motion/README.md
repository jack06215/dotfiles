# fuzzy-motion

[yuki-yano/fuzzy-motion.vim](https://github.com/yuki-yano/fuzzy-motion.vim)
jumps to a word on the screen: type part of the word, then select its label.
It runs on denops.

`g:fuzzy_motion_matchers` is `{ "fzf", "kensaku" }`. Thus romaji also matches
Japanese text, through [kensaku](../kensaku/README.md).

## Key

Press `<CR>` in normal or visual mode. [`keymaps.lua`](keymaps.lua) defines the
key, and [`config.lua`](config.lua) adds it to the spec. The plugin loads at
the first `<CR>` or `:FuzzyMotion`.

In a buffer that has a `buftype`, `<CR>` keeps its normal job. Thus `<CR>`
still opens an entry in a quickfix window, a help link or a line in the
command-line window. A global `<CR>` mapping would replace the built-in key in
those buffers too.
