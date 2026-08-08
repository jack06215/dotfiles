# vim config

A deliberately small vim setup that runs *next to* nvim rather than replacing it.

nvim stays the IDE. vim is what `$EDITOR` points at, so it handles the
short-lived edits — commit messages, rebase conflicts, `sudoedit`, opening a
file straight out of an fzf picker. Everything here has to earn its keep on a
ten-second edit, so there is no plugin manager and nothing to keep updated.

## Files

| Path | Purpose |
| --- | --- |
| `vimrc` | The whole config. |
| `after/ftplugin/gitcommit.vim` | Commit-message tuning, layered on vim's bundled `gitcommit` ftplugin. |

## How it loads

vim ≥ 9.1.0327 looks for `$XDG_CONFIG_HOME/vim/vimrc` on its own, so there is
no `~/.vimrc` and no symlink step — chezmoi drops the file in place and vim
finds it.

Picking up the XDG vimrc also makes vim set `$MYVIMDIR` and put it at the head
of `'runtimepath'`, with `$MYVIMDIR/after` at the tail. That is what makes
`after/ftplugin/` work with no rtp fiddling, and it drops `~/.vim` out of the
path entirely.

Requires vim 9.1.0327 or newer. To confirm the running vim supports it:

```sh
vim --version | grep XDG_CONFIG_HOME
#   3rd user vimrc file: "$XDG_CONFIG_HOME/vim/vimrc"
```

No output means the vim on `$PATH` predates XDG support and won't find this
file.

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

## Keybindings

Leader is <kbd>Space</kbd>.

### Normal mode

| Key | Action |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>l</kbd> | Redraw *and* clear search highlight. |
| <kbd>Space</kbd> <kbd>w</kbd> | `:write` |
| <kbd>Space</kbd> <kbd>f</kbd> | `:Files` — fuzzy file picker. |
| <kbd>Space</kbd> <kbd>b</kbd> | `:Buffers` — pick an open buffer. |
| <kbd>Space</kbd> <kbd>g</kbd> | `:Rg ` — leaves the cursor in the prompt for a pattern. |
| <kbd>Space</kbd> <kbd>y</kbd> | Yank to the system clipboard. |
| <kbd>Space</kbd> <kbd>Y</kbd> | Yank to end of line, to the system clipboard. |
| <kbd>Y</kbd> | Yank to end of line (consistent with `D` and `C`). |
| <kbd>n</kbd> / <kbd>N</kbd> | Next/previous match, recentred. |
| <kbd>]</kbd><kbd>x</kbd> / <kbd>[</kbd><kbd>x</kbd> | Next/previous conflict marker. |

### Visual mode

| Key | Action |
| --- | --- |
| <kbd>&lt;</kbd> / <kbd>&gt;</kbd> | Indent, keeping the selection. |
| <kbd>Space</kbd> <kbd>y</kbd> | Yank selection to the system clipboard. |

Clipboard yanks are explicit on purpose. `clipboard=unnamed` would mean every
delete while editing a commit message silently clobbers the pasteboard.

`]x`/`[x` exist because this vim has no built-in `]n` conflict motion — that
one is a neovim/vim-unimpaired feature, and rebase conflicts are a main reason
this config exists.

The mouse is off, so terminal select-and-copy keeps working. Uncomment
`set mouse=a` near the bottom of the keymaps section if you'd rather have
scroll and click-to-position.

### In a commit message

The buffer opens with the cursor at the end of `gcm`'s pre-filled
`type(scope): `, already in insert mode. A plain `git commit` (empty first
line) opens in normal mode at the top instead.

| Key | Action |
| --- | --- |
| `:wq!` | Commit. |
| `:cq!` | Discard — exits non-zero, which is how `gcm` detects the abort. |
| <kbd>]</kbd><kbd>s</kbd> / <kbd>[</kbd><kbd>s</kbd> | Next/previous misspelling (`spell` is on here). |
| <kbd>z</kbd><kbd>=</kbd> | Spelling suggestions. |
| <kbd>z</kbd><kbd>g</kbd> | Add word to the dictionary. |

Colour columns sit at 51 and 73 — the 50-char subject limit and the 72-char
body wrap.

## fzf

The `fzf#run`/`fzf#wrap` functions come from the plugin file that ships *inside*
the fzf package itself, so there's no plugin manager involved. The vimrc probes
the usual install paths (Homebrew on macOS and Linux, Debian, Termux, `~/.fzf`)
and silently skips the whole section if none is found.

The commands are thin wrappers over the same `fd` / `rg` / `bat` pipeline the
shell functions already use:

| Command | Source |
| --- | --- |
| `:Files [dir]` | `fd --type f --hidden --follow --exclude .git` |
| `:Rg <pattern>` | `rg --column --line-number --smart-case --hidden` |
| `:Buffers` | Listed buffers. |
| `:FZF` | Provided by the fzf plugin itself. |

Inside the picker:

| Key | Action |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>t</kbd> | Open in a new tab. |
| <kbd>Ctrl</kbd>+<kbd>x</kbd> | Open in a horizontal split. |
| <kbd>Ctrl</kbd>+<kbd>v</kbd> | Open in a vertical split. |
| <kbd>Tab</kbd> | Multi-select (`:Files` only). |
| <kbd>Ctrl</kbd>+<kbd>/</kbd> | Toggle the preview (from `FZF_DEFAULT_OPTS`). |

The split/tab keys come from `fzf#wrap` and apply to `:Files` and `:Buffers`.
`:Rg` uses its own sink to parse `file:line:col` and jump, so it opens in the
current window only.

Each command passes its own `--preview`, because the one in your
`FZF_DEFAULT_OPTS` assumes `{}` is a bare path and breaks on `:Rg`'s
`file:line:col:text` rows.

`:grep` is wired to ripgrep too, so `:grep pattern` populates the quickfix list
(`:copen`, then <kbd>Ctrl</kbd>+<kbd>o</kbd> / <kbd>Ctrl</kbd>+<kbd>i</kbd> to
jump around).

## Settings worth knowing

- **State lives under `$XDG_STATE_HOME/vim`** — undo, swap, backup, viminfo and
  the spell word list, with the directories created on startup. `$HOME` stays
  clean, same as the rest of the setup. Swap and backup use a trailing `//` so
  vim encodes the full path into the file name and two files with the same
  basename can't collide.
- **`spellfile` is set explicitly** to `$XDG_STATE_HOME/vim/spell/en.utf-8.add`.
  Without it `zg` fails with `E764` — vim only fills the option in on its own
  when a `spell` directory already exists inside `'runtimepath'`.
- **`undofile` is on**, so undo history survives closing a file.
- **`retrobox`** is the colorscheme — vim's bundled gruvbox port, which matches
  the nvim theme without pulling in a plugin. True colour is enabled only when
  `$COLORTERM` advertises it.
- **`modeline` is set explicitly.** It's on by default, but it's load-bearing
  here: the `# vim: filetype=zsh` headers across `zsh/src/myscripts/*` depend
  on it. (vim's bundled `gitcommit` ftplugin turns it off for commit buffers,
  which is the right call — the staged diff in the buffer is untrusted text.)
- **`ttimeoutlen=10`** — without it, leaving insert mode lags a full second.
  Same reasoning as the shell's `bindkey -v` setup.
- **Indentation mirrors `.editorconfig`** — 2 spaces, 4 for python, real tabs
  for `make`.
- **Files reopen at the last cursor position**, except commit/rebase buffers,
  which always start at the top.

## chezmoi filetypes

chezmoi source names aren't something vim can type on its own, so `*.tmpl`
files are re-detected against their name minus the `.tmpl` — `init.zsh.tmpl`
becomes zsh, `wezterm.lua.tmpl` becomes lua, and so on. `dot_zshenv` and
`git/config` get explicit rules, since stripping `.tmpl` still leaves a name
vim can't place.

This block has to be registered **before** `filetype on`. Autocmds fire in
registration order, and vim's own rule types every `*.tmpl` as `template`,
after which `did_filetype()` makes any re-detect a silent no-op. If you add
rules here, keep them above that line.

Known gap: `gpg-agent.conf.tmpl` still lands on `template`. vim detects `.conf`
via `setf FALLBACK`, which by design loses to the `*.tmpl` rule. Harmless, and
special-casing it would undermine the generic approach.

## Still on nvim

Deliberately untouched — nvim is the IDE, vim is the fast path:

- `vimfind` and `vimrecent` (`zsh/src/search.zsh`)
- `fzf-listprojects` (`zsh/src/myscripts/`)
- lazygit's `editPreset: nvim`

`vimrecent` and `fzf-listprojects` both read `vim.v.oldfiles` out of a headless
nvim, so they're tied to nvim's history rather than vim's viminfo.
