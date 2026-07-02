# Use zsh's $path array for dedupe and easy manipulation
typeset -gU path
add_path_front() { [[ -d "$1" ]] && path=("$1" $path) }
add_path_back()  { [[ -d "$1" ]] && path+=("$1") }

add_path_front "$HOME/.local/bin"

# BUN_INSTALL is already set correctly (XDG-based) in ~/.zshenv.
add_path_front "$BUN_INSTALL/bin"

# Only put rbenv on PATH when it's the chosen Ruby manager (see init.zsh),
# otherwise it silently fights asdf for ruby/gem resolution.
[[ "${ZSH_RUBY_MANAGER:-asdf}" == "rbenv" ]] && add_path_front "$HOME/.rbenv/bin"
add_path_back "$HOME/go/bin"
add_path_back "$XDG_DATA_HOME/npm/bin"
add_path_back "/opt/homebrew/opt/mysql@8.0/bin"
add_path_back "/opt/homebrew/opt/mysql-client@8.0/bin"

add_path_back "$HOME/.asdf/installs/poetry/2.2.1/bin"
add_path_back "$HOME/tools/flutter/bin"

# Flywheel specific script
add_path_back "$HOME/myscripts"
