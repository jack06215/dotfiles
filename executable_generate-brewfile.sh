#!/usr/bin/env bash
set -euo pipefail -o posix

# Resolved at runtime rather than templated in, so this file needs no chezmoi
# rendering and can be both the ~/generate-brewfile.sh target and the src of
# //:export_brewfile_macos. `bazel run` exports BUILD_WORKSPACE_DIRECTORY as the
# workspace root; outside bazel, ask chezmoi where its source directory is.
# Either way the manifest is written into the checkout, never into a build
# sandbox or the target tree.
source_dir="${BUILD_WORKSPACE_DIRECTORY:-$(chezmoi source-path)}"

case "$(uname -s)" in
  Darwin) manifest="${source_dir}/brewfiles/darwin" ;;
  Linux) manifest="${source_dir}/brewfiles/wsl2" ;;
  *)
    echo "generate-brewfile: no Brewfile manifest for $(uname -s)." >&2
    exit 1
    ;;
esac

function require_brew() {
  if command -v brew &> /dev/null; then
    return 0
  fi

  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "${candidate}" ]]; then
      eval "$("${candidate}" shellenv)"
      return 0
    fi
  done

  echo 'generate-brewfile: brew not found in PATH. Run setup.sh first.' >&2
  exit 1
}

function entries_of() {
  sed -nE 's/^(tap|brew|cask) "([^"]+)".*/\1 \2/p' "$1" | sort -u
}

function warn_dropped() {
  local old_file="$1" new_file="$2"
  [[ -f "${old_file}" ]] || return 0

  local old_entries new_entries dropped
  old_entries="$(mktemp -t Brewfile.old)"
  new_entries="$(mktemp -t Brewfile.new)"
  entries_of "${old_file}" > "${old_entries}"
  entries_of "${new_file}" > "${new_entries}"
  dropped="$(comm -23 "${old_entries}" "${new_entries}")"
  rm -f "${old_entries}" "${new_entries}"

  [[ -n "${dropped}" ]] || return 0

  printf '\nDropped (in the old Brewfile, not installed on request now):\n' >&2
  printf '%s\n' "${dropped}" | sed 's/^/  /' >&2
  printf 'Reinstall them and rerun, or restore the lines, if they are still wanted.\n' >&2
}

function dump_brewfile() {
  local tmpfile
  tmpfile="$(mktemp -t Brewfile)"
  # shellcheck disable=SC2064
  trap "rm -f '${tmpfile}'" EXIT

  local -a dump_args=(--formula --tap)
  if [[ "$(uname -s)" == 'Darwin' ]]; then
    dump_args+=(--cask)
  fi

  env -u TMUX brew bundle dump \
    "${dump_args[@]}" \
    --file="${tmpfile}" \
    --force

  warn_dropped "${manifest}" "${tmpfile}"

  mv "${tmpfile}" "${manifest}"
  trap - EXIT
}

function report() {
  local taps formulae casks
  taps="$(grep -c '^tap ' "${manifest}" || true)"
  formulae="$(grep -c '^brew ' "${manifest}" || true)"
  casks="$(grep -c '^cask ' "${manifest}" || true)"

  printf 'Wrote %s\n  %s taps, %s formulae, %s casks\n' \
    "${manifest}" "${taps}" "${formulae}" "${casks}"
}

require_brew
dump_brewfile
report
