function Clear-ARPCache
{
    <#
        .SYNOPSIS
        Flush the local ARP cache.

        .DESCRIPTION
        Runs `netsh interface ip delete arpcache`, which needs administrator
        rights. netsh is always started elevated, so from a non-elevated
        session this warns and then raises a UAC prompt.

        .EXAMPLE
        Clear-ARPCache
    #>
    [CmdletBinding()]
    param(

    )

    Begin{
        if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
        {
            Write-Warning -Message "Administrator rights are required to clear the ARP cache! Attempts to start the process with elevated privileges..."      
        }
    }

    Process{
        try{
            Start-Process -FilePath "$env:SystemRoot\System32\netsh.exe" -ArgumentList "interface ip delete arpcache" -Verb "RunAs" -WindowStyle Hidden -Wait
        }
        catch{
            throw
        }
    }

    End{

    }
}