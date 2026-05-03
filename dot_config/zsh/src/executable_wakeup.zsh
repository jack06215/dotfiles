#!/usr/bin/env zsh

echo "$(date) sleepwatcher triggered ($0)" >> "/tmp/sleepwatcher.log"
source "$HOME/.zsh/darwin_pre_init.zsh"
export PYTHONPATH="$HOME/.zsh"

# Get the day of the week (0 = Sunday, 6 = Saturday)
day_of_week=$(date +%w)

# Skip weekends
if [[ "$day_of_week" -eq 0 || "$day_of_week" -eq 6 ]]; then
  exit 0
fi

# Skip if disabled in DB
if ! "$SYS_PYTHON_BIN" -m python.sleepwatcher.should_run wake; then
  exit 0
fi

$HOME/myscripts/teamspirit-in >> "/tmp/teamspirit.log" 2>&1
