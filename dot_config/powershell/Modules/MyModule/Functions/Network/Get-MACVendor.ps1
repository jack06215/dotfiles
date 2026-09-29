function Get-MACVendor
{
    <#
        .SYNOPSIS
        Look up the manufacturer of one or more MAC addresses.

        .DESCRIPTION
        The first three bytes of a MAC address are the OUI, which the IEEE
        assigns to each manufacturer. They are looked up in the IEEE OUI list
        in Functions\Network\Resources - the same list Invoke-IPv4NetworkScan
        uses. The list is not tracked in the repo; Invoke-IPv4NetworkScan
        -UpdateList downloads it. Without it, this warns and every Vendor is
        empty.

        Returns MACAddress and Vendor for each address. Vendor is also empty
        for an OUI the list does not know, such as a randomized private
        address.

        .PARAMETER MACAddress
        One or more MAC addresses, as 00:11:22:33:44:55, 00-11-22-33-44-55 or
        001122334455. Also accepted from the pipeline, including the
        MACAddress property of Get-ARPCache's output.

        .EXAMPLE
        Get-MACVendor -MACAddress 00-15-5D-01-02-03

        .EXAMPLE
        Get-ARPCache | Get-MACVendor
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage='MAC-Address like 00:00:00:00:00:00')]
        [ValidateScript({
            if($_ -match "^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$|^[0-9A-Fa-f]{12}$")
            {
                return $true
            }
            else
            {
                throw "Enter a valid MAC-Address (like 00:00:00:00:00:00)!"
            }
        })]
        [String[]]$MACAddress
    )

    Begin{
        # Written by Invoke-IPv4NetworkScan -UpdateList
        $CSV_MACVendorList_Path = "$PSScriptRoot\Resources\IEEE_Standards_Registration_Authority.csv"

        # OUI -> vendor, so each address is one lookup rather than a walk
        # through the tens of thousands of rows in the list.
        $Vendors = @{}

        if(Test-Path -Path $CSV_MACVendorList_Path -PathType Leaf)
        {
            foreach($ListEntry in Import-Csv -Path $CSV_MACVendorList_Path)
            {
                $Vendors[$ListEntry.Assignment] = $ListEntry."Organization Name"
            }
        }
        else
        {
            Write-Warning -Message "No IEEE OUI list to look up vendors in. Use ""Invoke-IPv4NetworkScan -UpdateList"" to download the latest version from IEEE.org."
        }
    }

    Process{
        foreach($MAC in $MACAddress)
        {
            # The OUI is the first six hex digits, whatever the separators
            $OUI = $MAC.Replace(':','').Replace('-','').Substring(0,6).ToUpper()

            [pscustomobject] @{
                MACAddress = $MAC
                Vendor = [String]$Vendors[$OUI]
            }
        }
    }

    End{

    }
}
