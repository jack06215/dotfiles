# shellcheck shell=bash
# shellcheck disable=SC2190

# Orca's own settings (everything on its Settings screen) live in a SQLite
# profile database, not a file: no settings file, CLI or import can set them
# from here, and the app writes its in-memory copy back over an outside edit.
# Its shortcuts are the exception (dot_orca/keybindings.json), as is the
# monorepo's orca.yaml. So the settings these dotfiles rely on are listed
# below, and orca_settings_check reports the ones the app is not on; fixing
# one is a trip to Settings (Cmd-,).
#
# Each entry, keyed by its path in the settings JSON, is
#   <jq test on the value>|<where in Settings, and what to pick>|<why>
# A key the app has never written reads as null and so fails its test: it is
# reported, not taken to be at whatever its default may be.
typeset -gA _ORCA_SETTINGS=(
  terminalMacOptionAsAlt '. == "true"|Terminal > Option as Alt: Both|tmux M-h/j/k/l, M-v/b/y/t and nvim <A-j>/<A-k>; Auto composes on any layout but U.S. and ABC'
  terminalFontFamily 'type == "string" and startswith("PlemolJP Console NF")|Terminal > Font: PlemolJP Console NF|the Nerd Font glyphs starship, tmux-powerline and nvim draw'
  terminalThemeDark '. == "Catppuccin Mocha"|Terminal > Dark Theme: Catppuccin Mocha|what tmux-powerline, vi_mode.zsh and lynx are matched to, as in wezterm.lua'
  terminalUseSeparateLightTheme '. == false|Terminal > Light Theme: off (use the dark theme)|keeps Mocha when macOS is in light mode'
  terminalMinimumContrastRatio '. == 1|Terminal > Color Contrast: Off|Automatic shifts text colours; WezTerm draws the theme as is'
  terminalCursorBlink '. == false|Terminal > Blinking Cursor: off|a steady block, as in WezTerm; nvim sets its own shapes'
  terminalScrollbackRows '. >= 10000|Terminal > Advanced > Scrollback Rows: 10000|scrollback_lines in wezterm.lua'
  terminalMouseHideWhileTyping '. == true|Terminal > Hide Mouse While Typing: on|as WezTerm does by default'
  terminalAllowOsc52Clipboard '. == true|Terminal > Allow TUI Clipboard Writes (OSC 52): on|how tmux set-clipboard and nvim reach the system clipboard'
  terminalLinkClickBehavior '. == "open"|Browser > Terminal URL clicks: Open URL|a plain click opens the link, as in WezTerm'
  notifications.terminalBell '. == true|Notifications > Terminal Bell: on|Claude (preferredNotifChannel) and agent-hatch ring the bell from background tabs'
  agentStatusHooksEnabled '. == true|Agents > Agent status hooks: on|the Orca hook in claude/settings.json.tmpl reports through them'
  agentPermissionDefault '. == "own" or . == "ask"|Agents > Agent permissions: Manual|Yolo launches Claude with --dangerously-skip-permissions'
  telemetry.optedIn '. == false|Privacy & Telemetry: off|as telemetry.telemetryLevel off in VS Code'
)

# A zsh hash has no order of its own, so the report takes its order from here.
# Option as Alt is a macOS setting.
_ORCA_ORDER=()
[[ "$OSTYPE" == darwin* ]] && _ORCA_ORDER+=(terminalMacOptionAsAlt)
_ORCA_ORDER+=(
  terminalFontFamily
  terminalThemeDark
  terminalUseSeparateLightTheme
  terminalMinimumContrastRatio
  terminalCursorBlink
  terminalScrollbackRows
  terminalMouseHideWhileTyping
  terminalAllowOsc52Clipboard
  terminalLinkClickBehavior
  notifications.terminalBell
  agentStatusHooksEnabled
  agentPermissionDefault
  telemetry.optedIn
)

# The default profile's database. Only the macOS location has been seen;
# `orca agent hooks status` prints the profile directory it uses.
function _orca_profile_db() {
  print -r -- "$HOME/Library/Application Support/orca/profiles/local-default/profile-state.db"
}

# Print the settings JSON from a copy of <db>, its -wal and -shm included: the
# live files stay Orca's alone, and the write-ahead log holds whatever the app
# has not checkpointed into the database yet.
function _orca_settings_json() {
  local db="$1" tmp f rc
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/orca-settings.XXXXXX") || return 1

  for f in "$db" "$db-wal" "$db-shm"; do
    [[ -e "$f" ]] || continue
    cp "$f" "$tmp/" || {
      rm -rf "$tmp"
      return 1
    }
  done

  sqlite3 "$tmp/${db:t}" "select payload from profile_state_documents where domain = 'settings'"
  rc=$?
  rm -rf "$tmp"
  return $rc
}

function orca_settings_check() {
  local cmd
  for cmd in sqlite3 jq; do
    command -v "$cmd" > /dev/null 2>&1 || {
      echo "orca_settings_check: $cmd not found" >&2
      return 127
    }
  done

  if [[ "$OSTYPE" != darwin* ]]; then
    echo "orca_settings_check: only Orca's macOS profile location is known" >&2
    return 1
  fi

  local db json
  db=$(_orca_profile_db)
  if [[ ! -r "$db" ]]; then
    echo "orca_settings_check: no Orca profile at $db (has Orca been opened yet?)" >&2
    return 1
  fi
  json=$(_orca_settings_json "$db")
  if [[ $? -ne 0 || -z "$json" ]]; then
    echo "orca_settings_check: could not read the settings from $db" >&2
    return 1
  fi

  local key test where why value fixes=0
  for key in "${_ORCA_ORDER[@]}"; do
    IFS='|' read -r test where why <<< "${_ORCA_SETTINGS[$key]}"
    if jq -e ".$key | $test" <<< "$json" > /dev/null 2>&1; then
      printf '  ok   %s\n' "$where"
    else
      value=$(jq -c ".$key" <<< "$json")
      printf '  fix  %s  (now %s)\n       %s\n' "$where" "$value" "$why"
      fixes=$((fixes + 1))
    fi
  done

  if ((fixes == 0)); then
    echo "Orca's settings match."
    return 0
  fi
  echo "$fixes to change in Orca > Settings (Cmd-,)."
  return 1
}
