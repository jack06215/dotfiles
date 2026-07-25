function ls_fzf_open() {
  local target

  target="$(
    fd . --hidden --follow --exclude .git \
      | fzf --preview '
      if [ -d {} ]; then
        eza --tree --level=2 --icons --color=always {}
      else
        eza -l --icons --color=always {}
      fi
    ' \
        --preview-window=right:60%:wrap
  )" || return

  if [[ -d "$target" ]]; then
    cd "$target" || return 0
  else
    ${EDITOR:-vi} "$target"
  fi
}

function ls_count_ext() {
  local nu_functions="${XDG_CONFIG_HOME:-$HOME}/nushell/function.nu"
  nu -c "source '$nu_functions'; ls_count_ext"
}
