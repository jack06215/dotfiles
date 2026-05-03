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

export PATH="$HOME/.asdf/shims:$PATH"
