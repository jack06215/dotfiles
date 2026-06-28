function meetingbar_send_notification() {
  local json_file="$1"

  source "$HOME/.zshrc.local"
  source "$ZDOTDIR/src/zsh_python_init.zsh"
  source "$ZDOTDIR/src/darwin_pre_init.zsh"
  cd "$ZDOTDIR/src/python" || return 1
  command "$ZSH_PYTHON_BIN" -m meetingbar.read_json --json_path "$json_file"
}
