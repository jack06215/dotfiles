# shellcheck shell=bash
# shellcheck disable=SC1091
# filetype=sh

ROOT_CACHE_DIR="${HOME}/.flywheel"
TARGETS_CACHE_FILE="${ROOT_CACHE_DIR}/.bazel-targets"

function _stat_mtime() {
  local file="${1}"

  if stat -f %m "${file}" >/dev/null 2>&1; then
    # macOS
    stat -f %m "${file}"
  else
    # Linux
    stat -c %Y "${file}"
  fi
}

function _ensure_bazel_cache_dir() {
  [[ -d "${ROOT_CACHE_DIR}" ]] || mkdir -p "${ROOT_CACHE_DIR}"
}

function _bazel_cache_stale() {
  [[ ! -f "${TARGETS_CACHE_FILE}" ]] && return 0

  local now mtime
  now="$(date +%s)"
  mtime="$(_stat_mtime "${TARGETS_CACHE_FILE}")" || return 0

  # 24 hours = 86400 seconds
  ((now - mtime > 86400))
}

function bazel_refresh_targets() {
  _ensure_bazel_cache_dir

  echo "Refreshing Bazel targets..."

  bazel query \
    'kind("(.*_binary|.*_test)", //...)' \
    --output=label \
    --noshow_progress \
    --keep_going |
    sort -u >|"${TARGETS_CACHE_FILE}"

  echo "✔ Cached $(wc -l <"${TARGETS_CACHE_FILE}") targets → ${TARGETS_CACHE_FILE}"
}

function bazel_get_targets() {
  local mode="${1:-any}"
  local filter='.'

  _ensure_bazel_cache_dir

  if _bazel_cache_stale; then
    echo "Bazel target cache stale — refreshing..." >&2
    bazel_refresh_targets || return 1
  fi

  [[ -s "${TARGETS_CACHE_FILE}" ]] || {
    echo "Target cache missing or empty — run bazel_refresh_targets" >&2
    return 1
  }

  case "${mode}" in
  test) filter='_test$' ;;
  api) filter='(^|[^a-zA-Z0-9])api([^a-zA-Z0-9]|$)' ;;
  console) filter='(^|[^a-zA-Z0-9])console([^a-zA-Z0-9]|$)' ;;
  sealedsecrets) filter='(^|[^a-zA-Z0-9])sealedsecrets([^a-zA-Z0-9]|$)' ;;
  *) filter='.' ;;
  esac

  local target
  target="$(
    grep -E "${filter}" "${TARGETS_CACHE_FILE}" |
      fzf \
        --prompt="Bazel ${mode} ❯ " \
        --preview 'bazel query "kind(.*, {})" --output=build 2>/dev/null' \
        --preview-window=right:60%:wrap
  )" || return 1

  [[ -n "${target}" ]] || return 1
  echo "${target}"
}
