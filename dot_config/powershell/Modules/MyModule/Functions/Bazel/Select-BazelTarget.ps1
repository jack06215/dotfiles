function Select-BazelTarget {
    <#
        .SYNOPSIS
        Pick one or more bazel targets matching a query, with fzf.

        .DESCRIPTION
        The picker Invoke-Bzlrun, Invoke-Bzltest and Invoke-Bzlbuild are built
        on, and the PowerShell counterpart of _bazel_buffer_and_pick in
        dot_config/zsh/src/bazel.zsh.

        The query is run to completion before fzf starts, so bazel's progress
        and warnings land above the prompt rather than corrupting the selection
        list - the same reason the zsh version buffers into a temp file first.

        Returns the selected label(s), or nothing if the query matched nothing
        or the selection was cancelled.

        .EXAMPLE
        Select-BazelTarget -Query 'kind(".*_binary", ...)'

        .EXAMPLE
        Select-BazelTarget -Query '...' -Prompt 'Select a target > ' -Multi
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Query,

        [Parameter(Position = 1)]
        [string]$Prompt = 'Select a target > ',

        [switch]$Multi
    )

    foreach ($tool in 'bazel', 'fzf') {
        if (-not (Get-Command $tool -ErrorAction Ignore)) {
            Write-Error "bazel: $tool is not on PATH"
            return
        }
    }

    # --keep_going lets a tree with one broken package still answer, and exits
    # non-zero while doing it. The run is judged by whether labels came back,
    # not by the exit status, so a caller's 'Stop' preference must not turn that
    # exit code into a terminating error first.
    $ErrorActionPreference = 'Continue'

    Write-Host 'Querying targets...' -ForegroundColor DarkGray
    $labels = & bazel query $Query --output=label --noshow_progress --keep_going --color=yes
    if (-not $labels) {
        Write-Error 'bazel: no targets found'
        return
    }

    # fzf runs preview commands through cmd.exe on Windows, which cannot parse
    # this pipeline, so it is pointed at pwsh instead. {} is the highlighted
    # label; no legal bazel label contains a space or a quote, so it needs no
    # quoting of its own.
    $preview = 'bazel query "kind(.*, {})" --output=build 2>$null'
    if (Get-Command bat -ErrorAction Ignore) {
        $preview += ' | bat --language=python --color=always --style=plain --paging=never'
    }

    $fzfArgs = @(
        "--prompt=$Prompt"
        '--height=40%'
        '--layout=reverse'
        '--with-shell=pwsh -NoProfile -NonInteractive -Command'
        "--preview=$preview"
        '--preview-window=right:60%:wrap'
    )
    if ($Multi) {
        $fzfArgs += @('--multi', '--bind=ctrl-a:select-all')
    }

    # fzf exits 130 and prints nothing when cancelled, which every caller reads
    # as "stop here".
    $labels | & fzf @fzfArgs
}
