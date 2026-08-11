# Hardtime.nvim

Breaks bad Vim habits by rate-limiting or blocking low-value keys, and hinting a
better command when one exists. This config runs in **strict mode** — it is
tuned to push past the intermediate plateau, not to be gentle.

## How it works

Hardtime watches recent keystrokes and reacts in three ways:

- **`restricted_keys`** — allowed up to `max_count` times within `max_time`, then
  blocked. Rate-limiting, not banning: one or two `j` presses are fine, spamming
  is not.
- **`disabled_keys`** — blocked outright, always. Arrow keys come from the
  plugin defaults.
- **`hints`** — Lua patterns matched against recent keys. Non-blocking; they just
  tell you the shorter command you should have typed.

User options are merged into the plugin defaults with `vim.tbl_deep_extend`, so
everything in `config.lua` **adds to** the built-in tables rather than replacing
them. There are 38 default hints; this config adds 6 more.

## Settings

```lua
disable_mouse = true          -- no mouse escape hatch
allow_different_key = false   -- alternating hjkl still counts toward the limit
max_time = 800                -- window (ms) for counting repeats
max_count = 3                 -- repeats allowed inside that window
force_exit_insert_mode = true -- drop to normal mode after idling
max_insert_idle_ms = 10000    -- ...for 10 seconds
```

- **`allow_different_key = false`** is what makes this strict. With the default
  `true`, alternating `jkjkjk` resets the counter and dodges the limit entirely.
- **`force_exit_insert_mode`** targets *insert-mode camping* — sitting in insert
  mode while thinking or reading. Normal mode is the resting state; insert mode
  is a short trip you take to type a thing. Expect this one to feel hostile for
  about two days. If it interrupts genuine mid-line thinking, raise
  `max_insert_idle_ms` rather than turning the flag off.

## Restricted keys and why

| Keys | Habit it breaks | Reach for instead |
| --- | --- | --- |
| `h` `j` `k` `l` | Walking to a target one cell at a time | Relative jumps (`12j`), `f`/`t`, `s` (flash), `%`, `H`/`M`/`L` |
| `+` `-` | Same, line-wise | Counts, `{`/`}`, `[[`/`]]` |
| `gj` `gk` | Same, on display lines | `g0`/`g$`, or a real motion |
| `<Up>` `<Down>` `<Left>` `<Right>` | Leaving the home row | Blocked outright by plugin defaults, in normal **and** insert mode |

Note that arrow keys need no entry in `restricted_keys` — they are already in the
plugin's default `disabled_keys`, which is the stronger restriction.

### Phase 2 (commented out in `config.lua`)

`w`, `b`, `e`, `x` are staged but disabled. Turning them on forces `f`/`t`/flash
for intra-line movement and `ciw`/`de` over character-nibbling. **Do not enable
these until `f`/`t`/`s` are automatic** — otherwise editing just becomes painful
without teaching anything.

## Custom hints and why

| Pattern | Fires on | Suggests | The habit |
| --- | --- | --- | --- |
| `0i` | `0i` | `I` | The default config only catches `^i`; `0i` is the same mistake |
| `xi` | `xi` | `s` | `s` is "substitute char" — one key, and it dot-repeats cleanly |
| `ggVG` | `ggVG` | `yag` / `dag` / `=ag` | Whole-buffer text object (from `mini.ai`) beats a visual selection |
| `gg=G` | `gg=G` | `=ag` | Same, for the reindent case specifically |
| `v[ia]%a[dcy]` | `viwd`, `vipy`, `vifc` | `diw`, `yip`, `cif` | Operator + text object directly; visual mode is a detour that breaks `.` |
| `v[ia]%p[dcy]` | `vi"d`, `va(y` | `di"`, `ya(` | Same, for punctuation text objects |

The theme behind the last two: **visual mode is for when you need to see the
selection first.** When you already know what you're targeting, `d` + text object
is fewer keys and — critically — stays repeatable with `.`.

## The habit curriculum

These are the habits this config is trying to build, in the order worth learning
them. Everything below is already available in this Neovim setup.

### Tier 1 — the plateau breakers

- **`cgn` + `.`** — the biggest single unlock. `*` on a word, then `cgn`, type the
  replacement, then `.` `.` `.` for each subsequent match. Replaces most
  `:%s///gc` usage and keeps per-site judgment. Learn this one first.
- **`g;` / `g,`** — walk backward/forward through the changelist. One keystroke to
  get back to "where I was just editing", instead of searching or scrolling.
- **Treesitter text objects** (via `mini.ai`, already installed) — `daf` delete a
  function, `cio` change inner conditional/loop/block, `cia` an argument, `ac`/`ic`
  a class, `ie`/`ae` a camelCase segment, `ag`/`ig` the whole buffer.
- **`:g` (global command)** — `:g/console\.log/d`, `:g/pat/norm A;`, `:v/keep/d`.
  One command doing what a macro takes fifty keystrokes to do.
- **Registers** — `"0p` (the yank register, unclobbered by deletes), `<C-r>0` in
  insert mode, `"ay` for named stashes, `<C-r>=` for inline arithmetic.

### Tier 2 — build next

- **`H` / `M` / `L`, `zt` / `zz` / `zb`** — viewport-relative positioning. With
  `j`/`k` restricted, this is the main escape hatch.
- **Marks** — `mA` (uppercase = cross-file), `` `a `` to return exactly,
  `` `` `` for the last jump, `` `. `` for the last change.
- **Flash `r` and `R` in operator-pending mode** — already bound, rarely used.
  `yr<label>iw` yanks a word from elsewhere on screen without moving the cursor.
- **Insert-mode motions** — `<C-w>` delete word back, `<C-u>` delete to line start,
  `<C-o>` for a single normal-mode command. Stop leaving insert mode to fix a
  typo three characters back.
- **Visual block** — `<C-v>` then `I` / `A` / `$A` for column edits without a macro.

### Tier 3 — polish

`gi` (resume insert where you left off), `gv` (reselect), `<C-^>` (alternate
file), `]q` / `[q` for quickfix, `:cdo` for project-wide edits driven by a
quickfix list.

## Escape hatches

```vim
:Hardtime disable   " turn off for this session
:Hardtime enable
:Hardtime toggle
:Hardtime report    " what you've been getting wrong, ranked
```

`:Hardtime report` is worth checking weekly — it shows which restricted keys you
actually hit, which tells you what to drill next.

Hardtime is also off automatically in the filetypes listed in `config.lua`
(file trees, `lazy`, `mason`, quickfix, help, Diffview, Neogit, dapui, …), in
terminal buffers, and while recording or executing a macro.

> **Note:** `disabled_buftypes` is *not* a hardtime option — terminal buftypes are
> handled internally by the plugin, and `prompt` is covered by
> `disabled_filetypes`. Setting it does nothing.
