# alias ls='ls --color'
alias ls='eza --group-directories-first --icons'
alias tree='eza --tree'
alias vim='nvim'
alias cls='clear'
alias lg='lazygit'
alias zshrc_edit='vim "$ZDOTDIR/.zshrc"'
alias zshrc_reload='source "$ZDOTDIR/.zshrc"'

alias nlof="$ZDOTDIR/src/myscripts/fzf-listoldfiles"
alias nzo="$ZDOTDIR/src/myscripts/zoxide-openfiles-nvim"
alias gr='cd "$(git rev-parse --show-toplevel 2>/dev/null)"'

alias -s json=bat
alias -s md=bat
alias -s txt=bat
alias -s html=open

alias -g NE='2>/dev/null'
alias -g NO='>/dev/null'
alias -g NUL='>/dev/null 2>&1'
alias -g J='| jq'
alias -g C='| pbcopy'
alias -g P='| pbpaste'

# zinit aliases `zi` to itself; drop that so zoxide's `zi` (interactive
# search) function isn't shadowed by it.
unalias zi 2> /dev/null

# myscripts
alias jsonl_unescape="python ${XDG_CONFIG_HOME}/myscripts/jsonl_unescape.py"
alias bzclean='bazel clean --expunge_async'
