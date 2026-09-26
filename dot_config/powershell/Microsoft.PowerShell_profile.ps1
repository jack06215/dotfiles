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

# Help Function
function Show-Help {
    $helpText = @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

$($PSStyle.Foreground.Green)Update-PowerShell$($PSStyle.Reset) - Checks for the latest PowerShell release and updates if a new version is available.

$($PSStyle.Foreground.Green)Edit-Profile$($PSStyle.Reset) - Opens the current user's profile for editing using the configured editor.

$($PSStyle.Foreground.Green)Reload-Profile$($PSStyle.Reset) - Reloads the current profile.

$($PSStyle.Foreground.Green)touch$($PSStyle.Reset) <file> - Creates a new empty file.

$($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Finds files recursively with the specified name.

$($PSStyle.Foreground.Green)Get-PubIP$($PSStyle.Reset) - Retrieves the public IP address of the machine.

$($PSStyle.Foreground.Green)uptime$($PSStyle.Reset) - Displays the system uptime.

$($PSStyle.Foreground.Green)unzip$($PSStyle.Reset) <file> - Extracts a zip file to the current directory.

$($PSStyle.Foreground.Green)grep$($PSStyle.Reset) <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.

$($PSStyle.Foreground.Green)grep-table$($PSStyle.Reset) <regex> - Formats matching pipeline objects as a table.

$($PSStyle.Foreground.Green)df$($PSStyle.Reset) - Displays information about volumes.

$($PSStyle.Foreground.Green)sed$($PSStyle.Reset) <file> <find> <replace> - Replaces text in a file.

$($PSStyle.Foreground.Green)which$($PSStyle.Reset) <name> - Shows the path of the command.

$($PSStyle.Foreground.Green)export$($PSStyle.Reset) <name> <value> - Sets an environment variable.

$($PSStyle.Foreground.Green)pkill$($PSStyle.Reset) <name> - Kills processes by name.

$($PSStyle.Foreground.Green)pgrep$($PSStyle.Reset) <name> - Lists processes by name.

$($PSStyle.Foreground.Green)head$($PSStyle.Reset) <path> [n] - Displays the first n lines of a file (default 10).

$($PSStyle.Foreground.Green)tail$($PSStyle.Reset) <path> [n] - Displays the last n lines of a file (default 10).

$($PSStyle.Foreground.Green)Clear-Cache$($PSStyle.Reset) - Clears Windows prefetch, temp and INetCache directories.

$($PSStyle.Foreground.Green)Clean-Downloads$($PSStyle.Reset) [-Days n] - Deletes downloads older than n days (default 30).

Packages, modules and fonts are installed by $($PSStyle.Foreground.Magenta)~/setup.ps1$($PSStyle.Reset), not by this profile.
Use '$($PSStyle.Foreground.Magenta)Show-Help$($PSStyle.Reset)' to display this help message.
"@
    Write-Host $helpText
}

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

function Update-PowerShell {
    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
            Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
        }
        else {
            Write-Host "Your PowerShell is up to date." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}


function Clear-Cache {
    Write-Host "Clearing cache..." -ForegroundColor Cyan

    # Clear Windows Prefetch
    Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

    # Clear Windows Temp
    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear User Temp
    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear Internet Explorer Cache
    Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Cache clearing completed." -ForegroundColor Green
}

function Clean-Downloads {
    param([int]$Days = 30)
    $cutoff = (Get-Date).AddDays(-$Days)
    Get-ChildItem "$env:USERPROFILE\Downloads" -Recurse |
    Where-Object { !$_.PsIsContainer -and $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force
}


# Set Default Editor
$editors = @('nvim', 'vim', 'code', 'notepad++', 'notepad')

foreach ($editor in $editors) {
    if (Test-CommandExists $editor) {
        Set-Alias -Name vim -Value $editor
        break
    }
}

# Quick Access to Editing the Profile
# CurrentUserCurrentHost, not CurrentUserAllHosts: the file this repo manages is
# Microsoft.PowerShell_profile.ps1, and AllHosts would open a profile.ps1 that
# does not exist.
function Edit-Profile {
    vim $PROFILE.CurrentUserCurrentHost
}

function touch($file) { "" | Out-File $file -Encoding ASCII }

function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    }
    else {
        Start-Process wt -Verb runAs
    }
}

function uptime {
    try {
        # find date/time format
        $dateFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.ShortDatePattern
        $timeFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.LongTimePattern

        # check powershell version
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $lastBoot = (Get-WmiObject win32_operatingsystem).LastBootUpTime
            $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)

            # reformat lastBoot
            $lastBoot = $bootTime.ToString("$dateFormat $timeFormat")
        }
        else {
            $lastBoot = (Get-Uptime -Since).ToString("$dateFormat $timeFormat")
            $bootTime = [System.DateTime]::ParseExact($lastBoot, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
        }

        # Format the start time
        $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBoot]"
        Write-Host "System started on: $formattedBootTime" -ForegroundColor DarkGray

        # calculate uptime
        $uptime = (Get-Date) - $bootTime

        # Uptime in days, hours, minutes, and seconds
        $days = $uptime.Days
        $hours = $uptime.Hours
        $minutes = $uptime.Minutes
        $seconds = $uptime.Seconds

        # Uptime output
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f $days, $hours, $minutes, $seconds) -ForegroundColor Blue

    }
    catch {
        Write-Error "An error occurred while retrieving system uptime."
    }
}


function Reload-Profile {
    & $profile
}

function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function grep-table {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin {
        $collected = @()
    }

    process {
        try {
            $text = ($_ | Out-String).Trim()
            if ($text -match $Pattern) {
                $collected += , $_  # Wrap in array to prevent hashtable merge
            }
        }
        catch {
            Write-Warning "Skipping unprocessable object: $_"
        }
    }

    end {
        if ($collected.Count -gt 0) {
            $collected | Format-Table -AutoSize
        }
    }
}

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}


#### Startup Script ####
Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to display help$($PSStyle.Reset)"

# Import only. setup.ps1 is what installs these; a missing one means it has not
# run yet, and a warning beats silently losing the icons or the keybinds.
foreach ($module in 'Terminal-Icons', 'PSFzf', 'MyModule') {
    if (Get-Module -ListAvailable -Name $module) {
        Import-Module -Name $module
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
if (Test-CommandExists starship) {
    Invoke-Expression (&starship init powershell)
}
if (Test-CommandExists zoxide) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
}
# mise stands in for asdf here: asdf is a bash program and does not run on
# native Windows, while mise reads the same ~/.tool-versions. Needs pwsh 7.2+.
if (Test-CommandExists mise) {
    (& mise activate pwsh) | Out-String | Invoke-Expression
}
$env:SHELL = "pwsh"

# Set Alias
Set-Alias g goto
Set-Alias pbcopy Set-Clipboard
Set-Alias pbpaste Get-Clipboard
Set-Alias -Name su -Value admin
Set-Alias lg lazygit

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
