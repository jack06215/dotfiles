function tail {
    <#
        .SYNOPSIS
        Show the last lines of a file, and optionally follow it.

        .DESCRIPTION
        Get-Content -Tail, and -Wait for -f, under the name and argument order
        of Unix tail.

        .PARAMETER Path
        The file to read.

        .PARAMETER n
        How many lines. Default 10.

        .PARAMETER f
        Keep printing lines as they are added, like tail -f. Ctrl-C stops.

        .EXAMPLE
        tail .\app.log 50

        .EXAMPLE
        tail .\app.log -f
    #>
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}
