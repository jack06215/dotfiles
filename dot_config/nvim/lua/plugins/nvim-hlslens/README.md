# nvim-hlslens

[kevinhwang91/nvim-hlslens](https://github.com/kevinhwang91/nvim-hlslens)
shows virtual text next to each search match. After `/needle` and one `n`,
with the cursor on the third match:

```
    needle one                                    [2N 1]
    needle two                                    [N 2]
    needle three                                  [3/4]
    needle four                                   [n 4]
```

The match under the cursor shows `[index/total]`. Each other match shows the
keys that go to it (`2N`, `N`, `n`) and its index. You read the motion from the
screen, and you do not count.

## Keys

| Key | Mode | Action |
| --- | --- | --- |
| `n`, `N` | normal, visual | Next or previous match, then show the lens. |
| `*`, `#` | normal | Search for the word under the cursor, then show the lens. |
| `g*`, `g#` | normal | The same, without word boundaries. |
| `<leader>uH` | normal | Turn the lens on or off (`:HlSearchLensToggle`). |
| `<leader>xs` | normal | Put all matches of the last search in the quickfix list. |
| `<leader>ur` | normal | Clear the highlight, and with it the lens. |

`/` and `?` need no key. `auto_enable` uses the `CmdlineLeave` event, so the
lens shows when the search ends.

The keys are in
[`lua/config/keymaps/nvim-hlslens.lua`](../../config/keymaps/nvim-hlslens.lua),
not in a `keys` block. `n` and `N` are LazyVim keys. lazy.nvim makes the
`keys` stubs before which-key applies the LazyVim keys, so which-key would
replace a `keys` entry. The plugin loads on `VeryLazy`, because `auto_enable`
must be ready before the first `/`.

## How the n and N keys work

LazyVim binds `n` to `'Nn'[v:searchforward] . 'zv'`:

- `v:searchforward` is 1 after `/` and 0 after `?`. Thus `n` always goes down
  the buffer, also after a backward search.
- `zv` opens a fold that contains the match.

The `n` and `N` keys keep this expression and add the `start()` call of
hlslens. The snippet in the hlslens README would lose both features.

```lua
local function with_lens(expr)
  return function()
    return vim.fn.eval(expr) .. "<Cmd>lua require('hlslens').start()<CR>"
  end
end

local next_key = "'Nn'[v:searchforward]"
map("n", "n", with_lens(next_key .. " . 'zv'"), { expr = true })
```

The argument of `with_lens` is Vimscript. The right side given to
`vim.keymap.set` must be a Lua function.

> [!IMPORTANT]
> A `<Cmd>…<CR>` in the result of a Vimscript `expr` mapping does not run.
> Neovim drops it and shows no error. Other key codes, for example `<Esc>`,
> still work. The same string from a Lua function runs as expected.
>
> `auto_enable` hides this problem. `/foo` shows the lens through the command
> line events. `<Esc>` runs `:noh` and stops the lens. After that, `n` moves
> the cursor and highlights the match, but shows no lens, because `start()`
> never ran. `:lua = require("hlslens.render").status` shows the state: `2` is
> on, `1` is off.

More notes:

- A typed count (`3n`) applies to the motion.
- Visual mode does not add `zv`, as in LazyVim.
- Keep the expression in the `next_key` variable. `[['Nn'[v:searchforward]]]`
  as a Lua long string ends at the first `]]`, so Lua cannot parse it.
- Operator-pending `n` and `N` (`dn`, `cN`) keep the LazyVim key. The
  `<Cmd>` would run after the operator used the motion, and a lens is not
  worth the risk of an unexpected edit.

## Romaji search with kensaku

[`../kensaku/`](../kensaku/) changes romaji to a Japanese regex at `<CR>`.
Before that, `kensaku/preview.lua` writes the converted pattern into `@/` while
you type, for a live highlight.

`enable_incsearch` counts the raw command line (`getcmdline()`). During a
romaji search, the command line is still `nihongo`. Thus while you type, the
count is for the romaji, not for the 日本語 that the preview highlights. At
`<CR>`, the converted pattern goes into `@/`, and the count is correct again.

This affects only Japanese searches, and only the count that the lens shows.
To stop it, set
`enable_incsearch = false` in [`config.lua`](config.lua). ASCII searches are
not affected.

## Settings

The settings are in [`config.lua`](config.lua). `:h hlslens-config` lists all
options.

| Option | Value | Effect |
| --- | --- | --- |
| `calm_down` | `false` | The highlight stays until `<leader>ur` clears it. In this config, `<C-l>` moves between windows, so it does not clear the highlight. With `true`, the highlight goes when the cursor leaves a match. |
| `nearest_only` | `false` | A lens on each visible match. `true` shows a lens only on the match under the cursor. |
| `nearest_float_when` | `"auto"` | The lens under the cursor moves into a float when the right edge of the window would cut it. `"never"` keeps it in the line. |

The highlight groups are `HlSearchLens` for the other matches and
`HlSearchLensNear` for the match under the cursor. Both link to `Comment` by
default.

## flash

[`../flash/`](../flash/) sets `modes.search.enabled = false`, so flash does not
attach to `/`. The two plugins use different keys: `s` jumps to a label, and
`n` counts search results.
