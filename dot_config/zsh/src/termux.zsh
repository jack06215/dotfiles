# shellcheck shell=bash

# Every Termux session opens straight into the tmux session "main", creating
# it the first time and re-attaching after that. init.zsh sources this before
# the rest of the config, so the outer shell never loads plugins, completion
# or the prompt only to sit behind tmux; the shell inside tmux does that.
#
# Skipped inside tmux itself, for `zsh -c`/`zsh -ic` runs (tools that borrow
# an interactive shell for one command), in other terminals such as VS Code's
# (Termux sets no $TERM_PROGRAM), and over ssh into the phone.
#
# `&& exit` rather than `exec`: if tmux cannot start (a broken tmux.conf, a
# missing package), this falls through to a plain shell instead of closing the
# session straight away. Detaching closes the Termux session; "main" keeps
# running and the next session re-attaches to it.
if [[ -z "$TMUX" && -z "$ZSH_EXECUTION_STRING" && -z "$TERM_PROGRAM" && -z "$SSH_CONNECTION" ]] \
  && (($+commands[tmux])); then
  tmux new-session -A -s main && exit
fi
