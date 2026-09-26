#!/usr/bin/env zsh
# shellcheck shell=bash

alias firefox='$C_DRIVE/Program\ Files/Mozilla\ Firefox/firefox.exe'
function firefox_version() {
  pwsh -NoProfile -Command \
    "(Get-Item 'C:\Program Files\Mozilla Firefox\firefox.exe').VersionInfo.ProductVersion"
}
alias chrome='$C_DRIVE/Program\ Files/Google/Chrome/Application/chrome.exe'
function chrome_version() {
  pwsh -NoProfile -Command \
    "(Get-Item 'C:\Program Files\Google\Chrome\Application\chrome.exe').VersionInfo.ProductVersion"
}

# asdf.zsh (sourced earlier) already puts the shims dir on PATH. Re-prepending
# it here would put it ahead of ~/.local/bin (the pinned shfmt) and override
# ZSH_RUBY_MANAGER=rbenv - the same reason darwin_post_init.zsh dropped it.
