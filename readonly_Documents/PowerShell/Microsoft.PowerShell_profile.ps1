# Help Function
function Show-Help {
    $helpText = @"
$($PSStyle.Foreground.Cyan)PowerShell Profile Help$($PSStyle.Reset)
$($PSStyle.Foreground.Yellow)=======================$($PSStyle.Reset)

$($PSStyle.Foreground.Green)Update-Profile$($PSStyle.Reset) - Checks for profile updates from a remote repository and updates if necessary.

$($PSStyle.Foreground.Green)Update-PowerShell$($PSStyle.Reset) - Checks for the latest PowerShell release and updates if a new version is available.

$($PSStyle.Foreground.Green)Edit-Profile$($PSStyle.Reset) - Opens the current user's profile for editing using the configured editor.

$($PSStyle.Foreground.Green)touch$($PSStyle.Reset) <file> - Creates a new empty file.

$($PSStyle.Foreground.Green)ff$($PSStyle.Reset) <name> - Finds files recursively with the specified name.

$($PSStyle.Foreground.Green)Get-PubIP$($PSStyle.Reset) - Retrieves the public IP address of the machine.

$($PSStyle.Foreground.Green)uptime$($PSStyle.Reset) - Displays the system uptime.

$($PSStyle.Foreground.Green)unzip$($PSStyle.Reset) <file> - Extracts a zip file to the current directory.

$($PSStyle.Foreground.Green)grep$($PSStyle.Reset) <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.

$($PSStyle.Foreground.Green)df$($PSStyle.Reset) - Displays information about volumes.

$($PSStyle.Foreground.Green)sed$($PSStyle.Reset) <file> <find> <replace> - Replaces text in a file.

$($PSStyle.Foreground.Green)which$($PSStyle.Reset) <name> - Shows the path of the command.

$($PSStyle.Foreground.Green)export$($PSStyle.Reset) <name> <value> - Sets an environment variable.

$($PSStyle.Foreground.Green)pkill$($PSStyle.Reset) <name> - Kills processes by name.

$($PSStyle.Foreground.Green)pgrep$($PSStyle.Reset) <name> - Lists processes by name.

$($PSStyle.Foreground.Green)head$($PSStyle.Reset) <path> [n] - Displays the first n lines of a file (default 10).

$($PSStyle.Foreground.Green)tail$($PSStyle.Reset) <path> [n] - Displays the last n lines of a file (default 10).

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

function Get-URLFileToTemp {
    param (
        [string]$Url,
        [string]$DestinationPath
    )

    try {
        # Create HTTP client
        $httpClient = [System.Net.Http.HttpClient]::new()
        $response = $httpClient.SendAsync(
            [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $Url),
            [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead
        ).Result

        if (-not $response.IsSuccessStatusCode) {
            throw "HTTP Error $($response.StatusCode): $($response.ReasonPhrase)"
        }

        $totalBytes = $response.Content.Headers.ContentLength
        $inputStream = $response.Content.ReadAsStream()
        $outputStream = [System.IO.File]::OpenWrite($DestinationPath)

        $buffer = New-Object byte[] 8192
        $bytesRead = 0
        $totalRead = 0
        $percentComplete = 0

        do {
            $bytesRead = $inputStream.Read($buffer, 0, $buffer.Length)
            $outputStream.Write($buffer, 0, $bytesRead)
            $totalRead += $bytesRead

            if ($totalBytes -gt 0) {
                $percentComplete = [int](($totalRead / $totalBytes) * 100)
                Write-Progress -Activity "Downloading File" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
            }
        } while ($bytesRead -gt 0)

        $inputStream.Dispose()
        $outputStream.Dispose()
        $httpClient.Dispose()

        Write-Host "✅ Download complete: $DestinationPath"
    }
    catch {
        Write-Error "❌ Failed to download file from $Url"
        Write-Error $_
    }
}



function Install-WinGW {
    param (
        [string]$GccVersion = "15.1.0",
        [string]$MinGWVersion = "13.0.0",
        [string]$Revision = "r2"
    )
    try {
        if (-not (Test-CommandExists gcc)) {
            Write-Host "Installing WinGW GCC ${GccVersion}..."
            $GccZipUrl = "https://github.com/brechtsanders/winlibs_mingw/releases/download/${GccVersion}posix-${MinGWVersion}-ucrt-${Revision}/winlibs-x86_64-posix-seh-gcc-${GccVersion}-mingw-w64ucrt-${MinGWVersion}-${Revision}.zip"
            $zipFilePath = "$env:TEMP/mingw-${MinGWVersion}.zip"
            $extractPath = "$env:TEMP/mingw"    

            Write-Host "Downloading WinGW GCC ${GccVersion}..."            
            Get-URLFileToTemp -Url $GccZipUrl -DestinationPath $zipFilePath

            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = "C:/tools"
            if (-not (Test-Path $destination)) {
                Write-Host "Creating directory $destination"
                New-Item -ItemType Directory -Path $destination -Force | Out-Null
            }
            Get-ChildItem -Path $extractPath -Recurse -File | ForEach-Object {
                $relativePath = $_.FullName.Substring($extractPath.Length).TrimStart('\')
                $targetPath = Join-Path -Path $destination -ChildPath $relativePath
                $targetDir = Split-Path -Path $targetPath -Parent
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                Write-Host "Copying file $($_.FullName) to $targetPath"
                Copy-Item -Path $_.FullName -Destination $targetPath -Force
            }

            Write-Host "Removing Temporary Files..."
            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
            Write-Host "WinGW GCC ${GccVersion} installed to $destination"
            Write-Warning "Please add C:\tools\mingw64\bin to your PATH environment variable to use the compiler."
        }
        else {
            Write-Host "C++ Compiler Already Installed."
        }

    }
    catch {
        Write-Error "Failed to download or install WinGW-${WinGWVersion}. Error: $_"
    }
}

function Install-NerdFonts {
    param (
        [string]$FontName = "PlemolJP_NF",
        [string]$FontDisplayName = "PlemolJP Console NF Medium",
        [string]$Version = "2.0.4"
    )

    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -notcontains "${FontDisplayName}") {
            Write-Host "Installing ${FontDisplayName}"
            $fontZipUrl = "https://github.com/yuru7/PlemolJP/releases/download/v${Version}/${FontName}_v${Version}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
        }
        else {
            return
        }
    }
    catch {
        Write-Error "Failed to download or install ${FontDisplayName} font. Error: $_"
    }
}

function Install-Chocolatey {
    if (Test-CommandExists choco) {
        return
    }
    try {
        Write-Host "Chocolatey already installed."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    catch {
        Write-Error "Failed to install Chocolatey. Error: $_"
    }
}

function Open-InstallationMenu {
    Clear-Host
    $currentPath = Split-Path -Parent $PROFILE.CurrentUserAllHosts
    Write-Host "Installation Menu"
    Write-Host "This installer menu helps you install all essential packages."
    Write-Host ""

    function Show-Menu {
        Write-Host "..............................................."
        Write-Host "Select an option to proceed:"
        Write-Host "..............................................."
        Write-Host ""
        Write-Host "1 - Install Default apps"
        Write-Host "2 - Install Developer apps"
        Write-Host "3 - Install Chocolatey"
        Write-Host "4 - Upgrade all apps via Chocolatey"
        Write-Host "5 - Install WinGW GCC"
        Write-Host "q - EXIT"
        Write-Host ""
    }

    function Disable-ChecksumFlag {
        choco feature enable -n=allowEmptyChecksums
        choco feature enable -n=allowEmptyChecksumsSecure
    }

    while ($true) {
        Show-Menu
        $choice = Read-Host "Type 1, 2, 3, 4 or 5 then press ENTER"

        switch ($choice) {
            '1' {
                Disable-ChecksumFlag
                choco feature enable -n allowGlobalConfirmation
                choco install "$currentPath\defaultapps.config" --ignore-checksums -y
            }
            '2' {
                Disable-ChecksumFlag
                choco feature enable -n allowGlobalConfirmation
                choco install "$currentPath\defaultapps.config" --ignore-checksums -y
                choco install "$currentPath\devapps.config" --ignore-checksums -y
            }
            '3' {
                Write-Host "Installing Chocolatey..."
                Install-Chocolatey
                Disable-ChecksumFlag
                choco feature enable -n allowGlobalConfirmation
                choco upgrade chocolatey --ignore-checksums -y
                Write-Host "..............................................."
                Write-Host "A RESTART OF THE SCRIPT MAY BE NECESSARY!!"
                Write-Host "..............................................."
            }
            '4' {
                choco upgrade all
            }
            '5' {
                Install-WinGW -GccVersion "15.1.0" -MinGWVersion "13.0.0" -Revision "r2"
            }   
            'q' {
                Write-Host "Exiting..."
                return
            }
            default {
                Write-Host "Invalid selection. Please enter 1, 2, 3, 4, or 5."
            }
        }
    }
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
function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
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

# Install Essential Packages
function Install-Packages {
    # Chocolatey
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }
    else {
        Install-Chocolatey
    }
    # Terminal Icons
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
    }
    Import-Module -Name Terminal-Icons
    # Burnt Toast
    if (-not (Get-Module -ListAvailable -Name BurntToast)) {
        Install-Module -Name BurntToast -Scope CurrentUser -Force -SkipPublisherCheck
    }
    # Wifi Tools
    if  (-not (Get-Module -ListAvailable -Name WifiTools)) {
        Install-Module -Name WifiTools -Scope CurrentUser -Force -SkipPublisherCheck
    }
    if (-not (Get-Module -ListAvailable -Name PSFzf)) {
        Install-Module -Name PSFzf -Scope CurrentUser -Force -SkipPublisherCheck
    }
    Import-Module -Name PSFzf
    Import-Module -Name MyModule
    # Nert Font
    Install-NerdFonts -FontName "PlemolJP_NF" -FontDisplayName "PlemolJP Console NF Medium" -Version "2.0.4"
}


#### Startup Script ####
# Improved prediction settings
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -MaximumHistoryCount 10000
Write-Host "$($PSStyle.Foreground.Yellow)Use 'Show-Help' to display help$($PSStyle.Reset)"
Install-Packages
