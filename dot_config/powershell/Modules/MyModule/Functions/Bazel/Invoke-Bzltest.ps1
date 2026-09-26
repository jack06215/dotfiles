function Invoke-Bzltest {
    <#
        .SYNOPSIS
        Pick one or more testable targets with fzf, then `bazel test` them.

        .DESCRIPTION
        The PowerShell counterpart of the bzltest alias, which is
        bazel_find_testable_target in dot_config/zsh/src/bazel.zsh. Multi-select
        is on: TAB marks a target, Ctrl-A marks them all.

        Anything after the function name is passed to bazel verbatim; see
        Invoke-Bzlrun about PowerShell consuming the first `--`.

        .EXAMPLE
        Invoke-Bzltest

        .EXAMPLE
        Invoke-Bzltest --test_output=all
    #>
    [CmdletBinding()]
    param(
        [switch]$Print,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $targets = Select-BazelTarget `
        -Query 'kind("(test|test_suite) rule", ...)' `
        -Prompt 'Select testable target(s) > ' `
        -Multi
    if (-not $targets) {
        return
    }

    Invoke-BazelCommand -Command test -Target $targets -Arguments $Arguments -Print:$Print
}
