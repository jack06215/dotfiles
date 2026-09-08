# nvim-hlslens

Virtual text next to each search match saying where you are in the results.
After `/needle` and one `n`, with the cursor on the third match:

```
    needle one                                    [2N 1]
    needle two                                    [N 2]
    needle three                                  [3/4]
    needle four                                   [n 4]
```

The match under the cursor gets `[idx/total]`. Every other one gets **the keys
that would take you there** — `2N`, `N`, `n` — next to its index, so you read
the motion off the screen instead of counting. Replaces squinting at
`searchcount()` in the statusline.

## Keymaps

| Key                | Mode | Action                                     |
| ------------------ | ---- | ------------------------------------------ |
| `n` / `N`          | n, x | Next / previous match, then attach the lens |
| `*` / `#`          | n    | Search word under cursor, then attach       |
| `g*` / `g#`        | n    | Same, without word boundaries               |
| `<leader>uH`       | n    | Toggle the lens (`:HlSearchLensToggle`)     |
| `<leader>xs`       | n    | Export all matches to the quickfix list     |
| `<leader>ur`       | n    | Clear the highlight — the lens goes with it |

`/` and `?` need no keymap: `auto_enable` hooks `CmdlineLeave`, so the lens is
already there when the search lands.

The keymaps live in `config/keymaps/nvim-hlslens.lua`, not in a `keys` block
here. `n` and `N` are LazyVim defaults, and lazy.nvim installs `keys` stubs
*before* which-key applies the baseline spec — so a `keys` entry would be
silently overwritten. Same reason `config/keymaps/telescope.lua` exists.

### Why the n/N mappings look the way they do

hlslens's README suggests:

```lua
[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]]
```

That would quietly drop two things LazyVim gives us:

- **`'Nn'[v:searchforward]`** — vim-galore's "saner n/N". `v:searchforward` is
  `1` after `/` and `0` after `?`, so indexing that pair keeps `n` meaning
  "down the buffer" even when the last search ran backwards. A plain
  `normal! n` reverses after `?`.
- **`zv`** — opens a fold the match landed inside. Without it `n` parks the
  cursor on a closed fold.

So the mappings stay `expr`, evaluate LazyVim's own expression, and append the
`start()` call:

```lua
local function with_lens(expr)
  return function()
    return vim.fn.eval(expr) .. "<Cmd>lua require('hlslens').start()<CR>"
  end
end

map("n", "n", with_lens("'Nn'[v:searchforward] . 'zv'"), { expr = true })
```

The argument to `with_lens` is **Vimscript, not Lua** — it is what LazyVim puts
in the rhs — but the rhs handed to `vim.keymap.set` is a **Lua function**, and
that part is load-bearing.

> ### `<Cmd>` does not survive a Vimscript `expr` rhs
>
> The obvious version of this helper returns the Vim expression itself:
>
> ```lua
> local function with_lens(expr) -- broken
>   return expr .. [[ . "<Cmd>lua require('hlslens').start()<CR>"]]
> end
> ```
>
> `vim.keymap.set` does default `replace_keycodes = true` for `expr` mappings,
> and `maparg('n', 'n', 0, 1).replace_keycodes` duly reports `1` — but on
> Neovim 0.12 the `<Cmd>…<CR>` in the result of a **Vimscript-string** `expr`
> rhs never executes. It is not typed literally either; it is just dropped, with
> no error. Ordinary keycodes are unaffected: an `<Esc>` in the same position
> is translated and does leave insert mode. Returning the byte-identical string
> from a **Lua function** runs the command as expected, which is why the helper
> is shaped the way it is.
>
> `auto_enable` makes this look like an hlslens bug rather than a mapping bug:
> `/foo` shows the lens (the cmdline hooks start the renderer), `<Esc>` runs
> LazyVim's `:noh`, which stops it — and every `n` after that moves the cursor
> and highlights the match with no lens attached, because `start()` was never
> called. `:lua = require("hlslens.render").status` tells them apart: `2` is
> running, `1` is stopped.

A typed count (`3n`) still applies to the leading motion either way.

> Do not inline these as `[['Nn'[v:searchforward]]]`. Lua closes a long string
> at the *first* `]]`, so that reads as `'Nn'[v:searchforward` plus a stray `]`
> and fails to parse. Hence the helper.

Operator-pending `n`/`N` (`dn`, `cN`) is left on the plain LazyVim mapping. The
trailing `<Cmd>` would run *after* the operator had already consumed the
motion, and a lens is not worth risking a surprising edit.

## Interaction with the kensaku romaji search

`plugins/kensaku` converts romaji to a Japanese-matching regex on `<CR>`, and
`plugins/kensaku/preview.lua` fakes a live highlight before that by writing the
converted pattern into `@/` while you type.

hlslens's `enable_incsearch` reads the **raw command line** (`getcmdline()`),
which during a romaji search is still `nihongo` — so while you type, its count
describes the literal romaji, not the 日本語 that kensaku's preview is already
highlighting. Both agree again on `<CR>`, once the converted pattern lands in
`@/` and hlslens re-counts.

Cosmetic, and only for Japanese searches. If the mismatch while typing is more
annoying than the live count is useful, turn it off in `config.lua`:

```lua
enable_incsearch = false,
```

ASCII searches are unaffected — the cmdline and `@/` agree the whole way.

## Options worth knowing

Set in `config.lua`; full list in `:h hlslens-config`.

- **`calm_down = false`** — the highlight stays until `<leader>ur` clears it
  (LazyVim's "Redraw / Clear hlsearch"; note `<C-l>` is window-nav here, not
  `:nohlsearch`). Set `true` and the highlight drops by itself the moment the
  cursor leaves a match.
- **`nearest_only = false`** — lens on every visible match. `true` shows only
  the one under the cursor, which is quieter on a dense file.
- **`nearest_float_when = "auto"`** — the nearest lens moves into a small float
  when the virtual text would be pushed off the right edge. `"never"` keeps it
  inline and lets it get clipped.

Highlight groups are `HlSearchLens` (the `[2N 1]`-style lenses) and
`HlSearchLensNear` (the `[idx/total]` under the cursor), both linked to
`Comment` by default.

## Doesn't conflict with flash

`plugins/flash` sets `modes.search.enabled = false`, so flash never attaches to
`/`. The two stay on separate keys: `s` labels jump targets, `n` counts search
results.
