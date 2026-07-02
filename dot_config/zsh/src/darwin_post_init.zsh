#!/usr/bin/env zsh
# shellcheck shell=bash

alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
alias firefox_version='/Applications/Firefox.app/Contents/MacOS/firefox --version'
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias chrome_version='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version'

# asdf.zsh (sourced earlier via asdf.sh) already manages the shims dir.
# Re-prepending it here unconditionally would override an explicit
# ZSH_RUBY_MANAGER=rbenv choice made earlier in init.zsh, so it's removed.
