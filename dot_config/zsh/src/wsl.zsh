#!/usr/bin/env zsh
# shellcheck shell=bash
#
# WSL2. /etc/wsl.conf sets appendWindowsPath=false, so no Windows directory is
# on PATH to begin with: Windows binaries used here go by absolute path, and
# the few Windows dirs worth having are appended *last*. A lookup that reaches
# /mnt/c goes through the 9P file server - ~20ms per directory per miss
# against ~1ms locally - so a Windows dir ahead of brew slows down every
# command-not-found and every first use of a brew command.
#
# The clipboard is not here: ~/.local/bin/pbcopy and pbpaste (rendered only
# on WSL2, from dot_local/bin) wrap win32yank.exe as real executables, so
# tmux, lazygit, nvim and scripts can use them too, not just this shell.

# Paste the clipboard into this shell, after showing it and asking.
function pbexec() {
  pbpaste | sed -n '1,200p'
  printf "\n----- execute? -----[y/N]: "
  read -r ans
  [[ "$ans" == "y" ]] && source <(pbpaste)
}

function pwsh() {
  command "/mnt/c/Program Files/PowerShell/7/pwsh.exe" "$@"
}

# WSL's GPU driver shims (nvidia-smi, libcuda) - local, so cheap - then
# chocolatey (win32yank.exe, ...) and VS Code's `code` launcher. $WIN_HOME
# comes from ~/.zshenv; (N-/) drops a dir that isn't there.
path+=(
  "/usr/lib/wsl/lib"(N-/)
  "/mnt/c/ProgramData/chocolatey/bin"(N-/)
  "$WIN_HOME/AppData/Local/Programs/Microsoft VS Code/bin"(N-/)
)
alias win32yank='win32yank.exe'

export BROWSER=wslview

# Tell WezTerm the working directory (OSC 7), so a new tab or split in the WSL
# domain opens where this shell is. On macOS WezTerm reads a local process's
# cwd itself; across the WSL boundary only the shell can report it.
function _wsl_osc7_cwd() {
  local url_path="${PWD//\%/%25}"
  url_path="${url_path// /%20}"
  printf '\e]7;file://%s%s\e\\' "$HOST" "$url_path"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _wsl_osc7_cwd
