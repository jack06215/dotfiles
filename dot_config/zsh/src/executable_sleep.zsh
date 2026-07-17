#!/usr/bin/env zsh

# Launchd's environment can be sparser than a login shell's - don't assume
# XDG_CACHE_HOME made it through.
: "${XDG_CACHE_HOME:=$HOME/.cache}"
mkdir -p "$XDG_CACHE_HOME"
echo "$(date) sleepwatcher triggered ($0)" >> "$XDG_CACHE_HOME/sleepwatcher.log"
source "$ZDOTDIR/src/darwin_pre_init.zsh"
export PYTHONPATH="$HOME/workspace/jack06215/monorepo/python"

# Get the day of the week (0 = Sunday, 6 = Saturday)
day_of_week=$(date +%w)

# Skip weekends
if [[ "$day_of_week" -eq 0 || "$day_of_week" -eq 6 ]]; then
  exit 0
fi

# darwin_pre_init.zsh only exports SYS_PYTHON_BIN when brew/python@3.12
# actually resolved - without this check, running "" as a command fails
# with no useful trace and we'd silently skip everything below.
if [[ -z "$SYS_PYTHON_BIN" || ! -x "$SYS_PYTHON_BIN" ]]; then
  echo "$(date) sleepwatcher: SYS_PYTHON_BIN unset/not executable, skipping should_run check" >> "$XDG_CACHE_HOME/sleepwatcher.log"
  exit 1
fi

# Skip if disabled in DB
if ! "$SYS_PYTHON_BIN" -m sleepwatcher.should_run sleep; then
  exit 0
fi

$HOME/myscripts/teamspirit-out >> /tmp/teamspirit.log 2>&1
