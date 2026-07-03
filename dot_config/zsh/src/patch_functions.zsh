#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC2296

# Some repos (e.g. flywheel-jp/monorepo) pin an old shfmt via .tool-versions
# and a company script periodically overwrites that file, so patching it
# doesn't stick - and asdf resolves .tool-versions by walking upward from
# cwd, so nested .tool-versions files shadow the repo root too.
#
# Installs a pinned shfmt straight from source via `go install` and symlinks
# it into ~/.local/bin, which dot_zshenv unconditionally puts ahead of the
# asdf shims dir on PATH for every shell - interactive or not. `asdf
# which`/`asdf exec shfmt` are unaffected and still show the asdf-managed
# version; only bare `shfmt` resolves to this one.
function s_shfmt_pinned() {
  local pinned="v3.13.1"
  local target="$HOME/.local/bin/shfmt"
  local current=""

  [[ -x "$target" ]] && current="$("$target" --version 2>/dev/null)"
  [[ "$current" == "$pinned" ]] && return 0

  if ! command -v go >/dev/null 2>&1; then
    print -u2 -- "s_shfmt_version: go not found on PATH, cannot install shfmt ${pinned}"
    return 1
  fi

  go install "mvdan.cc/sh/v3/cmd/shfmt@${pinned}" || return 1

  local gobin
  gobin="$(go env GOBIN)"
  [[ -z "$gobin" ]] && gobin="$(go env GOPATH)/bin"

  mkdir -p "$HOME/.local/bin"
  ln -sf "$gobin/shfmt" "$target"
  # zsh caches each command's resolved PATH location on first use and won't
  # rescan just because a higher-priority match showed up later - without
  # this, `shfmt` in the current shell keeps hitting whatever it resolved to
  # before this symlink existed.
  hash -r
}

# Reverses s_shfmt_pinned: removes the ~/.local/bin/shfmt symlink so bare
# `shfmt` falls back to the asdf shim. Only touches the path if it's still
# the symlink we created - leaves it alone otherwise.
function cl_shfmt_pinned() {
  local target="$HOME/.local/bin/shfmt"

  if [[ -L "$target" ]]; then
    rm -f "$target"
    # Same reasoning as in s_shfmt_pinned - forget the cached location so
    # `shfmt` re-resolves to the asdf shim immediately, not on the next shell.
    hash -r
  elif [[ -e "$target" ]]; then
    print -u2 -- "cl_shfmt_pinned: $target exists but isn't a symlink, leaving it alone"
    return 1
  fi
}
