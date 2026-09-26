# Use zsh's $path array for dedupe and easy manipulation
typeset -gU path
add_path_front() { [[ -d "$1" ]] && path=("$1" $path); }
add_path_back() { [[ -d "$1" ]] && path+=("$1"); }

add_path_front "$HOME/.local/bin"

# BUN_INSTALL is already set correctly (XDG-based) in ~/.zshenv.
add_path_front "$BUN_INSTALL/bin"

# Only put rbenv on PATH when it's the chosen Ruby manager (see init.zsh),
# otherwise it silently fights asdf for ruby/gem resolution.
[[ "${ZSH_RUBY_MANAGER:-asdf}" == "rbenv" ]] && add_path_front "$HOME/.rbenv/bin"

# Homebrew's prefix: /opt/homebrew on macOS (where HOMEBREW_PREFIX is usually
# unset), Linuxbrew's on Linux (set in ~/.zshenv). add_path_* skip missing dirs.
_brew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

# imagemagick-full is keg-only, so it must go in FRONT of Homebrew's bin to
# beat the linked plain imagemagick. It's the build with the jxl/rsvg/raw
# delegates yazi's `magick` previewer needs (see yazi.toml).
add_path_front "$_brew_prefix/opt/imagemagick-full/bin"

# `go install` writes to $GOPATH/bin (GOPATH is under XDG_DATA_HOME, see
# ~/.zshenv); ~/go/bin is only where go puts things without a GOPATH.
add_path_back "$GOPATH/bin"
add_path_back "$HOME/go/bin"
add_path_back "$XDG_DATA_HOME/npm/bin"
add_path_back "$_brew_prefix/opt/mysql@8.0/bin"
add_path_back "$_brew_prefix/opt/mysql-client@8.0/bin"
unset _brew_prefix

add_path_back "$HOME/tools/flutter/bin"

add_path_back "$ZDOTDIR/src/myscripts"

# Flywheel specific script
add_path_back "$HOME/myscripts"
