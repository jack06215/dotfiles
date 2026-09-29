function Split-IPv4Subnet
{
    <#
        .SYNOPSIS
        Split a subnet into smaller subnets of equal size.

        .DESCRIPTION
        Returns one Get-IPv4Subnet result per smaller subnet, in order. The new
        prefix must be longer than the current one: a /24 splits into /25s or
        /26s, not /24s or /23s.

        .PARAMETER IPv4Address
        Any address in the subnet to split.

        .PARAMETER CIDR
        Prefix length of the subnet to split, without the slash.

        .PARAMETER NewCIDR
        Prefix length of the subnets to split it into, without the slash.

        .PARAMETER Mask
        Subnet mask of the subnet to split, such as 255.255.255.0.

        .PARAMETER NewMask
        Subnet mask of the subnets to split it into, such as 255.255.255.128.

        .EXAMPLE
        Split-IPv4Subnet -IPv4Address 192.168.0.0 -CIDR 22 -NewCIDR 24
        # 192.168.0.0/24 through 192.168.3.0/24

        .EXAMPLE
        Split-IPv4Subnet 10.0.0.0 -Mask 255.255.255.0 -NewMask 255.255.255.192
    #>
    [CmdletBinding(DefaultParameterSetName='CIDR')]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address which is in the subnet')]
        [IPAddress]$IPv4Address,

        [Parameter(
            ParameterSetName='CIDR',
            Position=1,
            Mandatory=$true,
            HelpMessage='CIDR like /24 without "/"')]
        [ValidateRange(0,31)]
        [Int32]$CIDR,

        [Parameter(
            ParameterSetName='CIDR',
            Position=2,
            Mandatory=$true,
            HelpMessage='New CIDR like /28 without "/"')]
        [ValidateRange(0,31)]
        [Int32]$NewCIDR,

        [Parameter(
            ParameterSetName='Mask',
            Position=1,
            Mandatory=$true,
            Helpmessage='Subnetmask like 255.255.255.0')]
        [ValidateScript({
            if($_ -match "^(254|252|248|240|224|192|128).0.0.0$|^255.(254|252|248|240|224|192|128|0).0.0$|^255.255.(254|252|248|240|224|192|128|0).0$|^255.255.255.(254|252|248|240|224|192|128|0)$")
            {
                return $true
            }
            else {
                throw "Enter a valid subnetmask (like 255.255.255.0)!"
            }
        })]
        [String]$Mask,

        [Parameter(
            ParameterSetName='Mask',
            Position=2,
            Mandatory=$true,
            HelpMessage='Subnetmask like 255.255.255.128')]
        [ValidateScript({
            if($_ -match "^(254|252|248|240|224|192|128).0.0.0$|^255.(254|252|248|240|224|192|128|0).0.0$|^255.255.(254|252|248|240|224|192|128|0).0$|^255.255.255.(254|252|248|240|224|192|128|0)$")
            {
                return $true
            }
            else 
            {
                throw "Enter a valid subnetmask (like 255.255.255.0)!"
            }
        })]
        [String]$NewMask  
    )

    Begin{
      
    }

    Process{
        if($PSCmdlet.ParameterSetName -eq 'Mask')
        {
            $CIDR = (Convert-Subnetmask -Mask $Mask).CIDR 
            $NewCIDR = (Convert-Subnetmask -Mask $NewMask).CIDR
        }
        
        if($CIDR -ge $NewCIDR)
        {
            throw "Subnet (/$CIDR) can't be greater or equal than new subnet (/$NewCIDR)"
        }

        # Calculate the current Subnet
        $Subnet = Get-IPv4Subnet -IPv4Address $IPv4Address -CIDR $CIDR
        
        # Get new  HostBits based on SubnetBits (CIDR) // Hostbits (32 - /24 = 8 -> 00000000000000000000000011111111)
        $NewHostBits = ('1' * (32 - $NewCIDR)).PadLeft(32, "0")

        # Convert Bits to Int64, add +1 to get all available IPs
        $NewAvailableIPs = ([Convert]::ToInt64($NewHostBits,2) + 1)

        # Convert the NetworkID to Int64
        $NetworkID_Int64 = (Convert-IPv4Address -IPv4Address $Subnet.NetworkID).Int64
        
        # Build new subnets, and return them
        for($i = 0; $i -lt $Subnet.IPs;$i += $NewAvailableIPs)
        {
            Get-IPv4Subnet -IPv4Address (Convert-IPv4Address -Int64 ($NetworkID_Int64 + $i)).IPv4Address -CIDR $NewCIDR
        }
    }

    End{

    }
}