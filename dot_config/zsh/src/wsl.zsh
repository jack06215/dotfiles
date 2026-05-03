function pbpaste() {
  win32yank.exe -o --lf
}

function pbcopy() {
  win32yank.exe -i --crlf
}


function pbexec() {
  pbpaste | sed -n '1,200p'
  printf "\n----- execute? -----[y/N]: "
  read -r ans
  [[ "$ans" == "y" ]] && source <(pbpaste)
}

function pwsh() {
  command "/mnt/c/Program Files/PowerShell/7/pwsh.exe" "$@"
}

# function terminal-notifier() {
#   local title="${1:-通知}"
#   local body="${2:-メッセージ}"
#   pwsh -NoProfile -Command \
#     'New-BurntToastNotification `
#       -AppLogo "C:\Users\jack0\Pictures\41322830.jpeg" `
#       -Text '$title','$body''
# }

alias 'win32yank=win32yank.exe'

export WIN_USER="$(
  pwsh  -NoProfile -Command '[System.IO.Path]::GetFileName($env:USERPROFILE)' \
  | tr -d '\r'
)"

# system
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/sbin:$PATH"
export PATH="/usr/bin:$PATH"
export PATH="/sbin:$PATH"
export PATH="/bin:$PATH"
export PATH="/usr/lib/wsl/lib:$PATH"

# GPU
export PATH="/mnt/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.8/bin:$PATH"

# homebrew
export HOMEBREW_HOME="/home/linuxbrew/.linuxbrew"
export PATH="$HOMEBREW_HOME/bin:$PATH"
export PATH="$HOMEBREW_HOME/sbin:$PATH"

# bun
export BUN_INSTALL="$HOME/Library/Application Support/reflex/bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# chocolatey
export PATH="/mnt/c/ProgramData/chocolatey/bin:$PATH"

# VS code
export PATH="$PATH:/mnt/c/Users/jack0/AppData/Local/Programs/Microsoft VS Code/bin"

# Browser
export BROWSER=wslview
