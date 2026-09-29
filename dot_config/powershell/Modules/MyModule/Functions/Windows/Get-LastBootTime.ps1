function Get-LastBootTime
{
    <#
        .SYNOPSIS
        Show when this or a remote computer last booted.

        .DESCRIPTION
        Reads LastBootUpTime from Win32_OperatingSystem. With Fast Startup on,
        a shutdown is a partial hibernation rather than a boot, so only a
        restart moves this time.

        Remote computers are read through PowerShell remoting, so they must
        answer ping and have WinRM enabled; one that fails is reported as an
        error and skipped.

        .PARAMETER ComputerName
        One or more computers to query. Defaults to this one.

        .PARAMETER Credential
        Credentials for the remote computers.

        .EXAMPLE
        Get-LastBootTime

        .EXAMPLE
        Get-LastBootTime -ComputerName server01, server02
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            HelpMessage='ComputerName or IPv4-Address of the remote computer')]
        [String[]]$ComputerName=$env:COMPUTERNAME,

        [Parameter(
			Position=1,
			HelpMessage='Credentials to authenticate agains a remote computer')]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.CredentialAttribute()]
		$Credential
    )

    Begin{
        $LocalAddress = @("127.0.0.1","localhost",".","$($env:COMPUTERNAME)")

		[System.Management.Automation.ScriptBlock]$ScriptBlock = {
             $LastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property LastBootUpTime).LastBootUpTime
             
             return [DateTime]$LastBootTime 
        }
    }

    Process{
        foreach($ComputerName2 in $ComputerName)
        {
            if($LocalAddress -contains $ComputerName2)
            {			
                $LastBootTime = Invoke-Command -ScriptBlock $ScriptBlock
            }
            else
            {
                if(Test-Connection -ComputerName $ComputerName2 -Count 2 -Quiet)
                {
                    try {
                        if($PSBoundParameters.ContainsKey('Credential'))
                        {
                            $LastBootTime = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName2 -Credential $Credential -ErrorAction Stop
                        }
                        else
                        {					    
                            $LastBootTime = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName2 -ErrorAction Stop
                        }
                    }
                    catch {
                        Write-Error -Message "$($_.Exception.Message)" -Category InvalidData

                        continue
                    }
                }
                else 
                {				
                    Write-Error -Message """$ComputerName2"" is not reachable via ICMP!" -Category ConnectionError

                    continue
                }
            }

            [pscustomobject] @{
                ComputerName = $ComputerName2
                LastBootTime = $LastBootTime
            }
        }
    }

    End{

    }
}