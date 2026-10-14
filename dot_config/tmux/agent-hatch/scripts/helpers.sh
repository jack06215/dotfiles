#!/usr/bin/env bash
# Shared helpers for agent-hatch.

# get_tmux_option <option-name> <default>
# Echoes the global tmux option value, or the default when unset/empty.
get_tmux_option() {
  local value
  value="$(tmux show-option -gqv "$1" 2>/dev/null)"
  if [ -n "$value" ]; then
    printf '%s' "$value"
  else
    printf '%s' "$2"
  fi
}

# agent_title <agent>
# The agent's name as a title: "claude" -> "Claude". Not ${1^}, which needs
# bash 4 and macOS still ships 3.2.
agent_title() {
  printf '%s%s' "$(printf '%s' "${1:0:1}" | tr '[:lower:]' '[:upper:]')" "${1:1}"
}

# session_hash <string>
# Short, stable, portable 8-char hash for deriving a session name from a path.
# Prefers md5sum (Linux), falls back to md5 (macOS) then shasum. The trailing
# newline matches the conventional `echo "$path" | md5sum` scheme, so it stays
# compatible with sessions created that way.
session_hash() {
  local out
  if command -v md5sum >/dev/null 2>&1; then
    out="$(printf '%s\n' "$1" | md5sum)"
  elif command -v md5 >/dev/null 2>&1; then
    out="$(printf '%s\n' "$1" | md5 -q)"
  else
    out="$(printf '%s\n' "$1" | shasum)"
  fi
  out="${out%% *}"
  printf '%s' "${out:0:8}"
}

# copy_to_clipboard <text>
# Puts <text> in a tmux paste buffer and on the system clipboard. A native tool
# is preferred; without one, `set-buffer -w` hands it to the outer terminal via
# OSC 52, which works only when `set-clipboard` is on and the terminal allows it.
copy_to_clipboard() {
  local tool
  for tool in pbcopy wl-copy 'xclip -selection clipboard' 'xsel --clipboard --input'; do
    command -v "${tool%% *}" >/dev/null 2>&1 || continue
    printf '%s' "$1" | $tool 2>/dev/null && {
      tmux set-buffer -- "$1" 2>/dev/null
      return 0
    }
  done
  tmux set-buffer -w -- "$1" 2>/dev/null
}
