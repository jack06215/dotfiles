# if ! is_termux && [[ -f "$HOMEBREW_PREFIX/opt/zinit/zinit.zsh" ]]; then
#   source "$HOMEBREW_PREFIX/opt/zinit/zinit.zsh"
# fi

ZINIT_HOME="$HOME/.local/share/zinit"
ZINIT_REPO="$ZINIT_HOME/zinit.git"
ZINIT_SCRIPT="$ZINIT_REPO/zinit.zsh"

if [[ ! -f "$ZINIT_SCRIPT" ]]; then
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"

  command mkdir -p "$ZINIT_HOME"
  command chmod g-rwX "$ZINIT_HOME"

  if command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_REPO"; then
    print -P "%F{33} %F{34}Installation successful.%f%b"
  else
    print -P "%F{160} The clone has failed.%f%b"
  fi
fi

source "$ZINIT_SCRIPT"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light Aloxaf/fzf-tab
zinit light zdharma/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
