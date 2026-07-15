#!/usr/bin/env zsh
# vim: filetype=zsh

function fman() {
  local cmd
  cmd=$(print -rl -- ${(k)commands} | fzf) || return
  man -- "$cmd"
}

# ==== Helpers =================================================================
function topcmds() {
  local n=${1:-10}
  history | awk '{print $2}' | sort | uniq -c | sort -nr | head -n "$n"
}

function mkcd() {
  if [ ! -n "$1" ]; then
    echo "Enter a directory name"
  elif [ -d $1 ]; then
    echo "\`$1' already exists"
  else
    mkdir $1 && cd $1
  fi
}

function pbpaste_dump() {
  local filename="dump_pbpaste_$(head -c 16 /dev/urandom | shasum -a 256 | head -c 8).txt"
  pbpaste | nl -s" | " -w3 -nln > "$filename"
  echo "Saved clipboard to $filename"
}

function send_notification() {
  msg="$1"
  title="${2:-Notification}"
  subtitle="$3"
  sound="$4"
  open_url="$5"

  if ! command -v terminal-notifier > /dev/null 2>&1; then
    echo "send_notification: terminal-notifier not found (brew install terminal-notifier)" >&2
    return 127
  fi

  if [[ -n "$sound" ]]; then
    terminal-notifier \
      -message "$msg" \
      -title "$title" \
      ${subtitle:+-subtitle "$subtitle"} \
      -sound "$sound" \
      ${open_url:+-open "$open_url"}
  else
    terminal-notifier \
      -message "$msg" \
      -title "$title" \
      ${subtitle:+-subtitle "$subtitle"} \
      ${open_url:+-open "$open_url"}
  fi
}

function preview_sound() {
  select s in /System/Library/Sounds/*.aiff; do
    [[ -n "$s" ]] && afplay "$s"
  done
}

function notify_action_required() { send_notification "$1" "Action required" "" "Funk"; }
function notify_news() { send_notification "$1" "Take a look" "" "Glass"; }
function notify_error() { send_notification "$1" "Attention!" "" "Basso"; }
function notify_youve_got_mail() { send_notification "$1" "You've got mail" "" "YouveGotMail"; }

function activate_poetry_env() {
  local venv_path
  venv_path="$(poetry env info --path 2> /dev/null)"

  if [[ -z "$venv_path" ]]; then
    echo "No Poetry environment found."
    return 1
  fi

  source "$venv_path/bin/activate"

  if [[ ":$PATH:" != *":$venv_path/bin:"* ]]; then
    export PATH="$venv_path/bin:$PATH"
  fi

  export VIRTUAL_ENV="$venv_path"
  echo "Activated Poetry venv from $venv_path"
}

function deactivate_poetry_env() {
  if [[ -z "$VIRTUAL_ENV" ]]; then
    echo "No Poetry venv is currently active."
    return 1
  fi

  local venv_path="$VIRTUAL_ENV"
  export PATH="$(echo "$PATH" | sed "s#$venv_path/bin:##")"
  unset VIRTUAL_ENV

  if type deactivate &> /dev/null; then
    deactivate 2> /dev/null
  fi

  echo "Deactivated Poetry venv ← $venv_path"
}

function ls_stats() {
  (
    echo "permissions,size,user,date,name"
    eza -l \
      --no-symlinks \
      --time-style=iso \
      --color=never \
      --total-size \
      | sed -E '
            s/[+@]/ /g;
            s/^[[:space:]]+//;
            s/[[:space:]]+/,/g
        '
  )
}

function csv2yml() {
  (($# >= 1)) || {
    print -u2 'usage: csv2yaml <file.csv> [col1,col2,...]'
    return 2
  }
  local file=$1
  local pipeline="open \"$file\""
  if [[ -n $2 ]]; then
    local -a cols=("${(@s:,:)2}") # split $2 on commas
    local c quoted=()
    for c in "${cols[@]}"; do quoted+=("\"$c\""); done
    pipeline+=" | select ${quoted[*]}"
  fi
  nu -c "$pipeline | to yaml"
}

function csv2json() {
  if [[ "$1" == "--no-header" ]]; then
    (($# >= 2)) || {
      print -u2 'csv2json --no-header requires column names'
      return 1
    }
    local -a cols=("${(@s:,:)2}")
    local c quoted=()
    for c in "${cols[@]}"; do quoted+=("\"$c\""); done
    nu --stdin -c "from csv --noheaders | rename ${quoted[*]} | to json"
  else
    nu --stdin -c "from csv | to json"
  fi
}

function jsonl2yml() {
  nu --stdin -c '
      from json --objects
      | to yaml
    '
}

function export_secret {
  local var_name="$1"
  local secret=""

  echo -n "Enter ${var_name}: " >&2
  read -rs secret
  echo >&2

  printf -v "${var_name}" '%s' "${secret}"
  export "${var_name}"

  echo "Exported: ${var_name}=***" >&2
}
