function pkill($name) {
    <#
        .SYNOPSIS
        Stop every process with a given name.

        .DESCRIPTION
        The name is matched as Get-Process -Name matches it: without the .exe,
        ignoring case, wildcards allowed. Nothing matching is not an error.

        .PARAMETER name
        The process name.

        .EXAMPLE
        pkill notepad
    #>
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}
