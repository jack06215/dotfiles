function pgrep($name) {
    <#
        .SYNOPSIS
        List the processes with a given name.

        .DESCRIPTION
        Runs Get-Process -Name, so the name goes without the .exe, ignores
        case and may hold wildcards. Unlike pgrep, nothing matching is an
        error.

        .PARAMETER name
        The process name.

        .EXAMPLE
        pgrep 'code*'
    #>
    Get-Process $name
}
