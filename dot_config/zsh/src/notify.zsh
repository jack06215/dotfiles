#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC2296
#
# notify <message> [title] [subtitle] [sound] [url] - a desktop notification.
# macOS: terminal-notifier. WSL2: a Windows toast via BurntToast (PowerShell 7).
#
# Self-contained - no core.zsh predicates - because send_notification
# (functions.zsh) sources this file on demand wherever it is called, including
# zshfn and tmux popups that never ran init.zsh.

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

# terminal-notifier takes macOS system sound names (see preview_sound);
# BurntToast's -Sound only knows its own short list. Map the ones this config
# passes, and play BurntToast's default for anything else. Only non-looping
# sounds: Alarm*/Call* ring until the toast is dismissed.
typeset -gA _NOTIFY_WSL_SOUNDS=(
  Funk Reminder
  Glass Default
  Basso SMS
  YouveGotMail Mail
)

# WSL backend (BurntToast via PowerShell 7)
_notify_wsl() {
  local msg="$1"
  local title="$2"
  local subtitle="$3"
  local sound="$4"
  local open_url="$5"
  local pwsh="/mnt/c/Program Files/PowerShell/7/pwsh.exe"

  if [[ ! -x "$pwsh" ]]; then
    echo "notify: PowerShell 7 not found at $pwsh" >&2
    return 127
  fi

  # The strings reach PowerShell as environment variables - WSLENV forwards
  # the listed names to Windows processes - and are never spliced into the
  # script, so quotes, $ and backticks in a message need no escaping. Empty
  # ones drop out of -Text (at most 3 lines: title, subtitle, message).
  NOTIFY_TITLE="$title" \
    NOTIFY_SUBTITLE="$subtitle" \
    NOTIFY_MSG="$msg" \
    NOTIFY_SOUND="${sound:+${_NOTIFY_WSL_SOUNDS[$sound]:-Default}}" \
    NOTIFY_URL="$open_url" \
    WSLENV="NOTIFY_TITLE:NOTIFY_SUBTITLE:NOTIFY_MSG:NOTIFY_SOUND:NOTIFY_URL${WSLENV:+:$WSLENV}" \
    "$pwsh" -NoProfile -NonInteractive -Command '
      Import-Module BurntToast -ErrorAction Stop
      $params = @{
        Text = @($env:NOTIFY_TITLE, $env:NOTIFY_SUBTITLE, $env:NOTIFY_MSG) | Where-Object { $_ }
      }
      $logo = Join-Path $env:USERPROFILE "Pictures\41322830.jpeg"
      if (Test-Path $logo) { $params.AppLogo = $logo }
      if ($env:NOTIFY_SOUND) { $params.Sound = $env:NOTIFY_SOUND }
      if ($env:NOTIFY_URL) {
        $params.Button = New-BTButton -Content "Open" -Arguments $env:NOTIFY_URL
      }
      New-BurntToastNotification @params
    '
}

# Public API
function notify() {
  local msg="$1"
  local title="${2:-Notification}"
  local subtitle="$3"
  local sound="$4"
  local open_url="$5"

  if [[ "$OSTYPE" == darwin* ]]; then
    _notify_macos "$msg" "$title" "$subtitle" "$sound" "$open_url"
  elif [[ -n "$WSL_DISTRO_NAME" ]]; then
    _notify_wsl "$msg" "$title" "$subtitle" "$sound" "$open_url"
  else
    echo "notify: unsupported platform ($OSTYPE)" >&2
    return 1
  fi
}
