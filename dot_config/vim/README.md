# vim config

A vim setup that runs *next to* nvim rather than replacing it — small enough to
open instantly for a commit message, capable enough to actually work in when
nvim is overkill or unavailable.

nvim is still the IDE. vim is what `$EDITOR` points at, so it takes the
short-lived edits — commit messages, rebase conflicts, `sudoedit`, opening a
file out of an fzf picker — plus real editing when that's what's in front of
you.

Plugins are managed with [vim-plug](https://github.com/junegunn/vim-plug).

## Files

| Path | Purpose |
| --- | --- |
| `vimrc` | The whole config. |
| `autoload/plug.vim` | vim-plug itself, vendored and tracked in git. |
| `after/ftplugin/gitcommit.vim` | Commit-message tuning, layered on vim's bundled `gitcommit` ftplugin. |

Plugins install to `$XDG_DATA_HOME/vim/plugged`, which is **not** under
`runtimepath` — vim-plug manages rtp itself and overlapping the two breaks it.
Language servers install to `$XDG_DATA_HOME/vim-lsp-settings/servers`.

## How it loads

vim ≥ 9.1.0327 looks for `$XDG_CONFIG_HOME/vim/vimrc` on its own, so there is
no `~/.vimrc` and no symlink step. To confirm the running vim supports it:

```sh
vim --version | grep XDG_CONFIG_HOME
#   3rd user vimrc file: "$XDG_CONFIG_HOME/vim/vimrc"
```

Picking up the XDG vimrc also makes vim set `$MYVIMDIR` and put it at the head
of `'runtimepath'`, with `$MYVIMDIR/after` at the tail. That's how
`autoload/plug.vim` and `after/ftplugin/` are found with no rtp fiddling, and
it drops `~/.vim` out of the path entirely.

`plug.vim` is committed to this repo rather than fetched at startup, so a fresh
machine needs no network and no bootstrap logic. Plugins themselves still need
one command on a new machine:

```sh
chezmoi apply
vim -c 'PlugInstall --sync' -c 'qa'
```

## Ordering rules

The layout of `vimrc` is load-bearing. The first two are marked `ORDER:` in
the file.

**1. `mapleader` must be set before `plug#end()`.** Plugins resolve `<leader>`
at definition time, so a leader set afterwards binds their mappings to the
wrong key.

**2. The chezmoi filetype block must be registered before `plug#end()`.**
`plug#end()` calls `filetype plugin indent on` (plug.vim:399). Autocmds fire in
registration order, and vim's own rule types every `*.tmpl` as `template`,
after which `did_filetype()` makes any re-detect a silent no-op. Move that
block below `plug#end()` and chezmoi template detection breaks **with no
error message**.

**3. Plugin mappings cannot be guarded with `exists()`.** Vim sources plugin
files only *after* the vimrc finishes, so `if exists(':Files')` around a
mapping is always false and silently skips it. The same trap applies to
`exists('*some#autoload#func')`, which stays false until something first calls
into that autoload file. Define plugin mappings unconditionally — the failure
mode without the plugin is `E492` on keypress, which says exactly what's
wrong.

## Plugins

| Plugin | Why |
| --- | --- |
| `tpope/vim-surround` | `ys`/`cs`/`ds`. Same plugin you use in nvim. |
| `tpope/vim-repeat` | Makes `.` repeat surround and sneak. Both plugins expect it. |
| `tpope/vim-commentary` | `gc`. The vim equivalent of Comment.nvim. |
| `justinmk/vim-sneak` | `s{char}{char}` two-character jump. The nearest vim equivalent to flash.nvim. |
| `andymass/vim-matchup` | `%` across keywords, not just brackets. Same plugin as nvim, same settings. |
| `editorconfig/editorconfig-vim` | Honours `.editorconfig`. Not built into vim 9.1, unlike newer builds. |
| `junegunn/fzf` + `fzf.vim` | `:Files`/`:Rg`/`:GFiles`/`:History`. |
| `tpope/vim-fugitive` | In-buffer git — blame, diff, staging while editing. |
| `junegunn/goyo.vim` | Writing mode. Same plugin and dimensions as nvim. |
| `prabirshrestha/vim-lsp` + `asyncomplete` + `asyncomplete-lsp` + `mattn/vim-lsp-settings` | LSP and completion in pure vimscript over `+job`/`+channel`. |

Deliberately **not** included: a colorscheme plugin (vim ships `retrobox`, a
gruvbox port, so the nvim theme matches at zero cost), git gutter signs,
which-key, and hardtime.

The fzf **binary** comes from brew, so the vimrc adds
`/opt/homebrew/opt/fzf` to the runtimepath as a local `Plug` rather than
cloning a second copy of the repo. It falls back to Linuxbrew's path, then to
cloning `junegunn/fzf` with `fzf#install()`.

### Managing them

| Command | Action |
| --- | --- |
| `:PlugInstall` | Install anything missing. |
| `:PlugUpdate` | Update all plugins. |
| `:PlugDiff` | Review what changed since last update; `X` on a commit rolls it back. |
| `:PlugClean` | Remove plugins no longer listed in the vimrc. |
| `:PlugStatus` | Health check. |
| `:PlugUpgrade` | Update vim-plug itself — then commit the `autoload/plug.vim` diff. |

## Keybindings

Leader is <kbd>Space</kbd>.

### Files and search

| Key | Action |
| --- | --- |
| <kbd>Space</kbd> <kbd>f</kbd> | `:Files` — all files (via `fd`). |
| <kbd>Space</kbd> <kbd>F</kbd> | `:GFiles` — git-tracked only. |
| <kbd>Space</kbd> <kbd>b</kbd> | `:Buffers` |
| <kbd>Space</kbd> <kbd>r</kbd> | `:Rg` — ripgrep across the project. |
| <kbd>Space</kbd> <kbd>/</kbd> | `:BLines` — search within the current buffer. |
| <kbd>Space</kbd> <kbd>:</kbd> | `:History:` — command history. |

Inside a picker: <kbd>Ctrl</kbd>+<kbd>t</kbd> tab, <kbd>Ctrl</kbd>+<kbd>x</kbd>
split, <kbd>Ctrl</kbd>+<kbd>v</kbd> vsplit, <kbd>Ctrl</kbd>+<kbd>/</kbd> toggles
the preview.

### Git (fugitive)

| Key | Action |
| --- | --- |
| <kbd>Space</kbd> <kbd>g</kbd><kbd>s</kbd> | `:Git` — status; `-` stages/unstages, `cc` commits. |
| <kbd>Space</kbd> <kbd>g</kbd><kbd>b</kbd> | `:Git blame` |
| <kbd>Space</kbd> <kbd>g</kbd><kbd>d</kbd> | `:Gdiffsplit` |
| <kbd>Space</kbd> <kbd>g</kbd><kbd>l</kbd> | `:Git log --oneline --decorate --graph` |

### Motion and editing

| Key | Action |
| --- | --- |
| <kbd>s</kbd> / <kbd>S</kbd> | Sneak forward/backward — `s{char}{char}` jumps to the nearest match. |
| <kbd>;</kbd> / <kbd>,</kbd> | Next/previous match (falls back to repeating `f`/`t`). |
| <kbd>z</kbd> / <kbd>Z</kbd> | Sneak as an operator target, e.g. `dzab` deletes to `ab`. |
| `ys` / `cs` / `ds` | Add / change / delete surround. Visual mode: <kbd>S</kbd>. |
| `gc` / `gcc` | Comment a motion / the current line. |
| <kbd>%</kbd> | Jump between matching keywords (`if`/`end`, tags), not just brackets. |
| <kbd>]</kbd><kbd>x</kbd> / <kbd>[</kbd><kbd>x</kbd> | Next/previous git conflict marker. |

**On `s`:** sneak takes over `s` and `S` in normal mode, replacing built-in
substitute-character (use `cl` for that). Same trade you already make with
flash.nvim. Sneak is conflict-aware by design — it uses `z`/`Z` for
operator-pending and leaves visual-mode `S` to vim-surround, so `cs`/`ds` and
`S` all still work. No configuration was needed for that.

Two things differ from flash.nvim and are worth knowing, because both read as
"`s` is broken":

- **It needs exactly two characters.** `s` followed by one character does
  nothing at all; there is no incremental mode that labels matches after the
  first keystroke.
- **As an operator it is `z`/`Z`, not `s`/`S`.** `dzab` deletes up to `ab`.
  `dsab` does *not* sneak — it hits vim-surround's delete-surround. That is the
  deliberate trade that keeps `cs"'` and `ds(` working.

`g:sneak#label` is **off**. With it on, `s{char}{char}` stops and waits for a
label keypress whenever more than one match is visible, which is easy to read
as a hang. With it off, the jump is immediate and `;`/`,` walk the remaining
matches.

### General

| Key | Action |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>l</kbd> | Redraw *and* clear search highlight. |
| <kbd>Space</kbd> <kbd>w</kbd> | `:write` |
| <kbd>Space</kbd> <kbd>z</kbd> | `:Goyo` — distraction-free writing. |
| <kbd>Space</kbd> <kbd>y</kbd> | Yank to the system clipboard (also in visual). |
| <kbd>Space</kbd> <kbd>Y</kbd> | Yank to end of line, to the clipboard. |
| <kbd>Y</kbd> | Yank to end of line (consistent with `D` and `C`). |
| <kbd>n</kbd> / <kbd>N</kbd> | Next/previous match, recentred. |
| <kbd>&lt;</kbd> / <kbd>&gt;</kbd> | (visual) Indent, keeping the selection. |

Clipboard yanks are explicit on purpose. `clipboard=unnamed` would mean every
delete while editing a commit message silently clobbers the pasteboard.

The mouse is off, so terminal select-and-copy keeps working — matching
`disable_mouse` in your nvim hardtime config. Uncomment `set mouse=a` in the
keymaps section if you want it.

### LSP

These are **buffer-local and only applied once a server actually attaches**, so
`K` stays keywordprg and `gd` stays goto-local-definition everywhere else —
including in commit messages, where no server ever attaches.

| Key | Action |
| --- | --- |
| `gd` | Go to definition. |
| `gr` | References. |
| `gi` | Implementation. |
| `gt` | Type definition. |
| <kbd>K</kbd> | Hover docs. |
| <kbd>Space</kbd> <kbd>c</kbd><kbd>r</kbd> | Rename symbol. |
| <kbd>Space</kbd> <kbd>c</kbd><kbd>a</kbd> | Code action. |
| <kbd>Space</kbd> <kbd>c</kbd><kbd>f</kbd> | Format document. |

Rename is `<leader>cr`, not the more common `<leader>rn`, because `<leader>r`
is already `:Rg` — vim waits out `timeoutlen` on any mapping that is a strict
prefix of another.
| <kbd>[</kbd><kbd>d</kbd> / <kbd>]</kbd><kbd>d</kbd> | Previous/next diagnostic. |

Completion popup: <kbd>Tab</kbd>/<kbd>Shift</kbd>+<kbd>Tab</kbd> to walk it,
<kbd>Enter</kbd> to accept. Both fall through to their normal meaning when no
popup is open, so <kbd>Enter</kbd> still just breaks a line while writing prose.
Completion is switched off entirely in commit buffers.

Diagnostics are deliberately quiet: signs in the gutter and an echo on the
cursor line, but **no virtual text**. The sign column is off globally and
turned on only for buffers with a server attached, so commit messages don't
lose two columns for nothing.

`pyright-langserver` is already on your `PATH` from npm, so python works with
no setup. For anything else, open a file of that type and run
`:LspInstallServer`. `:LspStatus` shows what's running.

## What routes here

`EDITOR` and `VISUAL` are exported from `dot_zshenv.tmpl`. Before that they
were never set anywhere, so each of these fell through to a bare, unconfigured
`vi`:

| Call site | What it does |
| --- | --- |
| `zsh/src/git.zsh` → `gcm` | Commit message, pre-filled `type(scope): ` with the staged diff below. |
| `zsh/src/git.zsh` → rebase resolver | Opens a conflicted file mid-rebase. |
| `git/config.tmpl` → `git edit-unmerged` | Opens every unmerged file at once. |
| `zsh/src/ls.zsh` → `ls_fzf_open` | `${EDITOR:-vi}` on the picked file. |
| `zsh/src/alias.zsh` → `zshrc_edit` | Edits `$ZDOTDIR/.zshrc`. |
| `SUDO_EDITOR` | `sudoedit`. |

### In a commit message

The buffer opens with the cursor at the end of `gcm`'s pre-filled
`type(scope): `, already in insert mode. A plain `git commit` (empty first
line) opens in normal mode at the top instead.

| Key | Action |
| --- | --- |
| `:wq!` | Commit. |
| `:cq!` | Discard — exits non-zero, which is how `gcm` detects the abort. |
| <kbd>]</kbd><kbd>s</kbd> / <kbd>[</kbd><kbd>s</kbd> | Next/previous misspelling. |
| <kbd>z</kbd><kbd>=</kbd> | Spelling suggestions. |
| <kbd>z</kbd><kbd>g</kbd> | Add word to the dictionary. |

Colour columns sit at 51 and 73 — the 50-char subject limit and the 72-char
body wrap.

## Startup cost

Measured through a pty, three runs each:

| Config | Opening a commit message |
| --- | --- |
| No plugins (previous setup) | ~21.5 ms |
| Current, 13 plugins | ~36–39 ms |
| Current, opening a `.py` (LSP attaches) | ~46 ms |

The largest single cost is `vim-lsp-settings` at ~3.5 ms. Nothing is
lazy-loaded: vim-plug's own docs call on-demand loading "a hacky workaround…
not always guaranteed to work" and recommend it as a last resort, and at 37 ms
there is nothing to buy back.

## Settings worth knowing

- **State lives under `$XDG_STATE_HOME/vim`** — undo, swap, backup, viminfo and
  the spell word list, with the directories created on startup. Swap and backup
  use a trailing `//` so vim encodes the full path into the file name and two
  files with the same basename can't collide.
- **`spellfile` is set explicitly** to `$XDG_STATE_HOME/vim/spell/en.utf-8.add`.
  Without it `zg` fails with `E764` — vim only fills the option in on its own
  when a `spell` directory already exists inside `'runtimepath'`.
- **`undofile` is on**, so undo history survives closing a file.
- **`retrobox`** is the colorscheme — vim's bundled gruvbox port, matching the
  nvim theme with no plugin. True colour is enabled only when `$COLORTERM`
  advertises it.
- **`modeline` is set explicitly.** It's on by default, but it's load-bearing
  here: the `# vim: filetype=zsh` headers across `zsh/src/myscripts/*` depend
  on it. (vim's bundled `gitcommit` ftplugin turns it off for commit buffers,
  which is right — the staged diff in the buffer is untrusted text.)
- **`ttimeoutlen=10`** — without it, leaving insert mode lags a full second.
  Same reasoning as the shell's `bindkey -v` setup.
- **Indentation** defaults to 2 spaces (4 for python, tabs for `make`), with
  editorconfig-vim overriding per project.
- **Files reopen at the last cursor position**, except commit/rebase buffers.

## chezmoi filetypes

chezmoi source names aren't something vim can type on its own, so `*.tmpl`
files are re-detected against their name minus the `.tmpl` — `init.zsh.tmpl`
becomes zsh, `wezterm.lua.tmpl` becomes lua, `chezmoi.toml.tmpl` becomes toml.
`dot_zshenv` and `git/config` get explicit rules, since stripping `.tmpl` still
leaves a name vim can't place.

See ordering rule 2 above before adding to that block.

Known gap: `gpg-agent.conf.tmpl` lands on `template`. vim detects `.conf` via
`setf FALLBACK`, which by design loses to the `*.tmpl` rule. Harmless, and
special-casing it would undermine the generic approach.

## Still on nvim

Deliberately untouched — nvim is the IDE:

- `vimfind` and `vimrecent` (`zsh/src/search.zsh`)
- `fzf-listprojects` (`zsh/src/myscripts/`)
- lazygit's `editPreset: nvim`

`vimrecent` and `fzf-listprojects` both read `vim.v.oldfiles` out of a headless
nvim, so they're tied to nvim's history rather than vim's viminfo.
