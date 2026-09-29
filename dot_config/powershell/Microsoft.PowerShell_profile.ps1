# PowerShell 7 profile.
#
# chezmoi copies this to ~/.config/powershell/, and
# run_onchange_after_link-powershell-profile.ps1 copies the whole
# dot_config/powershell tree into %USERPROFILE%\Documents\PowerShell - the only
# place pwsh looks for $PROFILE, and the only per-user entry on
# $env:PSModulePath, so Modules\MyModule has to land there too.
#
# Deliberately NOT a chezmoi template. On WSL2 the same file is pushed to the
# Windows home by run_onchange_after_push-windows-configs, and a template
# rendered under WSL would bake Linux paths (.xdg.configHome is /home/<user>/
# .config there) into a file that only ever runs on Windows. Every path below is
# therefore resolved at runtime.
#
# Installation lives in setup.ps1, not here. This file used to call
# Install-Packages on every shell start, which meant every new terminal hit the
# PowerShell Gallery and could download a font.

# The profile only sets the session up. Its commands - touch, grep, uptime,
# Edit-Profile and the rest - live in MyModule, one file each under
# Modules\MyModule\Functions, with comment-based help that fman browses.
#
# Get-Command rather than MyModule's Test-CommandExists throughout, so the setup
# below does not depend on the module having loaded.

# Set Default Editor
$editors = @('nvim', 'vim', 'code', 'notepad++', 'notepad')

foreach ($editor in $editors) {
    if (Get-Command $editor -ErrorAction Ignore) {
        Set-Alias -Name vim -Value $editor
        break
    }
}

#### Startup Script ####

# Import only. setup.ps1 is what installs these; a missing one means it has not
# run yet, and a warning beats silently losing the icons or the keybinds.
#
# -DisableNameChecking because MyModule keeps names like grep-table,
# Clean-Downloads and Reload-Profile, whose verbs are not on Get-Verb's list;
# without it every shell start warns about them.
foreach ($module in 'Terminal-Icons', 'PSFzf', 'MyModule') {
    if (Get-Module -ListAvailable -Name $module) {
        Import-Module -Name $module -DisableNameChecking
    }
    else {
        Write-Warning "$module is not installed; run ~/setup.ps1"
    }
}

# Chocolatey's tab completion, when Chocolatey is installed.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module $ChocolateyProfile
}

# The chezmoi-managed starship config. This used to point at
# ~/.starship/starship.toml - an unmanaged copy that shadowed this one. The
# fallback mirrors chezmoi's own default for .xdg.configHome.
$configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$env:STARSHIP_CONFIG = Join-Path $configHome 'starship/starship.toml'

# yazi reads %APPDATA%\yazi\config on Windows, so without this it never sees the
# config this repo manages. ~/.config/yazi is yazi's own default on Unix, which
# is why nothing in dot_zshenv sets this. setup.ps1 also persists it at User
# scope, for a yazi started outside pwsh.
$env:YAZI_CONFIG_HOME = Join-Path $configHome 'yazi'
if (Get-Command starship -ErrorAction Ignore) {
    Invoke-Expression (&starship init powershell)
}
if (Get-Command zoxide -ErrorAction Ignore) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}
# mise stands in for asdf here: asdf is a bash program and does not run on
# native Windows, while mise reads the same ~/.tool-versions. Needs pwsh 7.2+.
if (Get-Command mise -ErrorAction Ignore) {
    (& mise activate pwsh) | Out-String | Invoke-Expression
}
$env:SHELL = "pwsh"

# Set Alias
Set-Alias g goto
Set-Alias pbcopy Set-Clipboard
Set-Alias pbpaste Get-Clipboard
Set-Alias -Name su -Value admin
Set-Alias lg lazygit

# The bazel pickers, under the names alias.zsh gives them on the other side, so
# the muscle memory carries. The functions live in MyModule\Functions\Bazel.
Set-Alias bzlrun Invoke-Bzlrun
Set-Alias bzltest Invoke-Bzltest
Set-Alias bzlbuild Invoke-Bzlbuild

# fman from functions.zsh, which lives in MyModule\Functions\Utility.
Set-Alias fman Invoke-FuzzyHelp

if (Get-Module PSReadLine) {
    $vimCommand = Get-Command vim -ErrorAction Ignore
    if ($vimCommand) {
        Set-PSReadLineOption -EditMode Vi
        # PSFzf's chords are set after EditMode Vi so they land on top of the vi
        # keymap rather than under it.
        if (Get-Module PSFzf) {
            Set-PsFzfOption `
                -EnableTabCompletion `
                -PSReadlineChordReverseHistory 'Ctrl+r' `
                -PSReadlineChordProvider 'Ctrl+t' `
                -PSReadlineChordSetLocation 'Alt+c'
        }
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -MaximumHistoryCount 10000
        Set-PSReadLineOption -ViModeIndicator Cursor
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
        if (!($env:VISUAL)) {
            $env:VISUAL = "vim"
        }
        if (!($env:GIT_EDITOR)) {
            $env:GIT_EDITOR = "'$($vimCommand.Path)'"
        }
    }
    Remove-Variable vimCommand
}
