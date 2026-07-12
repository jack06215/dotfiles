# shellcheck shell=bash

# Shared flags for all bazel query invocations.
# Centralised here so changes apply everywhere.
_BAZEL_QUERY_FLAGS=(
  --output=label
  --noshow_progress
  --keep_going # continue past errors in broken targets
  --color=yes
)

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

    # stdout (labels) → buffer for fzf
    # stderr (server startup, progress, warnings) → /dev/tty so they're
    # visible above the fzf prompt without polluting the selection list
    bazel query \
      "${query}" \
      "${_BAZEL_QUERY_FLAGS[@]}" \
      > "${tmp}" 2> /dev/tty

    local selection
    selection="$(_bazel_fzf_pick "${prompt}" "${multi}" < "${tmp}")"

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

# Select a buildifier target (check/fix) and queue `bazel run <target>`
# as the next command line.
function bazel_find_buildifier_target() {
  local target
  target="$(_bazel_buffer_and_pick \
    "Select a buildifier target > " \
    'kind("buildifier", ...)')" || return
  print -z "bazel run ${target}"
}
