function Invoke-FuzzyHelp {
    <#
        .SYNOPSIS
        Pick a command with fzf, then read its full help.

        .DESCRIPTION
        The PowerShell counterpart of fman in dot_config/zsh/src/functions.zsh.
        That one offers every executable on PATH and opens its man page, but
        Windows has no man pages. This offers what Get-Help can document
        instead - cmdlets and functions, from every module on
        $env:PSModulePath rather than only the loaded ones - and shows it
        through `help`, which pages the way man does.

        Native executables are left out: Get-Help knows nothing about them
        beyond their path. So are aliases. Get-Help follows one to a cmdlet,
        but given one that points at a native program or at nothing, it
        falls back to a full-text search and lists hundreds of loose matches.

        .EXAMPLE
        Invoke-FuzzyHelp
    #>
    [CmdletBinding()]
    param()

    # A: to Z: are the functions that switch drive; Get-Help takes each for a
    # path and fails. Several modules can export the same name, and Get-Help
    # resolves a bare name the way the shell does, so one row per name is
    # enough.
    $name = Get-Command -CommandType Cmdlet, Function |
        Where-Object Name -NotMatch '^[A-Z]:$' |
        Select-Object -ExpandProperty Name |
        Sort-Object -Unique |
        & fzf --prompt='help> '

    # fzf exits 130 and prints nothing when cancelled.
    if (-not $name) {
        return
    }

    help -Name $name -Full
}
