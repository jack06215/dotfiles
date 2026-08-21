#!/usr/bin/env zsh
# vim: filetype=zsh

function _check_gum_cmd() {
  command -v gum > /dev/null 2>&1 || {
    # funcstack[2] is the calling function, so the message names it.
    echo "${funcstack[2]:-gum} requires 'gum' to be installed." >&2
    return 1
  }
}

function _check_fzf_cmd() {
  command -v fzf > /dev/null 2>&1 || {
    echo "${funcstack[2]:-fzf} requires 'fzf' to be installed." >&2
    return 1
  }
}

# $1 overrides the name in the message, for helpers that are called on behalf of
# the function the user actually typed.
function _check_nu_cmd() {
  command -v nu > /dev/null 2>&1 || {
    echo "${1:-${funcstack[2]:-nu}} requires 'nu' (nushell) to be installed." >&2
    return 1
  }
}

# encoding_rs, which backs nu's `decode` and `encode`, only answers to the
# WHATWG labels - so cp932 and eucjp, the names a Japanese CSV is usually
# described by, are hard errors until they are spelled its way.
function _nu_encoding_label() {
  local enc=${1:-utf-8}
  case ${enc:l} in
    cp932 | ms_kanji | ms-kanji) enc=shift-jis ;;
    eucjp | euc_jp) enc=euc-jp ;;
    utf8) enc=utf-8 ;;
  esac
  print -r -- "$enc"
}

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
  _check_gum_cmd || return 1

  local sound
  local -a names

  # :t:r reduces each path to its bare name, which is also the form
  # terminal-notifier's -sound flag wants - so whatever is picked here can be
  # passed straight to send_notification. N drops the glob when the directory
  # is empty rather than leaving the pattern unexpanded.
  names=(/System/Library/Sounds/*.aiff(N:t:r))

  ((${#names})) || {
    echo "No sounds found in /System/Library/Sounds." >&2
    return 1
  }

  # Loops the way the `select` builtin it replaces did, so several sounds can
  # be auditioned in a row; escaping the picker is what ends it.
  while sound=$(printf '%s\n' "${names[@]}" \
    | gum filter --header="Preview which sound? (esc to stop)" \
      --placeholder="sound"); do
    [[ -n "$sound" ]] || break
    afplay "/System/Library/Sounds/${sound}.aiff"
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

function _csv2_usage() {
  print -u2 -- "usage: $1 [options] [file|-] [col1,col2,...]

Reads stdin when no file (or '-') is given. The trailing column list selects and
reorders columns; with --no-header it names them instead.

  -c, --columns LIST   the column list, for when there is no file argument
  -n, --no-header      input has no header row (LIST supplies the names)
  -e, --encoding ENC   decode input as ENC (default: utf-8). Excel's Japanese
                       CSVs want shift-jis; cp932 and eucjp are also accepted
  -s, --separator SEP  field separator (default: ','; 'tab' for TSV)
  -i, --infer          let nushell type the fields; off by default so codes like
                       0123456 and 007 keep their leading zeros
      --flexible       allow rows with a varying number of fields
  -h, --help           this message"
}

# Shared reader behind csv2json/csv2jsonl/csv2yml. Nushell's CSV parser is
# RFC 4180 compliant, so quoted fields holding newlines, separators and doubled
# quotes come through whole, and its json/yaml writers emit non-ASCII literally
# rather than as \uXXXX escapes - so Japanese text stays readable.
#
# The file path and column names travel in the environment instead of being
# spliced into the nu source: both can contain quotes, and nu's single-quoted
# strings have no escape syntax to defend against that.
function _csv2() {
  local format=$1
  shift

  local caller=${funcstack[2]:-csv2json}
  _check_nu_cmd "$caller" || return 1

  local -a o_help o_cols o_noheader o_infer o_flexible o_enc o_sep
  zparseopts -D -E -F -- \
    h=o_help -help=o_help \
    c:=o_cols -columns:=o_cols \
    n=o_noheader -no-header=o_noheader \
    i=o_infer -infer=o_infer \
    e:=o_enc -encoding:=o_enc \
    s:=o_sep -separator:=o_sep \
    -flexible=o_flexible 2> /dev/null || {
      # zparseopts names the offending flag, but prefixes it with `_csv2`, which
      # is not a name the caller typed.
      print -u2 "$caller: unknown option; try '$caller --help'"
      return 2
    }

  ((${#o_help})) && {
    _csv2_usage "$caller"
    return 0
  }

  (($# > 2)) && {
    print -u2 "$caller: unexpected argument '$3'"
    return 2
  }

  local file=${1:-} cols=${2:-}
  if ((${#o_cols})); then
    [[ -z $cols ]] || {
      print -u2 "$caller: give the column list once, as --columns or as the trailing argument"
      return 2
    }
    cols=${o_cols[-1]}
  fi
  [[ $file == - ]] && file=''

  if [[ -n $file ]]; then
    [[ -r $file ]] || {
      print -u2 "$caller: cannot read '$file'"
      return 1
    }
  elif [[ -t 0 ]]; then
    _csv2_usage "$caller"
    return 2
  fi

  ((${#o_noheader})) && [[ -z $cols ]] && {
    print -u2 "$caller: --no-header needs a column list, e.g. $caller -n data.csv id,name"
    return 2
  }

  local enc
  enc=$(_nu_encoding_label "${o_enc[-1]:-utf-8}")

  local sep=${o_sep[-1]:-,}
  case $sep in
    tab | '\t') sep=$'\t' ;;
  esac

  local source_expr
  local -a nu_args=(-n -c)
  if [[ -n $file ]]; then
    source_expr='open --raw $env.__CSV2_FILE'
  else
    # nu hands stdin over already decoded as text whenever the bytes happen to
    # be valid UTF-8; going back to bytes lets `decode` apply --encoding
    # uniformly, whichever way the input arrived.
    nu_args=(-n --stdin -c)
    source_expr='$in | into binary'
  fi

  local csv_flags=' --separator $env.__CSV2_SEP'
  ((${#o_noheader})) && csv_flags+=' --noheaders'
  ((${#o_infer})) || csv_flags+=' --no-infer'
  ((${#o_flexible})) && csv_flags+=' --flexible'

  # A CRLF file keeps its CR inside multi-line quoted cells, so a two-line
  # address arrives as "...\r\n...". Drop it: a YAML block scalar cannot hold a
  # CR anyway, and normalising here is what keeps the yaml and json output
  # describing the same string.
  local normalize=' | update cells {|v| if ($v | describe) == "string" { $v | str replace --all "\r\n" "\n" | str replace --all "\r" "\n" } else { $v } }'

  local emit
  case $format in
    json) emit=' | to json' ;;
    jsonl) emit=' | each {|row| $row | to json --raw } | to text' ;;
    yaml) emit=' | to yaml' ;;
  esac

  local -a script=(
    "let rows = (${source_expr} | decode \$env.__CSV2_ENC | from csv${csv_flags}${normalize})"
  )
  if [[ -z $cols ]]; then
    script+=("\$rows${emit}")
  elif ((${#o_noheader})); then
    script+=("\$rows | rename ...(\$env.__CSV2_COLS | split row ',')${emit}")
  else
    # Left to `select`, a typo'd column reports itself against the environment
    # block the name arrived in, which tells the caller nothing. Say which name
    # missed and what the header actually holds - worth the detour when the
    # headers are Japanese and a stray full-width space is invisible.
    script+=(
      'let want = ($env.__CSV2_COLS | split row ",")'
      'let missing = ($want | where {|c| $c not-in ($rows | columns)})'
      'if not ($missing | is-empty) {'
      # The joins stay out of the interpolated string: a quote inside a `(...)`
      # subexpression closes the string early and the script fails to parse.
      '  let names = ($missing | str join ", ")'
      '  let have = ($rows | columns | str join ", ")'
      '  error make --unspanned { msg: $"no such column: ($names) -- header has: ($have)" }'
      '}'
      "\$rows | select ...\$want${emit}"
    )
  fi

  __CSV2_FILE=$file __CSV2_COLS=$cols __CSV2_ENC=$enc __CSV2_SEP=$sep \
    nu "${nu_args[@]}" "${(F)script}"
}

function csv2json() { _csv2 json "$@"; }
function csv2jsonl() { _csv2 jsonl "$@"; }
function csv2yml() { _csv2 yaml "$@"; }

function _jsonl2csv_usage() {
  print -u2 -- "usage: jsonl2csv [options] [file|-] [col1,col2,...]

Reads stdin when no file (or '-') is given. JSONL is UTF-8 by definition, so
--encoding names the *output* encoding here - the opposite of csv2jsonl's.

  -c, --columns LIST   emit only these columns, in this order
  -e, --encoding ENC   encode output as ENC (default: utf-8). Japanese Excel
                       wants shift-jis; cp932 and eucjp are also accepted
  -b, --bom            prepend a UTF-8 BOM, which is what makes Excel read a
                       UTF-8 CSV as UTF-8 rather than as cp932
  -s, --separator SEP  output separator (default: ','; 'tab' for TSV)
  -n, --no-header      omit the header row
  -h, --help           this message"
}

# The reverse of csv2jsonl, and the one worth reversing: a JSONL record is always
# exactly one line - a multi-line cell travels as an escaped \\n inside the
# string - so nothing line-oriented breaks on the way back, and any conformant
# parser reads the values as written. Round-tripping via yaml is what loses data:
# `to yaml` leaves a cell like 12:30:45 unquoted, and a YAML 1.1 parser reads
# that back as the integer 45045.
function jsonl2csv() {
  local caller=${funcstack[1]:-jsonl2csv}
  _check_nu_cmd "$caller" || return 1

  local -a o_help o_cols o_enc o_bom o_sep o_noheader
  zparseopts -D -E -F -- \
    h=o_help -help=o_help \
    c:=o_cols -columns:=o_cols \
    e:=o_enc -encoding:=o_enc \
    b=o_bom -bom=o_bom \
    s:=o_sep -separator:=o_sep \
    n=o_noheader -no-header=o_noheader 2> /dev/null || {
      print -u2 "$caller: unknown option; try '$caller --help'"
      return 2
    }

  ((${#o_help})) && {
    _jsonl2csv_usage
    return 0
  }

  (($# > 2)) && {
    print -u2 "$caller: unexpected argument '$3'"
    return 2
  }

  local file=${1:-} cols=${2:-}
  if ((${#o_cols})); then
    [[ -z $cols ]] || {
      print -u2 "$caller: give the column list once, as --columns or as the trailing argument"
      return 2
    }
    cols=${o_cols[-1]}
  fi
  [[ $file == - ]] && file=''

  if [[ -n $file ]]; then
    [[ -r $file ]] || {
      print -u2 "$caller: cannot read '$file'"
      return 1
    }
  elif [[ -t 0 ]]; then
    _jsonl2csv_usage
    return 2
  fi

  local enc
  enc=$(_nu_encoding_label "${o_enc[-1]:-utf-8}")

  [[ -n ${o_bom[*]} && $enc != utf-8 ]] && {
    print -u2 "$caller: --bom applies to utf-8 output only, not $enc"
    return 2
  }

  # nu renders a binary value as a hex dump even when stdout is a pipe, so
  # encoded output has to leave through `save` instead of off the end of the
  # pipeline. A terminal is never where cp932 bytes were meant to go, so that
  # case is refused rather than turned into mojibake.
  [[ $enc != utf-8 && -t 1 ]] && {
    print -u2 "$caller: refusing to write $enc to the terminal; redirect to a file"
    return 1
  }

  local sep=${o_sep[-1]:-,}
  case $sep in
    tab | '\t') sep=$'\t' ;;
  esac

  local source_expr
  local -a nu_args=(-n -c)
  if [[ -n $file ]]; then
    source_expr='open --raw $env.__J2C_FILE'
  else
    nu_args=(-n --stdin -c)
    source_expr='$in | into binary'
  fi

  local csv_flags=' --separator $env.__J2C_SEP'
  ((${#o_noheader})) && csv_flags+=' --noheaders'

  # `from json --objects` hands a line it cannot read on as a plain string rather
  # than failing, and the type error `to csv` then raises names neither the line
  # nor the problem. Say which line instead.
  local -a script=(
    "let rows = (${source_expr} | decode utf-8 | from json --objects | collect)"
    'let bad = ($rows | enumerate | where {|r| not (($r.item | describe) | str starts-with "record")})'
    'if not ($bad | is-empty) {'
    '  let n = (($bad | first | get index) + 1)'
    '  error make --unspanned { msg: $"line ($n) is not a JSON object -- expected one object per line" }'
    '}'
  )
  # No records means no columns to name, so nothing at all is the honest answer -
  # `to csv` would otherwise emit a lone `""` for an empty table.
  if [[ -n $cols ]]; then
    script+=(
      'let want = ($env.__J2C_COLS | split row ",")'
      'if not ($rows | is-empty) {'
      '  let missing = ($want | where {|c| $c not-in ($rows | columns)})'
      '  if not ($missing | is-empty) {'
      '    let names = ($missing | str join ", ")'
      '    let have = ($rows | columns | str join ", ")'
      '    error make --unspanned { msg: $"no such column: ($names) -- record has: ($have)" }'
      '  }'
      '}'
      "let out = (if (\$rows | is-empty) { '' } else { \$rows | select ...\$want | to csv${csv_flags} })"
    )
  else
    script+=("let out = (if (\$rows | is-empty) { '' } else { \$rows | to csv${csv_flags} })")
  fi

  if [[ -n ${o_bom[*]} ]]; then
    script+=('0x[EF BB BF] ++ ($out | encode utf-8) | save --raw --force /dev/stdout')
  elif [[ $enc == utf-8 ]]; then
    # `to csv` already ends in a newline; print must not add a second one.
    script+=('print --no-newline $out')
  else
    script+=('$out | encode $env.__J2C_ENC | save --raw --force /dev/stdout')
  fi

  __J2C_FILE=$file __J2C_COLS=$cols __J2C_ENC=$enc __J2C_SEP=$sep \
    nu "${nu_args[@]}" "${(F)script}"
}

function jsonl2yml() {
  if [ "$" -gt 0 ]; then
    cat -- "$@" | nu -n --stdin -c 'from json --objects | to yaml'
  elif [ -t 0 ]; then
    printf 'usage: jsonl2yml [file...]   # or pipe JSONL on stdin\n' >&2
    return 2
  else
    nu -n --stdin -c 'from json --objects | to yaml'
  fi
}

function export_secret {
  _check_gum_cmd || return 1

  local var_name="$1"
  local secret=""

  [[ -n "$var_name" ]] || {
    print -u2 'usage: export_secret <VAR_NAME>'
    return 2
  }

  # gum input --password does the masking, the prompt and the terminal-state
  # restore that the hand-rolled `read -rs` had to arrange between two manual
  # writes to stderr - including on interrupt, where the old version could
  # leave echo disabled.
  secret=$(gum input --password --header="Enter ${var_name}") || return 1

  [[ -n "$secret" ]] || {
    print -u2 'Aborted: empty value.'
    return 1
  }

  printf -v "${var_name}" '%s' "${secret}"
  export "${var_name}"

  print -u2 "Exported: ${var_name}=***"
}
