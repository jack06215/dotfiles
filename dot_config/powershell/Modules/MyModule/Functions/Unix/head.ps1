function head {
    <#
        .SYNOPSIS
        Show the first lines of a file.

        .DESCRIPTION
        Get-Content -Head, under the name and argument order of Unix head.

        .PARAMETER Path
        The file to read.

        .PARAMETER n
        How many lines. Default 10.

        .EXAMPLE
        head .\app.log

        .EXAMPLE
        head .\app.log 50
    #>
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}
