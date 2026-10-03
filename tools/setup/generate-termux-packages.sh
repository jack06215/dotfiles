#!/usr/bin/env bash
set -euo pipefail -o posix

# Writes pkgfiles/termux, the package manifest setup.sh installs on Termux,
# from what this phone has installed: every package marked manual, minus
# Termux's own base system and the EXCLUDED list below.
#
# No bazel target, unlike the Brewfile exporters: the manifest can only be
# dumped on the phone, and bazel is not among what it installs there. Run it
# from the checkout. As in generate-brewfile.sh, chezmoi says where that is,
# so the manifest is written into the source tree, never into $HOME.
source_dir="${BUILD_WORKSPACE_DIRECTORY:-$(chezmoi source-path)}"
manifest="${source_dir}/pkgfiles/termux"

# What Termux's bootstrap installs, from termux-packages'
# scripts/generate-bootstraps.sh. The bootstrap marks these and everything
# they depend on as manually installed, so without this filter a fresh Termux
# already lists ~80 packages nobody asked for.
BOOTSTRAP_ROOTS=(
  apt bash bzip2 command-not-found coreutils curl dash diffutils findutils
  gawk grep gzip less procps psmisc sed tar termux-core termux-exec
  termux-keyring termux-tools util-linux xz-utils
  ed debianutils dos2unix inetutils lsof nano net-tools patch unzip
)

# Installed on this phone, but not to be reinstalled on a fresh one. Listed
# here rather than pruned from the manifest, which the next run would undo.
EXCLUDED=(
  # an x86-64 VM
  qemu-common qemu-system-x86-64-headless qemu-utils
  # databases
  duckdb mariadb postgresql
  # JVM and build toolchains
  bazel dart openjdk-21
  # media and misc
  dlib ffmpeg transmission
  # quits at startup without root: Android hides /proc/stat from apps
  btop
)

function require_termux() {
  if [[ -z "${TERMUX_VERSION:-}" ]]; then
    echo 'generate-termux-packages: run this inside Termux.' >&2
    exit 1
  fi
}

function entries_of() {
  sed -E 's/[[:space:]]*#.*$//' "$1" | grep -E '[^[:space:]]' | sort -u
}

# The installed bootstrap roots and, recursively, what they depend on.
function base_packages() {
  local -a roots=()
  read -r -a roots <<< "$(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' \
    "${BOOTSTRAP_ROOTS[@]}" 2> /dev/null | awk '$1 == "ii" { print $2 }' | tr '\n' ' ')"

  apt-cache depends --recurse --installed --no-recommends --no-suggests \
    --no-conflicts --no-breaks --no-replaces --no-enhances "${roots[@]}" \
    | grep -v '^[ <]' | sort -u
}

function header() {
  cat << 'EOF'
# Termux package manifest, one package per line, installed by setup.sh with
# apt-get. Written by tools/setup/generate-termux-packages.sh from the phone's
# manually installed packages, minus Termux's base system and the script's
# EXCLUDED list - change those there, since a rerun rewrites this file. The
# *-repo entries add apt sources, so setup.sh installs them first.
EOF
}

# As in generate-brewfile.sh: name what the old manifest had and the new one
# lacks, so a package removed from the phone by accident gets noticed.
function warn_dropped() {
  local old_file="$1" new_file="$2" tmpdir="$3"
  [[ -f "${old_file}" ]] || return 0

  entries_of "${old_file}" > "${tmpdir}/old-entries"
  entries_of "${new_file}" > "${tmpdir}/new-entries"
  local dropped
  dropped="$(comm -23 "${tmpdir}/old-entries" "${tmpdir}/new-entries")"

  [[ -n "${dropped}" ]] || return 0

  printf '\nDropped (in the old manifest, not installed manually now):\n' >&2
  printf '%s\n' "${dropped}" | sed 's/^/  /' >&2
  printf 'Reinstall them and rerun, or restore the lines, if they are still wanted.\n' >&2
}

function dump_manifest() {
  local tmpdir
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/termux-packages.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmpdir}'" EXIT

  apt-mark showmanual | sort -u > "${tmpdir}/manual"
  base_packages > "${tmpdir}/base"
  printf '%s\n' "${EXCLUDED[@]}" | sort -u > "${tmpdir}/excluded"

  {
    header
    comm -23 "${tmpdir}/manual" "${tmpdir}/base" | comm -23 - "${tmpdir}/excluded"
  } > "${tmpdir}/manifest"

  warn_dropped "${manifest}" "${tmpdir}/manifest" "${tmpdir}"

  mkdir -p "$(dirname "${manifest}")"
  mv "${tmpdir}/manifest" "${manifest}"
  rm -rf "${tmpdir}"
  trap - EXIT
}

function report() {
  local packages repos
  packages="$(entries_of "${manifest}" | wc -l | tr -d ' ')"
  repos="$(entries_of "${manifest}" | grep -c -- '-repo$' || true)"

  printf 'Wrote %s\n  %s packages, %s of them repos\n' "${manifest}" "${packages}" "${repos}"
}

require_termux
dump_manifest
report
