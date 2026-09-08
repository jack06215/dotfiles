# Core options
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Fallback only. zsh-vi-mode owns the vi keymaps from zinit.zsh onwards (see
# vi_mode.zsh), and it runs `bindkey -v` itself at the end of its init; this
# line is what keeps vi mode working on a first run where zinit hasn't cloned
# the plugin yet, or on a machine that is offline.
#
# It still has to run before anything that does `bindkey -M viins/vicmd ...`
# (atuin.zsh, pet.zsh, etc.) - `bindkey -v` relinks the main keymap and
# custom bindings made against the old one are lost.
bindkey -v

export PATH="$XDG_DATA_HOME/npm/bin:$PATH"

# =============================================================================
# Platform detection
# =============================================================================
function is_termux() {
  [[ -n "$TERMUX_VERSION" ]]
}

function is_wsl() {
  [[ "$(uname -s)" == "Linux" ]] \
    && [[ -r /proc/version ]] \
    && grep -qi microsoft /proc/version 2>/dev/null
}

function is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}
