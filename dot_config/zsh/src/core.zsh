# Core options
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Must run before anything that does `bindkey -M viins/vicmd ...` (atuin.zsh,
# pet.zsh, etc.) - `bindkey -v` reinitializes the vi keymaps and silently
# wipes out custom bindings set on them beforehand.
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
