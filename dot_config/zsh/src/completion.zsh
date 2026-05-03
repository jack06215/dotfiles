# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

autoload -Uz compinit
_compdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -f "$_compdump" && ! -w "$_compdump" ]]; then
  chmod 600 "$_compdump" 2>/dev/null || true
fi
compinit -C
