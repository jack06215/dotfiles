function meetingbar_send_notification() {
  local json_file="$1"

  source "$HOME/.zshrc.local"
  source "$HOME/.zsh/zsh_python_init.zsh"
  source "$HOME/.zsh/darwin_pre_init.zsh"
  cd "$HOME/.zsh/python" || return 1
  command "$ZSH_PYTHON_BIN" -m meetingbar.read_json --json_path "$json_file"
}
