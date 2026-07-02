function pet_select() {
  BUFFER=$(pet search --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N pet_select
stty -ixon
bindkey -M viins '^s' pet-select
bindkey -M emacs '^s' pet-select
