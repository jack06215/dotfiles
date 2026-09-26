# Keep flow control off: tmux's prefix is C-s, and `C-s C-s` (send-prefix)
# forwards a literal ^S to this shell, which would otherwise XOFF the terminal.
# Needed with or without pet, so it sits outside the guard below.
[[ -t 0 ]] && stty -ixon

# Guarded like navi.zsh: without pet, ^O would replace the line being typed
# with pet's (empty) output.
if command -v pet > /dev/null 2>&1; then
  function pet_select() {
    BUFFER=$(pet search --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle redisplay
  }
  zle -N pet_select
  # ^O rather than ^S: tmux takes C-s as its prefix (see tmux.conf), so a ^S
  # binding here is unreachable. ^O is unbound in viins (self-insert).
  bindkey -M viins '^o' pet_select
  bindkey -M emacs '^o' pet_select
fi
