function which($name) {
    <#
        .SYNOPSIS
        Show what a command name runs.

        .DESCRIPTION
        Prints Get-Command's Definition: the path of a program, the target of
        an alias, the body of a function, or the syntax of a cmdlet.

        .PARAMETER name
        The command name to look up.

        .EXAMPLE
        which git

        .EXAMPLE
        which fman
    #>
    Get-Command $name | Select-Object -ExpandProperty Definition
}
