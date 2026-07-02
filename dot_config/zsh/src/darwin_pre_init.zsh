#!/usr/bin/env zsh
# shellcheck shell=bash
export HOMEBREW_HOME="/opt/homebrew"

if command -v brew >/dev/null 2>&1; then
  _sys_python_root="$(brew --prefix python@3.12 2>/dev/null)"

  # brew --prefix prints nothing if the formula isn't installed - only wire
  # up the exports/aliases when the interpreter actually resolved.
  if [[ -n "$_sys_python_root" && -x "$_sys_python_root/bin/python3.12" ]]; then
    export SYS_PYTHON_ROOT="$_sys_python_root"
    export SYS_PYTHON_BIN="$SYS_PYTHON_ROOT/bin/python3.12"
    export SYS_PIP_BIN="$SYS_PYTHON_ROOT/bin/pip3.12"

    alias sys_python='$SYS_PYTHON_BIN'
    alias sys_pip='$SYS_PIP_BIN'
  fi
  unset _sys_python_root
fi
