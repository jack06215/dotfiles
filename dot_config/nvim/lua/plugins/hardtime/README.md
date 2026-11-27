# hardtime

[m4xshen/hardtime.nvim](https://github.com/m4xshen/hardtime.nvim) breaks
inefficient Vim habits. It limits or blocks keys with low value, and it
suggests a better command when one exists. This config uses a strict setup,
to get past the intermediate level.

## How it works

hardtime watches the recent keys and acts in three ways:

- **`restricted_keys`**: you can press the key up to `max_count` times in
  `max_time`. After that, hardtime blocks it. One or two `j` presses are
  acceptable. A long series is not.
- **`disabled_keys`**: hardtime always blocks these keys. The arrow keys come
  from the plugin defaults.
- **`hints`**: Lua patterns that hardtime compares with the recent keys. A hint
  does not block. It shows the shorter command.

hardtime merges the options with its defaults through `vim.tbl_deep_extend`.
Thus each table in [`config.lua`](config.lua) adds to the built-in table, and
does not replace it. This config adds 6 hints.

## Settings

```lua
disable_mouse = true          -- no mouse
allow_different_key = false   -- jkjk also counts toward the limit
max_time = 800                -- time window in ms for the count
max_count = 3                 -- presses allowed in that window
force_exit_insert_mode = true -- go back to normal mode when idle
max_insert_idle_ms = 10000    -- after 10 seconds
```

- **`allow_different_key = false`** makes the setup strict. With the default
  `true`, a change of key (`jkjkjk`) resets the count, and the limit never
  applies.
- **`force_exit_insert_mode`** stops you from staying in insert mode while you
  think or read. Normal mode is the rest state. Insert mode is a short visit
  to type text. Expect this setting to feel bad for about two days. If it
  interrupts real thought in the middle of a line, increase
  `max_insert_idle_ms`. Do not turn the setting off.

## vscode-neovim

The plugin also loads in vscode-neovim (`vscode = true`), because normal-mode
keys reach Neovim there. Three settings change in VS Code:

- `disable_mouse` is off, because VS Code controls the mouse.
- `force_exit_insert_mode` is off. VS Code does the typing in insert mode, and
  Neovim does not see it. Thus each insert would look idle, and hardtime would
  stop it in the middle of a sentence.
- A hint goes to the VS Code status bar, not to a notification.

## Restricted keys

| Keys | Habit | Use instead |
| --- | --- | --- |
| `h` `j` `k` `l` | Move to a target one cell at a time. | Relative jumps (`12j`), `f`/`t`, `s` (flash), `%`, `H`/`M`/`L` |
| `+` `-` | The same, by line. | Counts, `{`/`}`, `[[`/`]]` |
| `gj` `gk` | The same, on screen lines. | `g0`/`g$`, or a real motion |
| `<Up>` `<Down>` `<Left>` `<Right>` | Leave the home row. | The plugin defaults block them in normal and insert mode. |

The arrow keys need no entry in `restricted_keys`. They are already in the
default `disabled_keys` of the plugin, which is the stronger limit.

### Phase 2

`w`, `b`, `e` and `x` are in `config.lua` as comments. When you turn them on,
you must use `f`, `t` or flash to move in a line, and `ciw` or `de` to edit.
Turn them on only after `f`, `t` and `s` are automatic. If you turn them on
before that, editing becomes difficult and teaches nothing.

## Custom hints

| Pattern | Matches | Suggests | Habit |
| --- | --- | --- | --- |
| `0i` | `0i` | `I` | The defaults catch only `^i`. `0i` is the same mistake. |
| `xi` | `xi` | `s` | `s` substitutes a character in one key, and `.` repeats it. |
| `ggVG` | `ggVG` | `yag` / `dag` / `=ag` | The whole-buffer text object (from `mini.ai`) is better than a visual selection. |
| `gg=G` | `gg=G` | `=ag` | The same, for indent. |
| `v[ia]%a[dcy]` | `viwd`, `vipy`, `vifc` | `diw`, `yip`, `cif` | Use the operator and the text object directly. Visual mode is a detour, and `.` cannot repeat it. |
| `v[ia]%p[dcy]` | `vi"d`, `va(y` | `di"`, `ya(` | The same, for text objects in punctuation. |

The theme of the last two: use visual mode when you must see the selection
first. When you know the target, `d` with a text object needs fewer keys, and
`.` can repeat it.

## Habits to learn

This config is for these habits, in the order to learn them. All are
available in this Neovim setup.

### Level 1: get past the plateau

- **`cgn` and `.`**: the most useful habit. Press `*` on a word, then `cgn`,
  then type the new text. Press `.` for each next match. This replaces most
  `:%s///gc` commands, and you still decide at each match. Learn this first.
- **`g;` and `g,`**: go back and forward in the change list. One key takes you
  back to your last edit, without a search or a scroll.
- **Tree-sitter text objects** (`mini.ai`, already installed): `daf` deletes a
  function, `cio` changes the inside of a condition, loop or block, `cia`
  changes an argument. `ac`/`ic` is a class, `ie`/`ae` is a camelCase part,
  and `ag`/`ig` is the whole buffer.
- **`:g`**: `:g/console\.log/d`, `:g/pat/norm A;`, `:v/keep/d`. One command
  does the work of a long macro.
- **Registers**: `"0p` pastes the last yank (a delete does not change it).
  `<C-r>0` does the same in insert mode. `"ay` yanks into a named register,
  and `<C-r>=` calculates in insert mode.

### Level 2: learn next

- **`H`, `M`, `L` and `zt`, `zz`, `zb`**: position by the window. With `j` and
  `k` limited, these are the main alternatives.
- **Marks**: `mA` (an uppercase mark works across files), `` `a `` to go back
  to the exact place, ` `` ` for the last jump, `` `. `` for the last change.
- **Flash `r` and `R` in operator-pending mode**: already bound, but not used
  much. `yr<label>iw` yanks a word in another part of the screen, and the
  cursor does not move.
- **Insert-mode keys**: `<C-w>` deletes the word before the cursor, `<C-u>`
  deletes to the line start, and `<C-o>` runs one normal-mode command. Do not
  leave insert mode to fix a typo three characters back.
- **Visual block**: `<C-v>`, then `I`, `A` or `$A`, edits a column without a
  macro.

### Level 3: refine

`gi` (insert again where you stopped), `gv` (select again), `<C-^>` (the
alternate file), `]q` and `[q` (the quickfix list), and `:cdo` (edits across
the project from a quickfix list).

## Turn it off

```vim
:Hardtime disable   " off for this session
:Hardtime enable
:Hardtime toggle
:Hardtime report    " your mistakes, most frequent first
```

Look at `:Hardtime report` each week. It shows the restricted keys that you
press most, so you know what to practice next.

hardtime is also off in these places:

- The filetypes in `disabled_filetypes` of `config.lua`: file trees, `lazy`,
  `mason`, quickfix, help, Diffview, Neogit, dapui and others.
- Terminal buffers.
- While you record or run a macro.

> [!NOTE]
> hardtime has no `disabled_buftypes` option. The plugin handles terminal
> buffers itself, and `disabled_filetypes` includes the prompt buffers.
