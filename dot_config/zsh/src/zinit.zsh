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

# zsh-vi-mode has to stay first: vi_mode.zsh configures it to initialize
# while it is being sourced (ZVM_INIT_MODE=sourcing), and it rebinds the
# viins/vicmd keymaps when it does. Anything that binds keys - fzf-tab's Tab
# below, and atuin/fzf/pet/keybinds further down init.zsh - has to come after
# it, or its bindings are the ones that get overwritten.
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit light Aloxaf/fzf-tab
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
