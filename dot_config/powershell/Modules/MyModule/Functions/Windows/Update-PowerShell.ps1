function Update-PowerShell {
    <#
        .SYNOPSIS
        Update PowerShell 7 with winget when a newer release is out.

        .DESCRIPTION
        Compares this session's version with the latest release of
        PowerShell/PowerShell on GitHub. If this one is older, runs
        `winget upgrade Microsoft.PowerShell` through Windows PowerShell and
        waits for it; restart the shell afterwards to use the new version.

        .EXAMPLE
        Update-PowerShell
    #>
    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
        $updateNeeded = $false
        # Compared as versions, not strings: as text, 7.10.0 sorts before 7.6.6
        $currentVersion = $PSVersionTable.PSVersion
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = [semver]$latestReleaseInfo.tag_name.Trim('v')
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
