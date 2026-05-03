if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

export FZF_DEFAULT_OPTS='
  --height=40%
  --layout=reverse
  --border
  --preview="
    if [ -d {} ]; then
      eza --tree --level=2 --color=always -- {}
    elif [ -f {} ] && [ -r {} ]; then
      if command -v bat >/dev/null 2>&1; then
        bat --style=numbers --color=always --line-range :300 -- {} 2>/dev/null || :
      fi
    fi
  "
'

# Keybindings
source /usr/share/fzf/key-bindings.zsh 2>/dev/null || true
source /usr/share/fzf/completion.zsh   2>/dev/null || true
