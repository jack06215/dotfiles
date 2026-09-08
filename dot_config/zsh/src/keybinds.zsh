# ==== Bindkey =================================================================
# `bindkey -v` lives in core.zsh; the vi keymaps themselves come from
# zsh-vi-mode (see vi_mode.zsh). This file is sourced near the end of
# init.zsh on purpose - zsh-vi-mode is already initialized by then, so these
# bindings override its defaults rather than the other way round. ^p/^n below
# are exactly that: zsh-vi-mode binds them to up/down-line-or-history.
bindkey '\e[3~' delete-char
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey ' '  magic-space
