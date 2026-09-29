function Get-ConsoleColor
{
    <#
        .SYNOPSIS
        List the 16 console colors.

        .DESCRIPTION
        One object per [ConsoleColor] value - the names Write-Host accepts for
        -ForegroundColor and -BackgroundColor.

        .EXAMPLE
        Get-ConsoleColor

        .EXAMPLE
        Get-ConsoleColor | ForEach-Object { Write-Host $_.ConsoleColor -ForegroundColor $_.ConsoleColor }
    #>
    [CmdletBinding()]
    param(
        
    )

    Begin{

    }

    Process{
        $Colors = [Enum]::GetValues([ConsoleColor])

        foreach($Color in $Colors)
        {
            [pscustomobject] @{
                ConsoleColor = $Color
            }
        }
    }

    End{

    }
}