function Get-PubIP {
    <#
        .SYNOPSIS
        Print this machine's public IP address.

        .DESCRIPTION
        Asks ifconfig.me, so the answer is the address the internet sees -
        behind NAT, the router's - rather than any local one.

        .EXAMPLE
        Get-PubIP
    #>
    (Invoke-WebRequest http://ifconfig.me/ip).Content
}
