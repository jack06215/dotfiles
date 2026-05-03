#!/usr/bin/env zsh
# shellcheck shell=bash

# export SYS_PYTHON_ROOT="/opt/homebrew/Cellar/python@3.12/3.12.12_1"
export SYS_PYTHON_ROOT="$(brew --prefix python@3.12)"
export SYS_PYTHON_BIN="$SYS_PYTHON_ROOT/bin/python3.12"
export SYS_PIP_BIN="$SYS_PYTHON_ROOT/bin/pip3.12"

alias sys_python='$SYS_PYTHON_BIN'
alias sys_pip='$SYS_PIP_BIN'
