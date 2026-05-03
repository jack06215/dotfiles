# shellcheck shell=bash
# shellcheck disable=SC1091
# filetype=sh

# =============================================================================
# Private credentials (NEVER COMMIT)
# =============================================================================
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# =============================================================================
# Core shell behavior
# =============================================================================
[ -f "$ZSH_DIR/core.zsh" ] && source "$ZSH_DIR/core.zsh"

# =============================================================================
# Zsh core with OS-specific setup
# =============================================================================
if is_wsl; then
  [ -f "$ZSH_DIR/wsl_pre_init.zsh" ] && source "$ZSH_DIR/wsl_pre_init.zsh"
  [ -f "$ZSH_DIR/wsl.zsh" ] && source "$ZSH_DIR/wsl.zsh"
elif is_macos; then
  [ -f "$ZSH_DIR/darwin_pre_init.zsh" ] && source "$ZSH_DIR/darwin_pre_init.zsh"
  [ -f "$ZSH_DIR/darwin.zsh" ] && source "$ZSH_DIR/darwin.zsh"
# Termux should be at the lowest priority since it's a special case of linux.
elif is_termux; then
  [ -f "$ZSH_DIR/termux_pre_init.zsh" ] && source "$ZSH_DIR/termux_pre_init.zsh"
  [ -f "$ZSH_DIR/termux.zsh" ] && source "$ZSH_DIR/termux.zsh"
fi
[ -f "$ZSH_DIR/zsh_python_init.zsh" ] && source "$ZSH_DIR/zsh_python_init.zsh"

# =============================================================================
# Core utilities
# =============================================================================
[ -f "$ZSH_DIR/asdf.zsh" ] && source "$ZSH_DIR/asdf.zsh"
[ -f "$ZSH_DIR/rbenv.zsh" ] && source "$ZSH_DIR/rbenv.zsh"
[ -f "$ZSH_DIR/functions.zsh" ] && source "$ZSH_DIR/functions.zsh"

# =============================================================================
# Zinit and its plugins
# =============================================================================
[ -f "$ZSH_DIR/zinit.zsh" ] && source "$ZSH_DIR/zinit.zsh"

# =============================================================================
# PATH, and history
# =============================================================================
[ -f "$ZSH_DIR/history.zsh" ] && source "$ZSH_DIR/history.zsh"
[ -f "$ZSH_DIR/path.zsh" ] && source "$ZSH_DIR/path.zsh"

# =============================================================================
# Completion
# =============================================================================
[ -f "$ZSH_DIR/completion.zsh" ] && source "$ZSH_DIR/completion.zsh"

# carapace must come AFTER compinit
[ -f "$ZSH_DIR/carapace.zsh" ] && source "$ZSH_DIR/carapace.zsh"

# =============================================================================
# Prompt & interactive tools
# =============================================================================
[ -f "$ZSH_DIR/atuin.zsh" ] && source "$ZSH_DIR/atuin.zsh"
[ -f "$ZSH_DIR/fzf.zsh" ] && source "$ZSH_DIR/fzf.zsh"
[ -f "$ZSH_DIR/starship.zsh" ] && source "$ZSH_DIR/starship.zsh"
[ -f "$ZSH_DIR/zoxide.zsh" ] && source "$ZSH_DIR/zoxide.zsh"

# =============================================================================
# Domain-specific
# =============================================================================
[ -f "$ZSH_DIR/aws.zsh" ] && source "$ZSH_DIR/aws.zsh"
[ -f "$ZSH_DIR/bazel.zsh" ] && source "$ZSH_DIR/bazel.zsh"
[ -f "$ZSH_DIR/dart.zsh" ] && source "$ZSH_DIR/dart.zsh"
[ -f "$ZSH_DIR/gh.zsh" ] && source "$ZSH_DIR/gh.zsh"
[ -f "$ZSH_DIR/git.zsh" ] && source "$ZSH_DIR/git.zsh"
[ -f "$ZSH_DIR/jira.zsh" ] && source  "$ZSH_DIR/jira.zsh"
[ -f "$ZSH_DIR/k8s.zsh" ] && source "$ZSH_DIR/k8s.zsh"
[ -f "$ZSH_DIR/ls.zsh" ] && source "$ZSH_DIR/ls.zsh"
[ -f "$ZSH_DIR/mysql.zsh" ] && source "$ZSH_DIR/mysql.zsh"
[ -f "$ZSH_DIR/notify.zsh" ] && source "$ZSH_DIR/notify.zsh"
[ -f "$ZSH_DIR/search.zsh" ] && source "$ZSH_DIR/search.zsh"

# =============================================================================
# Key bindings and aliases (possibly override)
# =============================================================================
[ -f "$ZSH_DIR/alias.zsh" ] && source "$ZSH_DIR/alias.zsh"
[ -f "$ZSH_DIR/keybinds.zsh" ] && source "$ZSH_DIR/keybinds.zsh"

# =============================================================================
# OS-specific post init (must be last)
# =============================================================================
if is_wsl; then
  [ -f "$ZSH_DIR/wsl_post_init.zsh" ] && source "$ZSH_DIR/wsl_post_init.zsh"
elif is_macos; then
  [ -f "$ZSH_DIR/darwin_post_init.zsh" ] && source "$ZSH_DIR/darwin_post_init.zsh"
elif is_termux; then
  [ -f "$ZSH_DIR/termux_post_init.zsh" ] && source "$ZSH_DIR/termux_post_init.zsh"
fi
# =============================================================================
# Profiling (opt-in)
# =============================================================================
zmodload zsh/zprof
