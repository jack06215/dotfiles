function meetingbar_send_notification() {
  local json_file="$1"

  source "$HOME/.zshrc.local"
  source "$XDG_CONFIG_HOME/zsh/src/zsh_python_init.zsh"
  source "$XDG_CONFIG_HOME/zsh/src/darwin_pre_init.zsh"
  cd "$XDG_CONFIG_HOME/zsh/src/python" || return 1
  command "$ZSH_PYTHON_BIN" -m meetingbar.read_json --json_path "$json_file"
}
