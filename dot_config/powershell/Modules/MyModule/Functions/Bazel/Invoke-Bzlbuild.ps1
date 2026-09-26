function Invoke-Bzlbuild {
    <#
        .SYNOPSIS
        Pick any target with fzf, then `bazel build` it.

        .DESCRIPTION
        The PowerShell counterpart of the bzlbuild alias, which is
        bazel_find_any_target in dot_config/zsh/src/bazel.zsh. The query is
        unfiltered, so every target in the workspace is offered.

        Anything after the function name is passed to bazel verbatim; see
        Invoke-Bzlrun about PowerShell consuming the first `--`.

        .EXAMPLE
        Invoke-Bzlbuild

        .EXAMPLE
        Invoke-Bzlbuild -c opt
    #>
    [CmdletBinding()]
    param(
        [switch]$Print,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $target = Select-BazelTarget -Query '...' -Prompt 'Select a target > '
    if (-not $target) {
        return
    }

    Invoke-BazelCommand -Command build -Target $target -Arguments $Arguments -Print:$Print
}
