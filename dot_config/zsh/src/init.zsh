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
[ -f "$ZDOTDIR/src/core.zsh" ] && source "$ZDOTDIR/src/core.zsh"

# =============================================================================
# Zsh core with OS-specific setup
# =============================================================================
if is_wsl; then
  [ -f "$ZDOTDIR/src/wsl_pre_init.zsh" ] && source "$ZDOTDIR/src/wsl_pre_init.zsh"
  [ -f "$ZDOTDIR/src/wsl.zsh" ] && source "$ZDOTDIR/src/wsl.zsh"
elif is_macos; then
  [ -f "$ZDOTDIR/src/darwin_pre_init.zsh" ] && source "$ZDOTDIR/src/darwin_pre_init.zsh"
  [ -f "$ZDOTDIR/src/darwin.zsh" ] && source "$ZDOTDIR/src/darwin.zsh"
# Termux should be at the lowest priority since it's a special case of linux.
elif is_termux; then
  [ -f "$ZDOTDIR/src/termux_pre_init.zsh" ] && source "$ZDOTDIR/src/termux_pre_init.zsh"
  [ -f "$ZDOTDIR/src/termux.zsh" ] && source "$ZDOTDIR/src/termux.zsh"
fi
[ -f "$ZDOTDIR/src/zsh_python_init.zsh" ] && source "$ZDOTDIR/src/zsh_python_init.zsh"

# =============================================================================
# Core utilities
# =============================================================================
[ -f "$ZDOTDIR/src/asdf.zsh" ] && source "$ZDOTDIR/src/asdf.zsh"
[ -f "$ZDOTDIR/src/rbenv.zsh" ] && source "$ZDOTDIR/src/rbenv.zsh"
[ -f "$ZDOTDIR/src/functions.zsh" ] && source "$ZDOTDIR/src/functions.zsh"

# =============================================================================
# Zinit and its plugins
# =============================================================================
[ -f "$ZDOTDIR/src/zinit.zsh" ] && source "$ZDOTDIR/src/zinit.zsh"

# =============================================================================
# PATH, and history
# =============================================================================
[ -f "$ZDOTDIR/src/history.zsh" ] && source "$ZDOTDIR/src/history.zsh"
[ -f "$ZDOTDIR/src/path.zsh" ] && source "$ZDOTDIR/src/path.zsh"

# =============================================================================
# Completion
# =============================================================================
[ -f "$ZDOTDIR/src/completion.zsh" ] && source "$ZDOTDIR/src/completion.zsh"

# carapace must come AFTER compinit
[ -f "$ZDOTDIR/src/carapace.zsh" ] && source "$ZDOTDIR/src/carapace.zsh"

# =============================================================================
# Prompt & interactive tools
# =============================================================================
[ -f "$ZDOTDIR/src/atuin.zsh" ] && source "$ZDOTDIR/src/atuin.zsh"
[ -f "$ZDOTDIR/src/fzf.zsh" ] && source "$ZDOTDIR/src/fzf.zsh"
[ -f "$ZDOTDIR/src/starship.zsh" ] && source "$ZDOTDIR/src/starship.zsh"
[ -f "$ZDOTDIR/src/zoxide.zsh" ] && source "$ZDOTDIR/src/zoxide.zsh"

# =============================================================================
# Domain-specific
# =============================================================================
[ -f "$ZDOTDIR/src/aws.zsh" ] && source "$ZDOTDIR/src/aws.zsh"
[ -f "$ZDOTDIR/src/bazel.zsh" ] && source "$ZDOTDIR/src/bazel.zsh"
[ -f "$ZDOTDIR/src/chezmoi.zsh" ] && source "$ZDOTDIR/src/chezmoi.zsh"
[ -f "$ZDOTDIR/src/dart.zsh" ] && source "$ZDOTDIR/src/dart.zsh"
[ -f "$ZDOTDIR/src/gh.zsh" ] && source "$ZDOTDIR/src/gh.zsh"
[ -f "$ZDOTDIR/src/git.zsh" ] && source "$ZDOTDIR/src/git.zsh"
[ -f "$ZDOTDIR/src/jira.zsh" ] && source  "$ZDOTDIR/src/jira.zsh"
[ -f "$ZDOTDIR/src/k8s.zsh" ] && source "$ZDOTDIR/src/k8s.zsh"
[ -f "$ZDOTDIR/src/ls.zsh" ] && source "$ZDOTDIR/src/ls.zsh"
[ -f "$ZDOTDIR/src/mysql.zsh" ] && source "$ZDOTDIR/src/mysql.zsh"
[ -f "$ZDOTDIR/src/notify.zsh" ] && source "$ZDOTDIR/src/notify.zsh"
[ -f "$ZDOTDIR/src/pet.zsh" ] && source "$ZDOTDIR/src/pet.zsh"
[ -f "$ZDOTDIR/src/search.zsh" ] && source "$ZDOTDIR/src/search.zsh"

# =============================================================================
# Key bindings and aliases (possibly override)
# =============================================================================
[ -f "$ZDOTDIR/src/alias.zsh" ] && source "$ZDOTDIR/src/alias.zsh"
[ -f "$ZDOTDIR/src/keybinds.zsh" ] && source "$ZDOTDIR/src/keybinds.zsh"

# =============================================================================
# OS-specific post init (must be last)
# =============================================================================
if is_wsl; then
  [ -f "$ZDOTDIR/src/wsl_post_init.zsh" ] && source "$ZDOTDIR/src/wsl_post_init.zsh"
elif is_macos; then
  [ -f "$ZDOTDIR/src/darwin_post_init.zsh" ] && source "$ZDOTDIR/src/darwin_post_init.zsh"
elif is_termux; then
  [ -f "$ZDOTDIR/src/termux_post_init.zsh" ] && source "$ZDOTDIR/src/termux_post_init.zsh"
fi
# =============================================================================
# Profiling (opt-in)
# =============================================================================
zmodload zsh/zprof
