function Invoke-Bzlrun {
    <#
        .SYNOPSIS
        Pick a runnable target with fzf, then `bazel run` it.

        .DESCRIPTION
        The PowerShell counterpart of the bzlrun alias, which is
        bazel_find_runnable_target in dot_config/zsh/src/bazel.zsh.

        Anything after the function name is passed to bazel verbatim. Note that
        PowerShell consumes the first `--` on a command line, so a flag meant
        for the program being run - rather than for bazel - needs two: the first
        ends PowerShell's parameter parsing, the second is what bazel sees.

        .EXAMPLE
        Invoke-Bzlrun

        .EXAMPLE
        Invoke-Bzlrun -- -- --dry-run
        # runs: bazel run <target> -- --dry-run

        .EXAMPLE
        Invoke-Bzlrun -c opt
        # runs: bazel run <target> -c opt
    #>
    [CmdletBinding()]
    param(
        [switch]$Print,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $target = Select-BazelTarget `
        -Query 'kind(".*_binary", ...)' `
        -Prompt 'Select a runnable target > '
    if (-not $target) {
        return
    }

    Invoke-BazelCommand -Command run -Target $target -Arguments $Arguments -Print:$Print
}
