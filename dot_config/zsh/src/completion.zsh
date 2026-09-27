# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
# Don't seed fzf's query with the typed word ("input"): carapace lists files
# by basename, so `cat a/b/<Tab>` would query "a/b/" against "file.txt" and
# match nothing. The candidates are already filtered by what was typed.
zstyle ':fzf-tab:*' query-string prefix first

autoload -Uz compinit
_compdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -f "$_compdump" && ! -w "$_compdump" ]]; then
  chmod 600 "$_compdump" 2>/dev/null || true
fi
compinit -C
