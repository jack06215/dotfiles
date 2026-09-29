function Convert-IPv4Address
{
    <#
        .SYNOPSIS
        Convert an IPv4 address between dotted-decimal and a 64-bit integer.

        .DESCRIPTION
        Either direction returns an object with both forms, IPv4Address and
        Int64. The integer form makes address arithmetic easy, which is how
        Get-IPv4Subnet, Split-IPv4Subnet and Invoke-IPv4NetworkScan step
        through a range.

        .PARAMETER IPv4Address
        A dotted-decimal address, such as 192.168.1.1.

        .PARAMETER Int64
        An address as an integer, such as 2886755428.

        .EXAMPLE
        Convert-IPv4Address -IPv4Address 192.168.1.1
        # IPv4Address 192.168.1.1, Int64 3232235777

        .EXAMPLE
        Convert-IPv4Address -Int64 2886755428
        # IPv4Address 172.16.100.100, Int64 2886755428
    #>
    [CmdletBinding(DefaultParameterSetName='IPv4Address')]
    param(
        [Parameter(
            ParameterSetName='IPv4Address',
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address as string like "192.168.1.1"')]
        [IPAddress]$IPv4Address,

        [Parameter(
                ParameterSetName='Int64',
                Position=0,
                Mandatory=$true,
                HelpMessage='IPv4-Address as Int64 like 2886755428')]
        [long]$Int64
    ) 

    Begin {

    }

    Process {
        switch($PSCmdlet.ParameterSetName)
        {
            # Convert IPv4-Address as string into Int64
            "IPv4Address" {
                $Octets = $IPv4Address.ToString().Split(".")
                $Int64 = [long]([long]$Octets[0]*16777216 + [long]$Octets[1]*65536 + [long]$Octets[2]*256 + [long]$Octets[3]) 
            }
    
            # Convert IPv4-Address as Int64 into string 
            "Int64" {            
                $IPv4Address = (([System.Math]::Truncate($Int64/16777216)).ToString() + "." + ([System.Math]::Truncate(($Int64%16777216)/65536)).ToString() + "." + ([System.Math]::Truncate(($Int64%65536)/256)).ToString() + "." + ([System.Math]::Truncate($Int64%256)).ToString())
            }      
        }

        [pscustomobject] @{    
            IPv4Address = $IPv4Address
            Int64 = $Int64
        }        	
    }

    End {

    }      
}