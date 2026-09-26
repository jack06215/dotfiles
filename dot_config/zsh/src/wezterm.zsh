# shellcheck shell=bash
# shellcheck disable=SC1091

source "$ZDOTDIR/src/functions.zsh"

# The appearance values wezterm_config tunes, keyed by the name the state file
# and wezterm.lua both use, as
#   <label>|<min>|<max>|<step>|<default>    a number
#   <label>|<choice,choice,...>|||<default> one of a fixed set of words
#
# The defaults must match the `appearance` table at the top of
# dot_config/wezterm/wezterm.lua, which is what applies on a machine whose
# state file does not exist yet.
#
# The two opacities are authored here as a 0-100 percentage and divided by 100
# on the Lua side; the blur is a point radius WezTerm takes as-is. The backdrop
# is Windows-only: Mica and Tabbed only show at window opacity 0.
typeset -gA _WEZTERM_SETTINGS=(
  windowBackgroundOpacity "Window background opacity|0|100|5|65"
  textBackgroundOpacity "Text background opacity|0|100|5|50"
  macosWindowBackgroundBlur "macOS background blur radius|0|100|5|20"
  win32SystemBackdrop "Windows backdrop|Acrylic,Mica,Tabbed,Disable|||Acrylic"
)

# A zsh hash has no order of its own - for these keys ${(k)…} comes back
# neither authored nor alphabetical - so the menu takes its order from here.
# Each platform lists only what its WezTerm reads.
_WEZTERM_ORDER=(
  windowBackgroundOpacity
  textBackgroundOpacity
)
if [[ "$OSTYPE" == darwin* ]]; then
  _WEZTERM_ORDER+=(macosWindowBackgroundBlur)
elif [[ -n "$WIN_HOME" ]]; then
  _WEZTERM_ORDER+=(win32SystemBackdrop)
fi

# Print one named field of <key>'s record. `key` is not among them: it is the
# hash key rather than part of the record.
function _wezterm_field() {
  local key="$1" name="$2"
  local label min max step default

  ((${+_WEZTERM_SETTINGS[$key]})) || return 1
  IFS='|' read -r label min max step default <<< "${_WEZTERM_SETTINGS[$key]}"

  case "$name" in
    label) print -r -- "$label" ;;
    min) print -r -- "$min" ;;
    max) print -r -- "$max" ;;
    step) print -r -- "$step" ;;
    default) print -r -- "$default" ;;
    *) return 1 ;;
  esac
}

# Choice settings keep their word list where numbers keep their minimum.
function _wezterm_is_choice() {
  [[ "$(_wezterm_field "$1" min)" == *[^0-9]* ]]
}

# wezterm.lua reads the state from ~/.local/state of the machine WezTerm runs
# on. On WSL2 that is Windows ($WIN_HOME, from ~/.zshenv), not this home.
function _wezterm_state_file() {
  if [[ -n "$WIN_HOME" ]]; then
    print -r -- "$WIN_HOME/.local/state/wezterm/appearance.json"
  else
    print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/wezterm/appearance.json"
  fi
}

function _wezterm_get() {
  local key="$1" file value
  file=$(_wezterm_state_file)

  if [[ -r "$file" ]]; then
    value=$(jq -r --arg k "$key" '.[$k] // empty' "$file" 2> /dev/null)
    if [[ -n "$value" ]]; then
      print -r -- "$value"
      return 0
    fi
  fi

  _wezterm_field "$key" default
}

function _wezterm_set() {
  local key="$1" value="$2" file dir tmp rc
  file=$(_wezterm_state_file)
  dir="${file:h}"

  mkdir -p "$dir" || return 1
  tmp=$(mktemp "$dir/.appearance.XXXXXX") || return 1

  # Numbers as JSON numbers, choices as strings.
  local -a vflag=(--argjson v "$value")
  [[ "$value" == <-> ]] || vflag=(--arg v "$value")

  if [[ -r "$file" ]]; then
    jq --arg k "$key" "${vflag[@]}" '.[$k] = $v' "$file" > "$tmp"
  else
    jq -n --arg k "$key" "${vflag[@]}" '{($k): $v}' > "$tmp"
  fi
  rc=$?

  if ((rc != 0)); then
    rm -f "$tmp"
    echo "wezterm_config: failed to write $file" >&2
    return 1
  fi

  mv -f "$tmp" "$file"
}

# wezterm.lua reads the state file at load time and watches it, so there is
# nothing to render. Touching wezterm.lua as well makes WezTerm reload even
# when the state file was only just created and is not on its watch list yet.
function _wezterm_apply() {
  local config
  if [[ -n "$WIN_HOME" ]]; then
    config="$WIN_HOME/.config/wezterm/wezterm.lua"
  else
    config="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/wezterm.lua"
  fi
  [[ -f "$config" ]] && touch "$config"
  return 0
}

function _wezterm_set_and_apply() {
  local key="$1" value="$2" previous
  previous=$(_wezterm_get "$key")

  _wezterm_set "$key" "$value" || return 1

  _wezterm_apply && return 0

  _wezterm_set "$key" "$previous" && _wezterm_apply > /dev/null 2>&1
  echo "wezterm_config: apply failed, restored $key=$previous" >&2
  return 1
}

function _wezterm_valid() {
  local value="$1" min="$2" max="$3"

  # A choice setting passes its comma-separated words as `min`.
  if [[ "$min" == *[^0-9]* ]]; then
    ((${${(s:,:)min}[(Ie)$value]}))
    return
  fi

  [[ "$value" == <-> ]] || return 1
  ((value >= min && value <= max))
}

# The choice-setting counterpart of _wezterm_tune: one pick, applied at once.
function _wezterm_choose() {
  local key="$1" label current choice
  label=$(_wezterm_field "$key" label) || return 1
  current=$(_wezterm_get "$key")

  choice=$(print -rl -- ${(s:,:)$(_wezterm_field "$key" min)} \
    | gum choose --header="${label}: ${current}" --selected="$current") || return 1
  [[ -n "$choice" && "$choice" != "$current" ]] || return 0

  _wezterm_set_and_apply "$key" "$choice" || return 1
  gum log --level info "saved" "$label" "$choice"
}

function _wezterm_tune() {
  local key="$1" from_menu="${2:-}"
  local label min max step original current applied action input
  local -a actions

  if _wezterm_is_choice "$key"; then
    _wezterm_choose "$key" || return 1
    [[ -n "$from_menu" ]] && return 2
    return 0
  fi

  label=$(_wezterm_field "$key" label) || return 1
  min=$(_wezterm_field "$key" min)
  max=$(_wezterm_field "$key" max)
  step=$(_wezterm_field "$key" step)

  original=$(_wezterm_get "$key")
  current="$original"
  applied="$original"

  while true; do
    actions=(
      "up       +${step}|up"
      "down     -${step}|down"
      "set      type an exact value|set"
      "keep     save ${current} and exit|keep"
      "revert   restore ${original} and exit|revert"
    )
    [[ -n "$from_menu" ]] && actions+=("back     save ${current} and pick another setting|back")

    action=$(printf '%s\n' "${actions[@]}" \
      | gum choose --label-delimiter="|" \
        --height=$((${#actions} + 2)) \
        --header="${label}: ${current}  (was ${original}, range ${min}-${max})") || {
      [[ "$applied" == "$original" ]] || _wezterm_set_and_apply "$key" "$original"
      return 1
    }

    case "$action" in
      up) ((current + step <= max)) && current=$((current + step)) ;;
      down) ((current - step >= min)) && current=$((current - step)) ;;
      set)
        input=$(gum input --header="${label} (${min}-${max})" --value="$current") || continue
        if ! _wezterm_valid "$input" "$min" "$max"; then
          gum log --level error "not a whole number in ${min}-${max}" value "$input"
          continue
        fi
        current="$input"
        ;;
      keep)
        gum log --level info "saved" "$label" "$current"
        return 0
        ;;
      revert)
        [[ "$applied" == "$original" ]] || _wezterm_set_and_apply "$key" "$original"
        gum log --level info "reverted" "$label" "$original"
        return 0
        ;;
      back)
        gum log --level info "saved" "$label" "$current"
        return 2
        ;;
    esac

    # Only when it actually moved: hitting up at the ceiling should not cost a
    # reload.
    if [[ "$current" != "$applied" ]]; then
      if ! _wezterm_set_and_apply "$key" "$current"; then
        # The failed step already undid itself, but earlier previews from this
        # session are still on disk. Bail out the way escaping does, so a broken
        # apply cannot leave a value behind that was never kept.
        [[ "$applied" == "$original" ]] || _wezterm_set_and_apply "$key" "$original"
        return 1
      fi
      applied="$current"
    fi
  done
}

function wezterm_config() {
  _check_gum_cmd || return 1

  local cmd
  for cmd in jq; do
    command -v "$cmd" > /dev/null 2>&1 || {
      echo "wezterm_config: $cmd not found" >&2
      return 127
    }
  done

  local key="${1:-}" value="${2:-}"
  local min max

  if [[ -n "$key" ]]; then
    ((${+_WEZTERM_SETTINGS[$key]})) || {
      echo "wezterm_config: unknown setting '$key'. Known settings:" >&2
      printf '  %s\n' "${(@ko)_WEZTERM_SETTINGS}" >&2
      return 2
    }
    min=$(_wezterm_field "$key" min)
    max=$(_wezterm_field "$key" max)

    [[ -n "$value" ]] || {
      _wezterm_tune "$key"
      return $?
    }

    _wezterm_valid "$value" "$min" "$max" || {
      if _wezterm_is_choice "$key"; then
        echo "wezterm_config: '$value' is not one of: ${min//,/, }" >&2
      else
        echo "wezterm_config: '$value' is not a whole number in ${min}-${max}" >&2
      fi
      return 2
    }

    _wezterm_set_and_apply "$key" "$value" || return 1
    gum log --level info "saved" "$(_wezterm_field "$key" label)" "$value"
    return 0
  fi

  local k label choice rc
  local -a menu

  while true; do
    menu=()
    for k in "${_WEZTERM_ORDER[@]}"; do
      label=$(_wezterm_field "$k" label)
      menu+=("$(printf '%-26s %-30s %s' "$k" "$label" "$(_wezterm_get "$k")")")
    done

    choice=$(printf '%s\n' "${menu[@]}" \
      | gum filter --header="Which WezTerm appearance value?" \
        --placeholder="type to filter") || return
    [[ -n "$choice" ]] || return

    _wezterm_tune "${choice%% *}" menu
    rc=$?

    # Anything but "back to the menu" is this function's own result: a saved
    # value, a revert, or a picker that was escaped out of.
    ((rc == 2)) || return "$rc"
  done
}
