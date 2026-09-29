function admin {
    <#
        .SYNOPSIS
        Open an elevated Windows Terminal, optionally running a command in it.

        .DESCRIPTION
        Starts wt as administrator, which raises a UAC prompt. Any arguments
        are joined into one command line that a new pwsh runs there, staying
        open afterwards. The profile aliases su to this.

        .EXAMPLE
        admin

        .EXAMPLE
        admin winget upgrade --all
    #>
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    }
    else {
        Start-Process wt -Verb runAs
    }
}
