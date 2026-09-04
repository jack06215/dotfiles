# shellcheck shell=bash

# Shared flags for all bazel query invocations.
# Centralised here so changes apply everywhere. The output format is
# deliberately left to the caller: label-based helpers want --output=label,
# the definition lookup wants --output=location.
_BAZEL_QUERY_FLAGS=(
  --noshow_progress
  --keep_going # continue past errors in broken targets
  --color=yes
)

# _bazel_spin_while <pid> <text>
#
# Animate a progress spinner on stderr until <pid> exits, then wait on it.
# The loading phase of a query on a large repo runs long enough to be
# indistinguishable from a hang, so it needs to show something.
#
# Deliberately NOT `gum spin`. gum drives a full TUI, and on startup it probes
# the terminal - DECRQM \e[?2026$p for synchronised output, \e[?u and
# \e[=1;1u for the Kitty keyboard protocol - then reads the replies off stdin.
# Those are questions the terminal answers. Handing the terminal straight from
# gum to fzf inside one command leaves any reply gum did not consume sitting
# in the input buffer, where fzf reads it as phantom keystrokes or ZLE types
# it into the command line the caller is about to queue with `print -z`.
#
# Everything written here is a one-way command the terminal never answers: a
# carriage return, \e[2K to erase the line, and \e[?25l / \e[?25h to hide and
# show the cursor. Same animation, no reply to leak.
#
# Writes to stderr rather than /dev/tty: inside a caller's command
# substitution only stdout is captured, so stderr is already the terminal -
# and opening /dev/tty *fails* when there is no controlling terminal (a
# script, a hook, a CI shell), which would take the whole query down with it
# rather than merely losing the animation.
function _bazel_spin_while() {
  local pid="$1" text="$2"

  # local_traps scopes the TRAPINT below to this function, so Ctrl-C
  # everywhere else keeps its usual behaviour.
  setopt localoptions local_traps

  # Ctrl-C would otherwise leave the cursor hidden for the rest of the
  # session, so it is trapped: restore the cursor, stop the query, then
  # re-raise. `return 128+SIGINT` is what propagates the abort; returning 0
  # from a trap swallows it, which would let the caller fall through to fzf
  # with a half-written buffer.
  #
  # Installed whether or not we are on a terminal: the cursor only needs
  # restoring if we hid it, but an abandoned query has to be stopped either
  # way - it holds the bazel lock, and the next bazel command would block on
  # it. Only the drawing below is conditional.
  TRAPINT() {
    [[ -t 2 ]] && print -n -u2 -- $'\r\e[2K\e[?25h'
    kill "${pid}" 2> /dev/null
    return $(( 128 + 2 ))
  }

  # Nothing to animate on, so don't write control sequences into a log - but
  # still wait, or the caller reads a half-written buffer.
  if [[ ! -t 2 ]]; then
    wait "${pid}" 2> /dev/null
    return 0
  fi

  # gum's "minidot" frames.
  local -a frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  local i=1

  print -n -u2 -- $'\e[?25l'
  while kill -0 "${pid}" 2> /dev/null; do
    print -n -u2 -- $'\r'"${frames[i]} ${text}"
    i=$(( i % ${#frames} + 1 ))
    sleep 0.08
  done
  print -n -u2 -- $'\r\e[2K\e[?25h'

  wait "${pid}" 2> /dev/null
  return 0
}

# _bazel_fzf_pick <prompt> [multi]
#
# Wrap fzf with a consistent preview and layout.
# Pass "multi" as the second argument to enable multi-select (returns
# newline-separated targets).
function _bazel_fzf_pick() {
  local prompt="$1"
  local multi="${2:-}"

  local -a fzf_args=(
    --prompt="${prompt}"
    --height=40%
    --layout=reverse
    --preview='bazel query "kind(.*, {})" --output=build 2>/dev/null \
               | { command -v bat &>/dev/null \
                   && bat --language=python --color=always --style=plain \
                   || cat; }'
    --preview-window=right:60%:wrap
  )

  [[ "${multi}" == "multi" ]] && fzf_args+=(--multi --bind='ctrl-a:select-all')

  fzf "${fzf_args[@]}"
}

# _bazel_buffer_and_pick <prompt> <bazel-query-expr> [multi]
#
# Runs `bazel query <expr>`, buffers the output in a temp file (so that
# progress/warning messages printed to stderr don't corrupt the fzf layout),
# then hands the buffer to fzf for interactive selection.
#
# Returns the selected target(s) on stdout, one per line.
# Returns 1 if the user cancels or no target is matched.
function _bazel_buffer_and_pick() {
  local prompt="$1"
  local query="$2"
  local multi="${3:-}"

  local tmp
  tmp="$(mktemp)" || return 1
  # Use a subshell so the EXIT trap is scoped to this function's lifetime only.
  (
    trap 'rm -f "${tmp}"' EXIT

    # stdout (labels) → buffer for fzf, so progress and warnings cannot
    # pollute the selection list. stderr is left inherited: it is already the
    # terminal, which keeps server startup and warnings visible above the fzf
    # prompt.
    #
    # The query runs in the background so the spinner can animate in the
    # foreground; _bazel_spin_while waits on it, so the buffer is complete
    # before fzf reads it. See _bazel_spin_while for why this is hand-rolled
    # and not `gum spin`.
    bazel query \
      "${query}" \
      --output=label \
      "${_BAZEL_QUERY_FLAGS[@]}" \
      > "${tmp}" &
    _bazel_spin_while $! "Querying targets..."

    local selection
    selection="$(_bazel_fzf_pick "${prompt}" "${multi}" < "${tmp}")"

    [[ -n "${selection}" ]] || exit 1
    printf '%s\n' "${selection}"
  )
}

# ---------------------------------------------------------------------------
# Target definition lookup
#
# The index format shared by the two producers below is one target per line,
# tab separated:
#
#   <name> \t <kind> \t <label> \t <absolute file> \t <line>
#
# The first three columns are what fzf displays; the last two are what the
# accept action needs. Name and kind are space-padded to fixed widths inside
# their own field, so the tab delimiter stays intact for --nth/--with-nth
# while --tabstop=1 renders each tab as a single column - the padding is what
# you actually see, giving aligned columns without a second pass.
# ---------------------------------------------------------------------------

# _bazel_workspace_root
#
# Walk up from $PWD looking for a workspace marker. Deliberately avoids
# `bazel info workspace`, which would boot the server just to answer a
# question the filesystem already knows - and which would defeat the point of
# the --grep path.
function _bazel_workspace_root() {
  local dir="${PWD}" marker
  while [[ -n "${dir}" && "${dir}" != "/" ]]; do
    for marker in MODULE.bazel WORKSPACE.bazel WORKSPACE; do
      if [[ -f "${dir}/${marker}" ]]; then
        printf '%s\n' "${dir}"
        return 0
      fi
    done
    dir="${dir:h}"
  done
  return 1
}

# _bazel_location_to_index
#
# Turn `bazel query --output=location` lines on stdin, which look like
#
#   /abs/pkg/BUILD.bazel:12:1: go_library rule //pkg:my_target
#
# into index lines. This is the authoritative producer - it sees targets that
# only exist after macro expansion, which no amount of grepping over BUILD
# files can find. For a macro-generated target bazel reports the macro's call
# site in the BUILD file (verified against bazel 9.2), which is the place you
# actually want to edit rather than the .bzl internals.
function _bazel_location_to_index() {
  awk '
    {
      gsub(/\033\[[0-9;]*m/, "")            # bazel may colour its output
      if (NF < 4 || $(NF - 1) != "rule") next

      loc = $1                              # /abs/pkg/BUILD.bazel:12:1:
      kind = $2
      label = $NF
      sub(/:$/, "", loc)

      rest = loc; sub(/:[^:]*$/, "", rest)  # drop the column
      line = rest; sub(/.*:/, "", line)
      file = rest; sub(/:[^:]*$/, "", file)
      if (line !~ /^[0-9]+$/) next

      name = label
      if (index(name, ":") > 0) sub(/.*:/, "", name); else sub(/.*\//, "", name)

      printf "%-30s\t%-14s\t%s\t%s\t%s\n", name, kind, label, file, line
    }
  '
}

# _bazel_target_index_grep <workspace-root>
#
# Same index shape, built by reading BUILD/*.bzl files directly. Instant, and
# works on a tree that will not load, but it only sees literal
# `name = "..."` attributes: computed and macro-generated target names are
# invisible to it. Rule kind comes from the nearest preceding call that opens
# its own line, so `native.filegroup(` inside a .bzl macro resolves too.
function _bazel_target_index_grep() {
  local root="$1"

  rg --files --null \
    --glob 'BUILD' --glob 'BUILD.bazel' --glob '*.bzl' \
    -- "${root}" 2> /dev/null \
    | xargs -0 awk -v root="${root}" '
      FNR == 1 {
        kind = ""

        dir = FILENAME; sub(/\/[^\/]*$/, "", dir)
        pkg = (index(dir, root) == 1) ? substr(dir, length(root) + 2) : dir

        base = FILENAME; sub(/.*\//, "", base)
        is_build = (base == "BUILD" || base == "BUILD.bazel")

        rel = (index(FILENAME, root "/") == 1) \
          ? substr(FILENAME, length(root) + 2) : FILENAME
      }

      # A call that opens the line is a rule instantiation; an attribute is
      # always `key = ...`, so this cannot be confused with glob()/select().
      /^[ \t]*[A-Za-z_][A-Za-z0-9_.]*\(/ {
        kind = $0
        sub(/\(.*/, "", kind)
        sub(/^[ \t]*/, "", kind)
        sub(/^native\./, "", kind)
      }

      /^[ \t]*name[ \t]*=[ \t]*"[^"]+"/ {
        name = $0
        sub(/^[^"]*"/, "", name)
        sub(/".*/, "", name)

        # `name = "%s_test" % name` and friends: a format string is not a
        # target name, and no legal bazel name contains % or {.
        if (name ~ /[%{]/) next

        printf "%-30s\t%-14s\t%s\t%s\t%s\n", \
          name, (kind == "" ? "?" : kind), \
          (is_build ? "//" pkg ":" name : rel), \
          FILENAME, FNR
      }
    '
}

# _bazel_definition_pick <initial-query>
#
# fzf over an index on stdin, returning the selected raw index line.
#
# Matching is restricted to the name column so deep package paths cannot
# pollute the ranking, while kind and the full label stay visible - in a
# large repo same-named targets in different packages are the norm, so the
# label is what tells them apart. The preview centres on the definition
# itself, which is both cheaper and more informative than re-querying bazel
# on every keystroke.
function _bazel_definition_pick() {
  local query="${1:-}"

  local preview='
    line={5}; file={4}
    start=$(( line > 10 ? line - 10 : 1 ))
    end=$(( line + 40 ))
    if command -v bat > /dev/null 2>&1; then
      bat --color=always --style=numbers --highlight-line "${line}" \
          --line-range "${start}:${end}" -- "${file}"
    else
      sed -n "${start},${end}p" "${file}"
    fi
  '

  fzf \
    --prompt="Select a target definition > " \
    --delimiter=$'\t' \
    --with-nth=1,2,3 \
    --nth=1 \
    --tabstop=1 \
    --query="${query}" \
    --height=60% \
    --layout=reverse \
    --preview="${preview}" \
    --preview-window='right,55%,wrap,<100(down,60%,wrap)'
}

# _bazel_definition_buffer_and_pick <root> <use-grep> <initial-query>
#
# Buffers an index into a temp file, then hands it to fzf - same reasoning as
# _bazel_buffer_and_pick: keep the query's own output off the selection list
# while leaving its diagnostics visible.
#
# Returns the selected index line on stdout, 1 if the user cancels.
function _bazel_definition_buffer_and_pick() {
  local root="$1"
  local use_grep="$2"
  local query="${3:-}"

  local tmp
  tmp="$(mktemp)" || return 1
  (
    trap 'rm -f "${tmp}"' EXIT

    if (( use_grep )); then
      _bazel_target_index_grep "${root}" > "${tmp}"
    else
      # bazel's stderr is left inherited so server startup and warnings stay
      # visible above the fzf prompt. $! is the pipeline's last element, which
      # exits once bazel has closed the pipe and awk has flushed the index.
      bazel query 'kind("rule", //...)' --output=location "${_BAZEL_QUERY_FLAGS[@]}" \
        | _bazel_location_to_index > "${tmp}" &
      _bazel_spin_while $! "Indexing targets..."
    fi

    # --keep_going exits non-zero on a partially broken tree, so judge the
    # run by whether we got an index rather than by the exit status.
    if [[ ! -s "${tmp}" ]]; then
      print -u2 -r -- "bazel: no targets found"
      exit 1
    fi

    local selection
    selection="$(_bazel_definition_pick "${query}" < "${tmp}")"

    [[ -n "${selection}" ]] || exit 1
    printf '%s\n' "${selection}"
  )
}

# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------

# Select a single runnable target (binary) and queue `bazel run <target>`
# as the next command line for editing/execution.
function bazel_find_runnable_target() {
  local target
  target="$(_bazel_buffer_and_pick \
    "Select a runnable target > " \
    'kind(".*_binary", ...)')" || return
  print -z "bazel run ${target}"
}

# Select one or more testable targets (supports multi-select with TAB /
# ctrl-a) and queue `bazel test <target...>` as the next command line.
function bazel_find_testable_target() {
  local targets
  targets="$(_bazel_buffer_and_pick \
    "Select testable target(s) > " \
    'kind("(test|test_suite) rule", ...)' \
    "multi")" || return

  print -z "bazel test ${targets//$'\n'/ }"
}

# Select any single target and queue `bazel build <target>` as the next
# command line.
function bazel_find_any_target() {
  local target
  target="$(_bazel_buffer_and_pick \
    "Select a target > " \
    '...')" || return
  print -z "bazel build ${target}"
}

# bazel_find_target_by_kind <kind-pattern>
#
# Ad-hoc kind filter without writing a new function.
# Example:
#   bazel_find_target_by_kind "go_library"
#   bazel_find_target_by_kind ".*_library"
function bazel_find_target_by_kind() {
  local kind="${1:?Usage: bazel_find_target_by_kind <kind-pattern>}"
  _bazel_buffer_and_pick \
    "Select a ${kind} target > " \
    "kind(\"${kind}\", ...)"
}

# Fuzzy-find a target by name and queue an editor command that opens the file
# at the line where the target is defined.
#
# Usage:
#   bazel_find_target_definition [-g|--grep] [initial-query]
#
#   -g, --grep   Build the index by reading BUILD files instead of asking
#                bazel. Instant, and works when the workspace will not load,
#                but blind to macro-generated target names.
#
# Example:
#   bazel_find_target_definition my_target
function bazel_find_target_definition() {
  local use_grep=0
  local query=""

  while (( $# )); do
    case "$1" in
      -g | --grep)
        use_grep=1
        shift
        ;;
      -h | --help)
        print -r -- \
          "Usage: bazel_find_target_definition [-g|--grep] [initial-query]"
        return 0
        ;;
      --)
        shift
        query="$*"
        break
        ;;
      *)
        query="$*"
        break
        ;;
    esac
  done

  local root
  if ! root="$(_bazel_workspace_root)"; then
    print -u2 -r -- "bazel: not inside a bazel workspace"
    return 1
  fi

  local selection
  selection="$(_bazel_definition_buffer_and_pick \
    "${root}" "${use_grep}" "${query}")" || return

  local -a fields
  fields=("${(@ps:\t:)selection}")

  local file="${fields[4]}" line="${fields[5]}"

  # Shorten to a cwd-relative path when we are inside it - the index carries
  # absolute paths so the preview works from any subdirectory, but an
  # absolute path makes for an unwieldy command line.
  local path="${file#${PWD}/}"
  print -z "${EDITOR:-vim} +${line} ${(q-)path}"
}

# Select a buildifier target (check/fix) and queue `bazel run <target>`
# as the next command line.
function bazel_find_buildifier_target() {
  local target
  target="$(_bazel_buffer_and_pick \
    "Select a buildifier target > " \
    'kind("buildifier", ...)')" || return
  print -z "bazel run ${target}"
}
