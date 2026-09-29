function Get-InstalledSoftware
	{
	<#
		.SYNOPSIS
		List the software installed on this or a remote computer.

		.DESCRIPTION
		Reads the machine-wide Uninstall keys in the registry, for 64-bit and
		32-bit programs alike, and lists each entry that has a display name
		and an uninstall command: DisplayName, Publisher, UninstallString,
		InstallLocation and InstallDate. Programs installed for one user only
		(the HKCU Uninstall key) and Store apps are not included.

		A remote computer is read through PowerShell remoting, so it must
		answer ping and have WinRM enabled.

		.PARAMETER Search
		Keep only entries whose display name matches this wildcard pattern,
		such as '*Visual Studio*'.

		.PARAMETER ComputerName
		The computer to query. Defaults to this one.

		.PARAMETER Credential
		Credentials for a remote computer.

		.EXAMPLE
		Get-InstalledSoftware -Search '*Python*'

		.EXAMPLE
		Get-InstalledSoftware -ComputerName server01 -Credential (Get-Credential)
	#>
	[CmdletBinding()]
	param(
		[Parameter(
			Position=0,
			HelpMessage='Search for product name (You can use wildcards like "*ProductName*')]
		[String]$Search,

		[Parameter(
			Position=1,
			HelpMessage='ComputerName or IPv4-Address of the remote computer')]
		[String]$ComputerName = $env:COMPUTERNAME,

		[Parameter(
			Position=2,
			HelpMessage='Credentials to authenticate agains a remote computer')]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.CredentialAttribute()]
		$Credential
	)

	Begin{
		$LocalAddress = @("127.0.0.1","localhost",".","$($env:COMPUTERNAME)")

		[System.Management.Automation.ScriptBlock]$ScriptBlock = {
			# Location where all entrys for installed software should be stored
			return Get-ChildItem -Path  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Select-Object -Property DisplayName, Publisher, UninstallString, InstallLocation, InstallDate
		}
	}

	Process{
		if($LocalAddress -contains $ComputerName)
		{			
			$Strings = Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Search            
		}
		else
		{
			if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
			{
				try {
					if($PSBoundParameters.ContainsKey('Credential'))
					{
						$Strings = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName -ArgumentList $Search -Credential $Credential -ErrorAction Stop
					}
					else
					{					    
						$Strings = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName -ArgumentList $Search -ErrorAction Stop
					}
				}
				catch {
					throw 
				}
			}
			else 
			{				
				throw """$ComputerName"" is not reachable via ICMP!"
			}
		}

		foreach($String in $Strings)
		{
			# Check for each entry if data exists
			if((-not([String]::IsNullOrEmpty($String.DisplayName))) -and (-not([String]::IsNullOrEmpty($String.UninstallString))))
			{
				# Search (only if parameter is used)
				if((-not($PSBoundParameters.ContainsKey('Search'))) -or (($PSBoundParameters.ContainsKey('Search') -and ($String.DisplayName -like $Search))))
				{                   
					[pscustomobject] @{
						DisplayName = $String.DisplayName
						Publisher = $String.Publisher
						UninstallString = $String.UninstallString
						InstallLocation = $String.InstallLocation
						InstallDate = $String.InstallDate
					}
				}   
			}
		}
	}

	End{
		
	}
}