function Test-CommandExists {
    <#
        .SYNOPSIS
        Test whether a name resolves to a command.

        .DESCRIPTION
        Returns $true if Get-Command finds a cmdlet, function, alias or
        program by that name, and $false otherwise.

        .PARAMETER command
        The command name to look for.

        .EXAMPLE
        Test-CommandExists rg

        .EXAMPLE
        if (Test-CommandExists starship) { Invoke-Expression (&starship init powershell) }
    #>
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}
