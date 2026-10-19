#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC2296
#
# notify <message> [title] [subtitle] [sound] [url] - a desktop notification.
# macOS: terminal-notifier. WSL2: a Windows toast via BurntToast (PowerShell 7).
# Termux: an Android notification via termux-api's termux-notification.
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

  # Optional flags go through an array: zsh does not split an unquoted
  # ${var:+-flag "$var"} into two words, so that form handed terminal-notifier
  # "-sound Glass" as one argument and the subtitle, sound and URL were lost.
  local -a args=(-message "$msg" -title "$title")
  [[ -n "$subtitle" ]] && args+=(-subtitle "$subtitle")
  [[ -n "$sound" ]] && args+=(-sound "$sound")
  [[ -n "$open_url" ]] && args+=(-open "$open_url")

  command terminal-notifier "${args[@]}"
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

# Termux backend (termux-notification, from the termux-api package; the
# Termux:API app has to be installed too)
_notify_termux() {
  local msg="$1"
  local title="$2"
  local subtitle="$3"
  local sound="$4"
  local open_url="$5"

  if ! command -v termux-notification >/dev/null 2>&1; then
    echo "notify: termux-notification not found (pkg install termux-api)" >&2
    return 127
  fi

  # -c even for an empty message: without it termux-notification waits 3s for
  # one on stdin. An Android notification has no subtitle line, so the
  # subtitle joins the title.
  local -a args=(-c "$msg" -t "$title${subtitle:+ - $subtitle}")

  # Android has one default sound rather than macOS's named ones, and from
  # Android 8 on even that is a setting of the notification channel, not of
  # each notification: termux-api posts on a single channel, so whether these
  # ring or pop up is set under Termux:API's notification settings. --sound
  # only does anything on older Android.
  [[ -n "$sound" ]] && args+=(--sound)

  # Tapping the notification opens the URL. termux-api runs the action under
  # /system/bin/sh without Termux's environment, hence the explicit PATH (for
  # termux-open-url and the `am` it calls); (qq) single-quotes the URL for
  # that shell.
  [[ -n "$open_url" ]] \
    && args+=(--action "PATH=/data/data/com.termux/files/usr/bin:\$PATH termux-open-url ${(qq)open_url}")

  command termux-notification "${args[@]}"
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
  elif [[ "$OSTYPE" == linux-android* ]]; then
    _notify_termux "$msg" "$title" "$subtitle" "$sound" "$open_url"
  else
    echo "notify: unsupported platform ($OSTYPE)" >&2
    return 1
  fi
}
