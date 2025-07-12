$GotoPath = @{
    "monorepo"   = "$HOME/Documents/Mycodespace/monorepo"
    "jack06215"  = "$HOME/Documents/Mycodespace/jack06215"
    "nvim"       = "$HOME/AppData/Local/nvim"
    "powershell" = (Split-Path -Parent $PROFILE.CurrentUserAllHosts)
    "chezmoi"    = "$HOME/.local/share/chezmoi"
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

# starship configuration
$ENV:STARSHIP_CONFIG = "$HOME\.starship\starship.toml"
Invoke-Expression (&starship init powershell)
$env:SHELL = "pwsh"

# Set Alias
Set-Alias g goto
Set-Alias pbcopy Set-Clipboard
Set-Alias -Name su -Value admin
