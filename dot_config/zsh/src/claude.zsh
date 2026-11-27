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

# Export the Bash commands that one Claude Code session ran, as a JSON array
# of {timestamp, session_id, command} in time order.
#
#   claude_cmds                                  # pick the session in fzf
#   claude_cmds 6dce8017                         # a unique id prefix is enough
#   claude_cmds latest                           # the most recently active one
#   claude_cmds 6dce8017 | jq -r '.[].command'
#
# The commands come from atuin's thread capture, not from its shell history.
# `atuin hook claude-code` gives each history row it writes a new atuin
# session id, so history.db has no column that links a command to the Claude
# Code session that ran it. A thread is stored under Claude Code's own
# session id.
#
# Each subagent has its own thread with an `agent-...` id. The export includes
# the commands of every subagent that the session started, with the
# subagent's id in session_id. A timestamp is the time at which the tool call
# went into the transcript, in UTC. That is before the command ran, and before
# any permission prompt for it.
function claude_cmds() {
  emulate -L zsh
  setopt pipefail

  if (($# == 0)); then
    local picked
    picked=$(_claude_cmds_pick) || return
    set -- "$picked"
  fi

  if (($# != 1)); then
    print -ru2 -- 'usage: claude_cmds [session-id | unique prefix | latest]'
    return 64
  fi

  # atuin prints a tool call's input as a JSON-encoded string, not an object.
  local extract='select(.kind == "message") | .timestamp as $ts | .content[]?
    | select(.type == "tool_call" and .name == "Bash")
    | {timestamp: $ts, session_id: $sid,
       command: (.input | if type == "string" then fromjson else . end).command}'

  local thread sid
  thread=$(atuin threads show --style ndjson "$1") || return
  sid=$(jq -r 'select(.kind == "session") | .session_id' <<<"$thread") || return

  local -a subagents
  subagents=(${(f)"$(atuin threads list --style ndjson | jq -r --arg sid "$sid" \
    'select(.parent_kind == "subagent" and .parent.session_id == $sid) | .session_id')"})

  # sort_by compares the timestamps as strings. That gives time order only
  # because atuin prints every timestamp with the same +00:00 offset.
  {
    jq -c --arg sid "$sid" "$extract" <<<"$thread"
    local id
    for id in $subagents; do
      atuin threads show --style ndjson "$id" | jq -c --arg sid "$id" "$extract"
    done
  } | jq -s 'sort_by(.timestamp)'
}

# The fzf picker for a bare `claude_cmds`. It prints the session id of the
# pick. A row shows when the session was last active, its directory, its title
# and its first prompt. Subagents get no row, because claude_cmds exports their
# commands with the parent session. The preview shows the commands that
# claude_cmds exports for the session under the cursor.
#
# fzf matches the query against the rows. ctrl-r switches to atuin's full-text
# search, which also looks at every message and tool call, so a word from a
# command finds the session that ran it. That search matches whole words only,
# so a word finds nothing until it is complete. In full-text mode fzf does not
# match (disable-search), and each change to the query reloads the rows from
# _claude_cmds_search. The ctrl-r transform reads the mode from the prompt, the
# same way as the picker in atuin.zsh.
#
# fzf runs reload, transform and preview commands in a new shell, which does
# not have these functions. $run starts zsh, sources this file again (it only
# defines functions) and calls a function by name.
function _claude_cmds_pick() {
  emulate -L zsh
  setopt pipefail

  local -x _CLAUDE_CMDS_LIB=${functions_source[_claude_cmds_pick]}
  local run='zsh -fc '\''source -- "$_CLAUDE_CMDS_LIB" && "$@"'\'' zsh'

  # A file, not a variable, because _claude_cmds_search runs in another
  # process and reads the rows to turn search hits back into rows.
  local -x _CLAUDE_CMDS_ROWS
  _CLAUDE_CMDS_ROWS=$(mktemp "${TMPDIR:-/tmp}/claude_cmds.XXXXXX") || return
  {
    # fromdateiso8601 rejects fractional seconds and "+00:00". atuin prints
    # every time in UTC, so the first 19 characters plus "Z" are the same time.
    atuin threads list --style ndjson | jq -nr --arg home "$HOME" '
      [inputs
        | select(.harness == "claude-code" and .parent_kind != "subagent")
        | {id: .session_id,
           when: (.updated_at[0:19] + "Z" | fromdateiso8601
                  | strflocaltime("%m-%d %H:%M")),
           dir: (.cwd // ""
                 | if startswith($home) then "~" + ltrimstr($home) else . end
                 | if length > 32 then ".." + .[-30:] else . end),
           text: ([.title, .preview] | map(select(. != null and . != ""))
                  | join(" · ") | gsub("\\s+"; " ") | .[0:300])}]
      | (map(.dir | length) | max // 0) as $w
      | .[] | [.id, .when, .dir + " " * ($w - (.dir | length) + 1), .text]
      | join("\t")' >|"$_CLAUDE_CMDS_ROWS" || return

    local -x _CLAUDE_CMDS_TO_TEXT="change-prompt(text> )+disable-search+rebind(change)+reload($run _claude_cmds_search)"
    local -x _CLAUDE_CMDS_TO_TITLE='change-prompt(title> )+enable-search+unbind(change)+reload(cat -- "$_CLAUDE_CMDS_ROWS")'

    fzf --delimiter='\t' --with-nth=2.. --accept-nth=1 --tabstop=1 \
      --scheme=history --height=80% --prompt='title> ' \
      --header='ctrl-r: match titles / search the full text' \
      --preview="$run _claude_cmds_preview {1}" \
      --preview-window='right,60%,wrap,<120(down,60%,wrap)' \
      --bind='start:unbind(change)' \
      --bind="change:reload($run _claude_cmds_search)" \
      --bind='ctrl-r:transform:case $FZF_PROMPT in
          title*) printf %s "$_CLAUDE_CMDS_TO_TEXT" ;;
          *) printf %s "$_CLAUDE_CMDS_TO_TITLE" ;;
        esac' <"$_CLAUDE_CMDS_ROWS"
  } always {
    rm -f -- "$_CLAUDE_CMDS_ROWS"
  }
}

# The rows of the sessions that atuin's full-text search finds for the fzf
# query, most relevant first. A hit in a subagent's thread stands for its
# parent session, which has the row. A query that atuin rejects gives no rows.
function _claude_cmds_search() {
  emulate -L zsh
  setopt pipefail

  local -a words=(${=FZF_QUERY})
  if ((!${#words})); then
    cat -- "$_CLAUDE_CMDS_ROWS"
    return
  fi

  atuin threads search --harness claude-code --limit 0 --style ndjson \
    -- "${words[@]}" 2>/dev/null |
    jq -nr --rawfile rows "$_CLAUDE_CMDS_ROWS" '
      ($rows | split("\n") | map(select(. != "") | {key: split("\t")[0], value: .})
       | from_entries) as $row
      | reduce (inputs | .session.parent.session_id // .session.session_id) as $id
          ([]; if any(.[]; . == $id) then . else . + [$id] end)
      | .[] | $row[.] // empty'
}

function _claude_cmds_preview() {
  claude_cmds "$1" | jq -r '
    if length == 0 then "No Bash commands." else
      .[] | (.timestamp[0:19] + "Z" | fromdateiso8601
             | strflocaltime("%m-%d %H:%M:%S")) as $t
      | "\u001b[90m\($t)\u001b[0m  \(.command)"
    end'
}
