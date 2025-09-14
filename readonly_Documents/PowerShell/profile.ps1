# starship configuration
$ENV:STARSHIP_CONFIG = "$HOME\.starship\starship.toml"
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
$env:SHELL = "pwsh"

# Set Alias
Set-Alias g goto
Set-Alias pbcopy Set-Clipboard
Set-Alias -Name su -Value admin
Set-Alias lg lazygit
$GotoPath = @{
    "monorepo"   = "$HOME/Documents/Mycodespace/monorepo"
    "jack06215"  = "$HOME/Documents/Mycodespace/jack06215"
    "nvim"       = "$HOME/AppData/Local/nvim"
    "powershell" = (Split-Path -Parent $PROFILE.CurrentUserAllHosts)
    "chezmoi"    = "$HOME/.local/share/chezmoi"
}

if (Get-Module PSReadLine) {
    $vimCommand = Get-Command vim -ErrorAction Ignore
    if ($vimCommand) {
        if (Get-Module PSFzf) {
            Write-Warning "PSFzf is already loaded. Setting Vim keybindings will override PSFzf keybinds (like Ctrl+r)."
        }
        Set-PSReadLineOption -EditMode Vi
        #Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
        #Set-PSReadlineKeyHandler -Key Ctrl+Shift+r -Function ForwardSearchHistory
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

function goto {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("monorepo", "jack06215", "nvim", "powershell", "chezmoi")]
        [string]$label
    )
    if ($GotoPath.ContainsKey($label)) {
        Write-Host "Navigating to $label at $($GotoPath[$label])" -ForegroundColor Green
        Set-Location $GotoPath[$label]
    }
}

