# navi (https://github.com/denisidoro/navi) - cheatsheet launcher over the
# .cheat files in $XDG_CONFIG_HOME/navi/cheats, which are a port of pet's
# snippet.toml. It runs alongside pet rather than replacing it; NAVI_CONFIG is
# exported in ~/.zshenv so navi reads the chezmoi-managed config on macOS too.
#
# `navi widget zsh` prints the upstream widget: it defines _navi_widget and
# binds it to ^G in whatever the main keymap happens to be. The two bindkey
# lines redo that per keymap, the same way pet.zsh does - with `bindkey -v` in
# effect the main keymap is viins, so the upstream binding never reaches emacs.
#
# ^G rather than ^S: tmux takes C-s as its prefix (see tmux.conf) and pet
# already holds ^O. ^G is send-break in emacs mode and unbound in viins.
if command -v navi > /dev/null 2>&1; then
  eval "$(navi widget zsh)"
  bindkey -M viins '^g' _navi_widget
  bindkey -M emacs '^g' _navi_widget
fi
