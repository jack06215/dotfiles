#!/usr/bin/env zsh
# vim: filetype=zsh

# rgi <file...> [language] [mode]
# modes: fuzzy | literal | regex
function rgsearch() {
  local mode="fuzzy"
  local lang="auto"

  local -a files=()
  local -a bat_lang_opt
  local preview_cmd reload_cmd

  # -----------------------------
  # Parse arguments
  # -----------------------------
  for arg in "$@"; do
    case "$arg" in
      fuzzy|literal|regex)
        mode="$arg"
        ;;
      xml|json|yaml|yml|toml|bash|csv)
        lang="$arg"
        ;;
      *)
        files+=("$arg")
        ;;
    esac
  done

  (( ${#files[@]} > 0 )) || {
    echo "Usage: rgi <file...> [language] [mode]" >&2
    return 1
  }

  for f in "${files[@]}"; do
    [[ -f "$f" ]] || {
      echo "File not found: $f" >&2
      return 1
    }
  done

  # -----------------------------
  # Auto-detect language
  # -----------------------------
  if [[ "$lang" == "auto" ]]; then
    case "${files[1]}" in
      *.xml)  lang=xml ;;
      *.json) lang=json ;;
      *.yml|*.yaml) lang=yaml ;;
      *.toml) lang=toml ;;
      *.sh)   lang=bash ;;
      *.csv)  lang=csv ;;
    esac
  fi

  [[ -n "$lang" && "$lang" != "auto" ]] && bat_lang_opt=(--language "$lang")

  # -----------------------------
  # Preview command
  # Fields: {1}=file {2}=line {3}=column {4}=text
  # -----------------------------
  preview_cmd="sh -c '
    file=\"\$1\"
    line=\"\$2\"

    if [ -n \"\$line\" ] && printf \"%s\" \"\$line\" | grep -Eq \"^[0-9]+$\"; then
      bat --style=numbers --color=always --paging=never --wrap=character ${bat_lang_opt[@]} \
          --highlight-line \"\$line\" \"\$file\"
    else
      bat --style=numbers --color=always --paging=never --wrap=character ${bat_lang_opt[@]} \
          \"\$file\"
    fi
  ' sh {1} {2}"

  # -----------------------------
  # Build rg reload command
  # Always output: file:line:column:text
  # -----------------------------
  local files_joined
  files_joined=$(printf '%q ' "${files[@]}")

  case "$mode" in
    fuzzy)
      reload_cmd="sh -c '
        q=\"\$1\"
        if [ -z \"\$q\" ]; then
          rg --with-filename --line-number --column . $files_joined
        else
          pat=\$(printf \"%s\" \"\$q\" | sed \"s/[[:space:]]\\\\+/.*/g\")
          rg --with-filename --line-number --column -i -- \"\$pat\" $files_joined
        fi
      ' sh {q}"
      ;;
    literal)
      reload_cmd="sh -c '
        q=\"\$1\"
        if [ -z \"\$q\" ]; then
          rg --with-filename --line-number --column . $files_joined
        else
          rg --with-filename --line-number --column -i -F -- \"\$q\" $files_joined
        fi
      ' sh {q}"
      ;;
    regex)
      reload_cmd="sh -c '
        q=\"\$1\"
        if [ -z \"\$q\" ]; then
          rg --with-filename --line-number --column . $files_joined
        else
          rg --with-filename --line-number --column -i -- \"\$q\" $files_joined
        fi
      ' sh {q}"
      ;;
    *)
      echo "Unknown mode: $mode (use fuzzy|literal|regex)" >&2
      return 1
      ;;
  esac

  # -----------------------------
  # Run fzf
  # -----------------------------
  local out query selected
  out=$(
    printf '' |
      fzf --phony --disabled \
          --print-query \
          --delimiter : --nth 4.. \
          --preview-window=wrap \
          --preview "$preview_cmd" \
          --bind "start:reload:$reload_cmd" \
          --bind "change:reload:$reload_cmd"
  ) || return

  query="${out%%$'\n'*}"
  selected="${out#*$'\n'}"

  # -----------------------------
  # Parse rg output
  # file:line:column:text
  # -----------------------------
  local file line col rest text
  file="${selected%%:*}"
  rest="${selected#*:}"
  line="${rest%%:*}"
  rest="${rest#*:}"
  col="${rest%%:*}"
  text="$(
    print -r -- "${rest#*:}" |
      sed 's/^[[:space:]]\+//; s/[[:space:]]\+$//'
  )"

  # -----------------------------
  # Emit structured JSON
  # -----------------------------
  jq -n \
    --arg file "$file" \
    --arg line "$line" \
    --arg col "$col" \
    --arg text "$text" \
    --arg search "$query" \
    --arg mode "$mode" \
    --arg lang "$lang" \
    '
    {
      file: $file,
      line: ($line | tonumber? // null),
      column: ($col | tonumber? // null),
      text: $text,
      search: $search,
      mode: $mode,
      lang: $lang
    }
    '
}

function vimfind() {
    if [ -z "$1" ]; then
        # use fd with fzf to select & open a file when no arg are provided
        file="$(fd --type f -I -H -E .git -E .git-crypt -E .cache -E .backup | fzf --height=70% --preview='bat -n --color=always --line-range :500 {}')"
        if [ -n "$file" ]; then
            nvim "$file"
        fi
    else
        # Handle when an arg is provided
        lines=$(zoxide query -l | xargs -I {} fd --type f -I -H -E .git -E .git-crypt -E .cache -E .backup -E .vscode "$1" {} | fzf --no-sort) # Initial filter attempt with fzf
        line_count="$(echo "$lines" | wc -l | xargs)" # Trim any leading spaces

        if [ -n "$lines" ] && [ "$line_count" -eq 1 ]; then
            # looks for the exact ones and opens it
            file="$lines"
            nvim "$file"
        elif [ -n "$lines" ]; then
            # If multiple files are found, allow further selection using fzf and bat for preview
            file=$(echo "$lines" | fzf --query="$1" --height=70% --preview='bat -n --color=always --line-range :500 {}')
            if [ -n "$file" ]; then
                nvim "$file"
            fi
        else
            echo "No matches found." >&2
        fi
    fi
}

function vimrecent() {
    # Get the oldfiles list from Neovim
    oldfiles=($(nvim -u NONE --headless +'lua io.write(table.concat(vim.v.oldfiles, "\n") .. "\n")' +qa))

    # Filter invalid paths or files not found
    valid_files=()
    for file in "${oldfiles[@]}"; do
        if [[ -f "$file" ]]; then
            valid_files+=("$file")
        fi
    done

    # Use fzf to select from valid files
    files=($(printf "%s\n" "${valid_files[@]}" | \
        grep -v '\[.*' | \
        fzf --multi \
        --preview 'bat -n --color=always --line-range=:500 {} 2>/dev/null || echo "Error previewing file"' \
        --height=70% \
        --layout=default))

    # Open selected files in Neovim
    [[ ${#files[@]} -gt 0 ]] && nvim "${files[@]}"
}

function es_find_by_index_prefix() {
  local prefix="${1:?index prefix required}"

  jq -r '
    to_entries
    | map(select(.key | startswith("'"$prefix"'")))
    | from_entries
  '
}

function es_find_by_filter() {
  local filter_name="${1:?filter name required}"
  jq -r --arg f "$filter_name" '
    to_entries[] 
    | select(.value.settings.index.analysis.analyzer[].filter // [] | contains([$f])) 
    | .key'
}

function es_list_all_analyzers() {
  jq -r '[.[] | .settings.index.analysis.analyzer | keys[]] | unique[]'
}

# Assuming naming convention is name-YYYYMMDDHHMMSS
function es_list_dates() {
  jq -r 'keys[] | . as $id | capture("(?<name>.*)-(?<date>[0-9]{14})") // {name: $id, date: "N/A"} | "\(.date) \(.name)"' | sort
}

function es_find_after_date() {
  local date_limit="${1:?date YYYYMMDD required}"
  jq --arg d "$date_limit" '
    to_entries 
    | map(select(.key | capture("(?<ts>[0-9]{8})") | .ts >= $d)) 
    | from_entries'
}

function es_summarize_by_project() {
  jq -r 'keys[] | split("-")[0]' | sort | uniq -c
}

function es_summarize_by_name() {
  jq -r 'keys[] | sub("-[0-9]{14}$"; "")' | sort | uniq -c
}

function es_find_all_dates_by_name() {
  local base_name="${1:?base name required (e.g. cda-kddi-slp-kp)}"

  # We use a regex capture to ensure the match is exact for the name part
  # and only pulls indices that follow the -YYYYMMDDHHMMSS format.
  jq -r --arg name "$base_name" '
    keys[] 
    | capture("^(?<name>.*)-(?<date>[0-9]{14})$") 
    | select(.name == $name) 
    | .date
  ' | sort -r
}
