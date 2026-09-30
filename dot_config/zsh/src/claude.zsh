# shellcheck shell=bash
# filetype=sh

# Agent teams are experimental and off by default. Turning them on in
# settings.json would be the obvious move, but it has a side effect worth
# avoiding: while teams are enabled, *any* subagent Claude names launches as a
# full teammate - a separate Claude instance inheriting this config's Opus and
# xhigh effort - so a team can form during ordinary delegation you never framed
# as team work. Opt in per session instead, and leave the global default alone.
#
# teammateMode is already "auto" in settings.json, so a team started this way
# lands in tmux split panes when you are inside tmux, and falls back to the
# in-process agent panel when you are not. Nothing else to pass.
#
#   claude_team                    # one session with teams enabled
#   claude_team --resume           # any claude flag passes straight through
#
# `command` rather than a bare call so this keeps working if claude ever picks
# up an alias elsewhere in the config.
function claude_team() {
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 command claude "$@"
}

# Browse Claude Code's auto-memory across every project: pick with fzf, read in
# the preview, open the picks in $EDITOR.
#
#   claude_memory                 # every memory, newest first
#   claude_memory dotfiles        # start with the query "dotfiles"
#   claude_memory | xargs rm      # stdout not a tty: print paths instead
function claude_memory() {
  emulate -L zsh
  zmodload -F zsh/stat b:zstat

  local root="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"

  # `om` sorts the whole expansion by mtime, so the newest memory comes first
  # whichever project it lives in. MEMORY.md is only the index of the others.
  local -a files
  files=("$root"/*/memory/**/*.md(N.om))
  files=(${files:#*/MEMORY.md})

  (( $#files )) || { print -r -- "No Claude memories under $root"; return 0; }

  # One awk over every file, reading only the frontmatter. `type` may sit at
  # the top level or indented under `metadata:`, depending on which version of
  # Claude Code wrote the file. Empty fields become "-": read collapses runs of
  # tabs, so an empty column would shift every column after it.
  local fields
  fields=$(awk -v sq="'" '
    function value(s) {
      sub(/^[^:]*:[[:space:]]*/, "", s)
      sub(/[[:space:]]+$/, "", s)
      if (s ~ /^".*"$/) { s = substr(s, 2, length(s) - 2); gsub(/\\"/, "\"", s) }
      else if (s ~ "^" sq ".*" sq "$") { s = substr(s, 2, length(s) - 2); gsub(sq sq, sq, s) }
      gsub(/\t/, " ", s)
      return s
    }
    function flush() {
      if (file == "") return
      if (name == "") { name = file; sub(/.*\//, "", name); sub(/\.md$/, "", name) }
      print file "\t" name "\t" (type == "" ? "-" : type) "\t" desc
      file = ""
    }
    FNR == 1 {
      flush()
      file = FILENAME; name = type = desc = ""
      in_fm = ($0 ~ /^---[[:space:]]*$/)
      next
    }
    !in_fm { next }
    /^---[[:space:]]*$/ { in_fm = 0; next }
    /^name:/ { name = value($0); next }
    /^description:/ { desc = value($0); next }
    /^[[:space:]]*type:/ { type = value($0); next }
    END { flush() }
  ' "${files[@]}") || return 1

  # Project dirs are the cwd with every non-alphanumeric turned into "-", so
  # the home prefix is recognisable but the rest can't be turned back into a
  # path.
  local home_key=${HOME//[^A-Za-z0-9]/-}

  local -a f_file f_date f_proj f_type f_name f_desc mtime
  local file name type desc proj
  integer proj_w=0
  while IFS=$'\t' read -r file name type desc; do
    [[ -n $file ]] || continue
    proj=${${file#$root/}%%/*}
    proj=${${proj#$home_key}#-}
    proj=${proj:-'~'}
    zstat -F '%Y-%m-%d' -A mtime +mtime -- "$file"
    f_file+=("$file")
    f_date+=("${mtime[1]}")
    f_proj+=("$proj")
    f_type+=("$type")
    f_name+=("$name")
    f_desc+=("$desc")
    (( $#proj > proj_w )) && proj_w=$#proj
  done <<< "$fields"

  local -A type_color=(user 34 feedback 33 project 32 reference 35)

  local -a rows
  local i t
  for i in {1..$#f_file}; do
    t=${f_type[$i]}
    rows+=("${f_file[$i]}"$'\t'"$(printf '\e[90m%s\e[0m  \e[36m%s\e[0m  \e[%sm%-9s\e[0m  \e[1m%s\e[0m  \e[90m%s\e[0m' \
      "${f_date[$i]}" "${(r:$proj_w:)f_proj[$i]}" "${type_color[$t]:-0}" "$t" "${f_name[$i]}" "${f_desc[$i]}")")
  done

  # {1} is the path, hidden from the list by --with-nth, so typing only matches
  # the date, project, type, name and description.
  local preview='cat -- {1}'
  (( $+commands[bat] )) && preview='bat --color=always --style=numbers --language=markdown -- {1}'

  local -a selection
  selection=("${(@f)$(print -rl -- "${rows[@]}" \
    | fzf --ansi \
      --multi \
      --height=80% \
      --delimiter='\t' \
      --with-nth=2.. \
      --accept-nth=1 \
      --prompt='Memory> ' \
      --query="$*" \
      --header='enter: open in editor · tab: multi-select · ctrl-/: toggle preview' \
      --preview="$preview" \
      --preview-window='right,60%,wrap,<120(down,60%,wrap)')}") || return 0
  [[ -n ${selection[1]} ]] || return 0

  [[ -t 1 ]] || { print -rl -- "${selection[@]}"; return 0; }

  ${=VISUAL:-${EDITOR:-nvim}} -- "${selection[@]}"
}
