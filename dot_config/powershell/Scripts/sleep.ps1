$LogDir  = "C:\ProgramData\sleepwatcher\logs"
$LogFile = Join-Path $LogDir "events.log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

Add-Content $LogFile "$(Get-Date -Format o) SLEEP"
