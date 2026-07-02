# ==== Bindkey =================================================================
# `bindkey -v` now lives in core.zsh (must run before atuin.zsh/pet.zsh
# install their custom viins/vicmd bindings).
bindkey '\e[3~' delete-char
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey ' '  magic-space
