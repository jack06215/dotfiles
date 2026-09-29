function Invoke-BazelCommand {
    <#
        .SYNOPSIS
        Echo an assembled bazel command line, then run it.

        .DESCRIPTION
        What Invoke-Bzlrun, Invoke-Bzltest and Invoke-Bzlbuild hand their
        selection to.

        The zsh helpers end with `print -z`, which leaves the assembled command
        on the next prompt to be edited before it runs. PowerShell has no
        equivalent that works from inside a function - PSReadLine's AddToHistory
        throws when no line is being edited - so the line is printed and run
        instead, and -Print returns it as a string for a caller that wants to
        edit, pipe or copy it rather than run it.

        .PARAMETER Command
        The bazel command: build, run or test.

        .PARAMETER Target
        One or more target labels, such as //:export_powertoys_settings.

        .PARAMETER Arguments
        Anything else for bazel, placed after the targets.

        .PARAMETER Print
        Return the command line instead of running it.

        .EXAMPLE
        Invoke-BazelCommand -Command run -Target '//:export_powertoys_settings'

        .EXAMPLE
        Invoke-BazelCommand -Command build -Target '//...' -Print | Set-Clipboard
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('build', 'run', 'test')]
        [string]$Command,

        [Parameter(Mandatory, Position = 1)]
        [string[]]$Target,

        [Parameter(Position = 2)]
        [string[]]$Arguments,

        [switch]$Print
    )

    $argv = @($Command) + $Target
    if ($Arguments) {
        $argv += $Arguments
    }
    $line = "bazel $($argv -join ' ')"

    if ($Print) {
        return $line
    }

    Write-Host $line -ForegroundColor DarkGray
    & bazel @argv
}
