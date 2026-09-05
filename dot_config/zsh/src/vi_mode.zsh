# zsh-vi-mode (jeffreytse/zsh-vi-mode) - replaces zsh's own `bindkey -v` vi
# mode with text objects, surround, a proper visual mode, per-mode cursor
# shapes, and a ~30ms <ESC> (its own readkey engine) instead of zle's 400ms.
#
# The plugin itself is loaded in zinit.zsh; this file only carries its
# settings, and *must* be sourced before zinit.zsh - zsh-vi-mode reads most
# of its ZVM_* options once, while it is being sourced, and ignores anything
# set afterwards.

# =============================================================================
# Initialization mode
# =============================================================================
# By default zsh-vi-mode postpones its init to the first precmd, i.e. after
# the whole of init.zsh has run, and rebinds the viins/vicmd keymaps when it
# gets there - silently throwing away every binding this config makes in the
# meantime (atuin's `/` and `k`, fzf's ^R, pet's ^O, keybinds.zsh).
#
# `sourcing` makes it initialize inside the `zinit light` call instead, so
# everything sourced later in init.zsh binds *after* the plugin and wins.
# That is the same "load order decides" rule core.zsh already documents, so
# the ordering in init.zsh.tmpl is what keeps those bindings alive.
ZVM_INIT_MODE=sourcing

# The same trap one level down: with lazy keybindings the vicmd/visual keymaps
# are not bound at init but on the first <ESC>, which is long after atuin.zsh
# has taken `/` and `k` in vicmd - they would work until you first entered
# normal mode and then vanish. Bind everything up front instead - it costs
# nothing measurable, the deferred path builds the same list either way.
ZVM_LAZY_KEYBINDINGS=false

# =============================================================================
# Command-line editing (`vv`)
# =============================================================================
# `v` in visual mode drops the whole command line into an editor - the way out
# of fighting a 200-character pipeline with `ciw`. It defaults to $EDITOR,
# which is `vim` (see .zshenv) and resolves to Apple's stock /usr/bin/vim on
# macOS, so dot_config/nvim never gets a look in. Point *only* this at nvim:
# $EDITOR itself stays `vim`, so git's commit editor is unchanged.
#
# /opt/homebrew/bin is already on PATH by this point (path_helper reads
# /etc/paths.d/homebrew before .zshrc), so the probe is meaningful here. Where
# nvim isn't installed - WSL, termux, a bare server - this stays unset and the
# plugin falls back to ${EDITOR:-vim} on its own.
(($+commands[nvim])) && ZVM_VI_EDITOR=nvim

# =============================================================================
# System clipboard
# =============================================================================
# Push yanks out to the real clipboard: `y` - and `d`/`x`, same as vim without
# a register - now copy to the system clipboard as well as to zsh's cutbuffer.
#
# It is one-way. Plain `p` still pastes the internal cutbuffer, so pulling text
# *in* from the clipboard remains `gp`/`gP`; those two are wired to the
# clipboard whether or not this option is set, because only copying out is
# gated by it.
ZVM_SYSTEM_CLIPBOARD_ENABLED=true

# macOS and desktop Linux need nothing here: the plugin probes for
# pbcopy/pbpaste, then wl-copy, xclip and xsel. The two platforms it has no
# probe for are the two this config also targets, so wire those up by hand
# (same is_wsl/is_termux predicates notify.zsh dispatches on; both come from
# core.zsh, which init.zsh sources well before this file).
if is_wsl; then
  ZVM_CLIPBOARD_COPY_CMD='clip.exe'
  # Get-Clipboard hands back CRLF; the trailing ^M would be pasted literally
  # into the command line. PASTE_CMD is eval'd, so a pipeline is fine here.
  ZVM_CLIPBOARD_PASTE_CMD="powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r'"
elif is_termux; then
  ZVM_CLIPBOARD_COPY_CMD='termux-clipboard-set'
  ZVM_CLIPBOARD_PASTE_CMD='termux-clipboard-get'
fi

# If none of the above resolve, the plugin's own guard turns every clipboard
# operation into a silent no-op rather than an error, so leaving the feature
# enabled everywhere is safe.

# =============================================================================
# Visual selection colours
# =============================================================================
# The plugin's default selection is #cc0000 on #eeeeee - a hard red that has
# nothing to do with the terminal theme. These are Catppuccin Mocha's `surface1`
# and `text`, i.e. what nvim paints Visual with, to match the WezTerm scheme
# (color_scheme = "Catppuccin Mocha" in wezterm.lua.tmpl). Change both together
# if that scheme ever changes.
ZVM_VI_HIGHLIGHT_BACKGROUND='#45475a'
ZVM_VI_HIGHLIGHT_FOREGROUND='#cdd6f4'

# =============================================================================
# Settings that need the plugin's own constants
# =============================================================================
# $ZVM_MODE_* / $ZVM_CURSOR_* don't exist yet at this point - the plugin
# defines them as it is sourced, then calls zvm_config() before initializing,
# which is the documented place for options that reference them.
function zvm_config() {
  # Start every prompt in insert mode. zsh-vi-mode otherwise restores
  # whichever mode the previous line ended in; plain `bindkey -v` always
  # started in insert, so this keeps the shell feeling the way it did.
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

  # Cursor shapes are left at the plugin defaults: beam in insert, block in
  # normal/visual, underline in operator-pending. tmux.conf already passes
  # the shape sequences through (`terminal-overrides '*:Ss=...:Se=...'`), so
  # these survive inside tmux too.
}

# =============================================================================
# Deliberately not set
# =============================================================================
# ZVM_CLIPBOARD_USE_OSC52 - would push yanks to the *local* clipboard over the
# terminal's escape sequence when working on a remote host, and the plugin
# wraps it for tmux automatically. Left off because the copy commands above
# cover the machines this config runs on; turn it on if SSH becomes routine.
#
# ZVM_VI_INSERT_ESCAPE_BINDKEY - <ESC> stays <ESC>; set it to `jk`/`jj` here
# if that ever becomes the preference.
#
# ZVM_VI_SURROUND_BINDKEY - left at `classic`, i.e. vim-surround muscle
# memory: `ds"` / `cs"'` in normal mode, `S"` or `ys"` over a visual
# selection (the `s-prefix` alternative moves those onto `sd"` / `sr"'` /
# `sa"` and frees `S`).
