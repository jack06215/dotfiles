#!/usr/bin/env zsh
# shellcheck shell=bash

# Homebrew is already on PATH: ~/.zshenv sets it up for every zsh, not just
# interactive ones (and without `brew shellenv`'s exported FPATH).

export C_DRIVE="/mnt/c/"

# Read straight from the opt/ link rather than `brew --prefix`, which forks
# brew; only wired up when python@3.12 is actually installed.
if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/opt/python@3.12/bin/python3.12" ]]; then
  export SYS_PYTHON_ROOT="$HOMEBREW_PREFIX/opt/python@3.12"
  export SYS_PYTHON_BIN="$SYS_PYTHON_ROOT/bin/python3.12"
  export SYS_PIP_BIN="$SYS_PYTHON_ROOT/bin/pip3.12"

  alias sys_python='$SYS_PYTHON_BIN'
  alias sys_pip='$SYS_PIP_BIN'
fi
