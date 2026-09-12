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
    nu_args=(-n --stdin -c)
    source_expr='$in'
  fi

  local flags=''
  ((${#o_noheader})) && flags+=' --noheaders'
  ((${#o_infer})) && flags+=' --infer'
  ((${#o_flexible})) && flags+=' --flexible'

  local -a script=(
    'source ($nu.default-config-dir | path join csv2.nu)'
    "${source_expr} | csv2 ${format} --columns \$env.__CSV2_COLS --encoding \$env.__CSV2_ENC --separator \$env.__CSV2_SEP${flags}"
  )

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
    source_expr='$in'
  fi

  local flags=''
  ((${#o_noheader})) && flags+=' --noheaders'
  ((${#o_bom})) && flags+=' --bom'

  # Binary (--bom, or any encoding but utf-8) leaves through `save`, per the
  # note above. `to csv` already ends in a newline; print must not add another.
  local -a script=(
    'source ($nu.default-config-dir | path join jsonl2csv.nu)'
    "let out = (${source_expr} | jsonl2csv --columns \$env.__J2C_COLS --encoding \$env.__J2C_ENC --separator \$env.__J2C_SEP${flags})"
    'if ($out | describe) == "binary" { $out | save --raw --force /dev/stdout } else { print --no-newline $out }'
  )

  __J2C_FILE=$file __J2C_COLS=$cols __J2C_ENC=$enc __J2C_SEP=$sep \
    nu "${nu_args[@]}" "${(F)script}"
}

function jsonl2yml() {
  local -a script=(
    'source ($nu.default-config-dir | path join jsonl2yml.nu)'
    '$in | jsonl2yml'
  )

  # An arithmetic test, not `[ "$#" -gt 0 ]`: shfmt's zsh mode rewrites that
  # "$#" to "$", which silently turns every file argument into a usage error.
  if (($# > 0)); then
    cat -- "$@" | nu -n --stdin -c "${(F)script}"
  elif [ -t 0 ]; then
    printf 'usage: jsonl2yml [file...]   # or pipe JSONL on stdin\n' >&2
    return 2
  else
    nu -n --stdin -c "${(F)script}"
  fi
}

function _yml2jsonl_usage() {
  print -u2 -- "usage: yml2jsonl [options] [file|-] [path.to.list]

Reads stdin when no file (or '-') is given. A YAML sequence, or a file of several
'---' separated documents, becomes one JSON object per line; a lone mapping
becomes a single line. The trailing path descends through mapping keys first,
for the common case of the sequence being nested under one.

  -p, --path PATH      the dotted path, for when there is no file argument
  -e, --encoding ENC   decode input as ENC (default: utf-8). cp932, shift-jis
                       and eucjp are also accepted
  -h, --help           this message"
}

# The reverse of jsonl2yml. `from yaml` already folds a multi-document file into
# a list, so '---' separators and a plain YAML sequence arrive as the same thing
# and each become one line - which is the whole point of the format.
#
# The file path and the dotted path travel in the environment rather than being
# spliced into the nu source, for the reason _csv2 does the same: both can hold
# quotes, and nu's single-quoted strings have no escape syntax to defend against
# that.
function yml2jsonl() {
  local caller=${funcstack[1]:-yml2jsonl}
  _check_nu_cmd "$caller" || return 1

  local -a o_help o_path o_enc
  zparseopts -D -E -F -- \
    h=o_help -help=o_help \
    p:=o_path -path:=o_path \
    e:=o_enc -encoding:=o_enc 2> /dev/null || {
    print -u2 "$caller: unknown option; try '$caller --help'"
    return 2
  }

  ((${#o_help})) && {
    _yml2jsonl_usage
    return 0
  }

  (($# > 2)) && {
    print -u2 "$caller: unexpected argument '$3'"
    return 2
  }

  # Not `path`: that name is tied to $PATH in zsh, and a local one blanks the
  # command search path for the rest of the function.
  local file=${1:-} keypath=${2:-}
  if ((${#o_path})); then
    [[ -z $keypath ]] || {
      print -u2 "$caller: give the path once, as --path or as the trailing argument"
      return 2
    }
    keypath=${o_path[-1]}
  fi
  [[ $file == - ]] && file=''

  if [[ -n $file ]]; then
    [[ -r $file ]] || {
      print -u2 "$caller: cannot read '$file'"
      return 1
    }
  elif [[ -t 0 ]]; then
    _yml2jsonl_usage
    return 2
  fi

  local enc
  enc=$(_nu_encoding_label "${o_enc[-1]:-utf-8}")

  local source_expr
  local -a nu_args=(-n -c)
  if [[ -n $file ]]; then
    source_expr='open --raw $env.__Y2J_FILE'
  else
    nu_args=(-n --stdin -c)
    source_expr='$in'
  fi

  local -a script=(
    'source ($nu.default-config-dir | path join yml2jsonl.nu)'
    "${source_expr} | yml2jsonl --path \$env.__Y2J_PATH --encoding \$env.__Y2J_ENC"
  )

  __Y2J_FILE=$file __Y2J_PATH=$keypath __Y2J_ENC=$enc \
    nu "${nu_args[@]}" "${(F)script}"
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

# nushell's `lsz` (directories sized by everything under them, largest first),
# drawn by gum. The listing and the CSV both come from the same .nu files
# config.nu sources, so the two shells cannot drift apart.
function lsz {
  _check_nu_cmd || return 1
  _check_gum_cmd || return 1

  (($# > 1)) && {
    print -u2 'usage: lsz [dir]'
    return 2
  }

  local -a script=(
    'source ($nu.default-config-dir | path join lsz.nu)'
    'source ($nu.default-config-dir | path join tocsv.nu)'
    'lsz $env.__LSZ_DIR | tocsv'
  )

  local csv
  csv=$(__LSZ_DIR=${1:-.} nu -n -c "${(F)script}") || return
  [[ -n $csv ]] || return 0

  gum table --print <<< "$csv"
}
