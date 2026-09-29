function grep-table {
    <#
        .SYNOPSIS
        Keep the piped-in objects whose displayed text matches, shown as a table.

        .DESCRIPTION
        Each object is rendered the way it would print (Out-String) and kept
        if that text matches -Pattern, a regular expression that ignores
        case. The objects kept are shown with Format-Table, so this belongs at
        the end of a pipeline.

        .PARAMETER Pattern
        The regular expression to match against each object's displayed text.

        .PARAMETER InputObject
        The objects to filter, from the pipeline.

        .EXAMPLE
        Get-Process | grep-table pwsh

        .EXAMPLE
        Get-Service | grep-table '^Running.*Windows'
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin {
        $collected = @()
    }

    process {
        try {
            $text = ($_ | Out-String).Trim()
            if ($text -match $Pattern) {
                $collected += , $_  # Wrap in array to prevent hashtable merge
            }
        }
        catch {
            Write-Warning "Skipping unprocessable object: $_"
        }
    }

    end {
        if ($collected.Count -gt 0) {
            $collected | Format-Table -AutoSize
        }
    }
}
