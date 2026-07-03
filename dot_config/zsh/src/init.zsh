# shellcheck shell=bash
# shellcheck disable=SC1091
# filetype=sh
#
# Above `shell=bash` is deliberate, not a mismatch: shellcheck has no zsh
# mode (see https://github.com/koalaman/shellcheck/wiki/SC1071), so `bash`
# is used as the closest approximation, same convention as atuin.zsh in
# this directory. Any bash-vs-zsh false positive should be silenced with a
# targeted `# shellcheck disable=...` near the offending line rather than by
# dropping the directive (that turns into SC2148 "shell type unknown").

# =============================================================================
# Profiling (opt-in) - set ZSH_PROFILE_STARTUP=1 before launching zsh to
# enable. Must be loaded before anything else is sourced so it can actually
# measure it; the report is printed at the very end of this file. Zero
# overhead when unset (default).
# =============================================================================
if [[ -n "$ZSH_PROFILE_STARTUP" ]] && zmodload zsh/zprof 2>/dev/null; then
  _ZSH_PROFILE_STARTUP_ENABLED=1
fi

# =============================================================================
# Private credentials (NEVER COMMIT)
# =============================================================================
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# =============================================================================
# Core shell behavior
# =============================================================================
[ -f "$ZDOTDIR/src/core.zsh" ] && source "$ZDOTDIR/src/core.zsh"

# =============================================================================
# Safety net for OS predicates
# is_wsl/is_macos/is_termux are defined in core.zsh. If core.zsh is ever
# missing/renamed, define harmless fallbacks so the OS branches below never
# hit "command not found: is_wsl" and just fall through to plain-Linux/none.
# =============================================================================
(( $+functions[is_wsl] ))    || is_wsl()    { return 1; }
(( $+functions[is_macos] ))  || is_macos()  { return 1; }
(( $+functions[is_termux] )) || is_termux() { return 1; }

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
else
  # Plain Linux (not WSL, not Termux): intentionally no dedicated pre-init
  # file exists yet. This is a deliberate no-op, not an oversight - add a
  # linux_pre_init.zsh here (mirroring wsl_pre_init.zsh) if/when
  # Linux-specific setup is needed. Set ZSH_DEBUG_INIT=1 to trace this.
  [[ -n "$ZSH_DEBUG_INIT" ]] && print -u2 -- "[init.zsh] plain Linux detected; no OS-specific pre-init defined, skipping"
fi
[ -f "$ZDOTDIR/src/zsh_python_init.zsh" ] && source "$ZDOTDIR/src/zsh_python_init.zsh"

# =============================================================================
# Core utilities
# =============================================================================
[ -f "$ZDOTDIR/src/asdf.zsh" ] && source "$ZDOTDIR/src/asdf.zsh"

# Ruby version manager: asdf and rbenv both install shims/hooks that mutate
# PATH, so loading both makes `ruby`/`gem` resolution depend on sourcing
# order rather than intent. asdf is the default since it already manages
# other tools in this config (see mysql.zsh, path.zsh, zsh_python_init.zsh).
# Set ZSH_RUBY_MANAGER=rbenv to use rbenv instead.
if [[ "${ZSH_RUBY_MANAGER:-asdf}" == "rbenv" ]]; then
  [ -f "$ZDOTDIR/src/rbenv.zsh" ] && source "$ZDOTDIR/src/rbenv.zsh"
fi
[ -f "$ZDOTDIR/src/functions.zsh" ] && source "$ZDOTDIR/src/functions.zsh"

# Version overrides for tools whose pin (company .tool-versions, etc.) can't
# be trusted to stay current - see patch_functions.zsh for why.
if [ -f "$ZDOTDIR/src/patch_functions.zsh" ]; then
    source "$ZDOTDIR/src/patch_functions.zsh"
    s_shfmt_pinned
fi

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
[ -f "$ZDOTDIR/src/jira.zsh" ] && source "$ZDOTDIR/src/jira.zsh"
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
else
  # Plain Linux: no dedicated post-init file yet either; see the pre-init
  # branch above for rationale. Intentional no-op.
  [[ -n "$ZSH_DEBUG_INIT" ]] && print -u2 -- "[init.zsh] plain Linux detected; no OS-specific post-init defined, skipping"
fi

# =============================================================================
# Profiling report (opt-in, see top of file for ZSH_PROFILE_STARTUP)
# =============================================================================
if [[ -n "${_ZSH_PROFILE_STARTUP_ENABLED:-}" ]]; then
  zprof
fi
