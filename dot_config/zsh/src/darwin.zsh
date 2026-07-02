# homebrew
export HOMEBREW_HOME="/opt/homebrew"

function brew_trust_taps() {
  emulate -L zsh
  setopt local_options pipefail

  local taps=(
    atlassian/acli
    auth0/auth0-cli
    bufbuild/buf
    cockroachdb/tap
    derailed/k9s
    hashicorp/tap
    kdash-rs/kdash
    leoafarias/fvm
    localstack/tap
    nikitabobko/tap
    yoheimuta/protolint
  )

  local tap failed=()
  for tap in $taps; do
    echo "Trusting $tap..."
    if ! brew trust "$tap"; then
      failed+=("$tap")
    fi
  done

  if (( ${#failed[@]} )); then
    echo "\nFailed to trust: ${failed[*]}" >&2
    return 1
  fi

  echo "\nAll taps trusted."
}

