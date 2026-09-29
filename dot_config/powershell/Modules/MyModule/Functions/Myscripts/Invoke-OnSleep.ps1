function Invoke-OnSleep {
    <#
        .SYNOPSIS
        Append a SLEEP line to the sleepwatcher event log.

        .DESCRIPTION
        The Windows stand-in for the sleep hook sleepwatcher runs on macOS
        (dot_config/zsh/src/executable_sleep.zsh), and the same thing
        Scripts\sleep.ps1 does. It only records the event: an ISO 8601
        timestamp followed by SLEEP, appended to
        C:\ProgramData\sleepwatcher\logs\events.log. The folder is created
        on first use.

        .EXAMPLE
        Invoke-OnSleep
    #>
    $LogDir  = "C:\ProgramData\sleepwatcher\logs"
    $LogFile = Join-Path $LogDir "events.log"

    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    Add-Content $LogFile "$(Get-Date -Format o) SLEEP"
}
