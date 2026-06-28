#!/usr/bin/env zsh

source "$ZDOTDIR/src/core.zsh"

function zsh_python_init() {
  local zsh_python_dir="$ZDOTDIR/src/python"

  cd "$zsh_python_dir" || return 1
  export PYTHONPATH="$ZDOTDIR/src/python"

  local venv_path
  venv_path="$(poetry env info -p 2>/dev/null)" || return 1

  echo "$venv_path/bin/python"
}

function cd_zsh_python() {
  echo "$ZDOTDIR/src/python"
}

function load_zsh_python_venv_macos() {
  (
    cd "$ZDOTDIR/src/python" || exit 1
    command "$HOME/.asdf/shims/poetry" env info -p
  )
}

function load_zsh_python_venv_wsl() {
  (
    cd "$ZDOTDIR/src/python" || exit 1
    command "/home/linuxbrew/.linuxbrew/bin/poetry" env info -p
  )
}

# python
if is_macos; then
    _ZSH_PYTHON="$(load_zsh_python_venv_macos)"
elif is_wsl; then
    _ZSH_PYTHON="$(load_zsh_python_venv_wsl)"
else
    _ZSH_PYTHON="/data/data/com.termux/files/usr"
fi
export ZSH_PYTHON_ROOT=$_ZSH_PYTHON
export ZSH_PYTHON_BIN="$_ZSH_PYTHON/bin/python"
export ZSH_PIP_BIN="$_ZSH_PYTHON/bin/pip"

# python cli
export ALEMBIC_BIN="$ZSH_PYTHON_ROOT/bin/alembic"
export LLM_BIN="$ZSH_PYTHON_ROOT/bin/llm"
export DBT_BIN="$ZSH_PYTHON_ROOT/bin/dbt"
export GDOWN_BIN="$ZSH_PYTHON_ROOT/bin/gdown"
export RUFF_BIN="$ZSH_PYTHON_ROOT/bin/ruff"

alias zsh_python='$ZSH_PYTHON_BIN'
alias zsh_pip='$ZSH_PIP_BIN'

alias llm='$LLM_BIN'
alias alembic='$ALEMBIC_BIN'
alias ruff='$RUFF_BIN'
alias gdown='$GDOWN_BIN'
