#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC2296

# macOS backend (terminal-notifier)
_notify_macos() {
  local msg="$1"
  local title="$2"
  local subtitle="$3"
  local sound="$4"
  local open_url="$5"

  if ! command -v terminal-notifier >/dev/null 2>&1; then
    echo "notify: terminal-notifier not found (brew install terminal-notifier)" >&2
    return 127
  fi

  command terminal-notifier \
    -message "$msg" \
    -title "$title" \
    ${subtitle:+-subtitle "$subtitle"} \
    ${sound:+-sound "$sound"} \
    ${open_url:+-open "$open_url"}
}

# WSL backend (BurntToast via PowerShell)
_notify_wsl() {
  local msg="$1"
  local title="$2"
  local subtitle="$3"
  local sound="$4"
  local open_url="$5"

  # Build PowerShell Text array (max 3 lines)
  local ps_text=()
  ps_text+=("'$title'")
  [[ -n "$subtitle" ]] && ps_text+=("'$subtitle'")
  ps_text+=("'$msg'")

  local ps_text_joined
  ps_text_joined=$(IFS=,; echo "${ps_text[*]}")

  # Optional button for URL
  local ps_button=""
  if [[ -n "$open_url" ]]; then
    ps_button="-Button (New-BTButton -Content 'Open' -Arguments '$open_url')"
  fi

  pwsh -NoProfile -Command "
    Import-Module BurntToast -ErrorAction SilentlyContinue
    New-BurntToastNotification \
      -AppLogo 'C:\Users\jack0\Pictures\41322830.jpeg' \
      -Text $ps_text_joined \
      $ps_button
  "
}

# Public API
function notify() {
  local msg="$1"
  local title="${2:-Notification}"
  local subtitle="$3"
  local sound="$4"
  local open_url="$5"

  if is_macos; then
    _notify_macos "$msg" "$title" "$subtitle" "$sound" "$open_url"
  elif is_wsl; then
    _notify_wsl "$msg" "$title" "$subtitle" "$sound" "$open_url"
  else
    echo "notify: unsupported platform ($OSTYPE)" >&2
    return 1
  fi
}
