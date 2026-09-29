function Get-RandomPIN
{
	<#
		.SYNOPSIS
		Generate one or more random numeric PINs.

		.DESCRIPTION
		Builds each PIN from random numbers between -Minimum and -Maximum.

		A single PIN comes back as an object with a PIN property; with a
		-Count above 1, each also carries its number in Count.
		-CopyToClipboard is for a single PIN, so it cannot be combined with
		-Count.

		.PARAMETER Length
		Digits per PIN. Default 4.

		.PARAMETER Count
		Number of PINs to generate. Default 1.

		.PARAMETER CopyToClipboard
		Also copy the PIN to the clipboard.

		.PARAMETER Minimum
		Smallest number to draw. Default 0.

		.PARAMETER Maximum
		Largest number to draw. Default 9.

		.EXAMPLE
		Get-RandomPIN

		.EXAMPLE
		Get-RandomPIN -Length 6 -Count 3
	#>
	[CmdletBinding(DefaultParameterSetName='NoClipboard')]
	param(
		[Parameter(
			Position=0,
			HelpMessage='Length of the PIN (Default=4)')]
		[ValidateScript({
			if($_ -eq 0)
			{
				throw "Length of the PIN can not be 0!"
			}
			else 
			{
				return $true	
			}
		})]
		[Int32]$Length=4,

		[Parameter(
			ParameterSetName='NoClipboard',
			Position=1,
			HelpMessage='Number of PINs to be generated (Default=1)')]
		[ValidateScript({
			if($_ -eq 0)
			{
				throw "Number of PINs to be generated can not be 0"
			}
			else 
			{
				return $true
			}
		})]
		[Int32]$Count=1,

		[Parameter(
			ParameterSetName='Clipboard',
			Position=1,
			HelpMessage='Copy PIN to clipboard')]
		[switch]$CopyToClipboard,

		[Parameter(
			Position=2,
			HelpMessage='Smallest possible number (Default=0)')]
		[Int32]$Minimum=0,
		
		[Parameter(
			Position=3,
			HelpMessage='Greatest possible number (Default=9)')]
		[Int32]$Maximum=9
	)

	Begin{
		# Checked here rather than in a ValidateScript on -Maximum: $Minimum is
		# not reliably bound yet while -Maximum is being validated.
		if($Maximum -lt $Minimum)
		{
			throw "Minimum can not be greater than maximum!"
		}
	}

	Process{
		for($i = 1; $i -ne $Count + 1; $i++)
		{ 
			$PIN = [String]::Empty
				
			while($PIN.Length -lt $Length)
			{
				# Create random numbers. Get-Random never returns its -Maximum,
				# so it is given one past $Maximum to make $Maximum reachable.
				$PIN += (Get-Random -Minimum $Minimum -Maximum ($Maximum + 1)).ToString()
			}
			
			# Return result
			if($Count -eq 1)
			{
				# Set to clipboard
				if($CopyToClipboard)
				{
					Set-Clipboard -Value $PIN
				}

				[pscustomobject] @{
					PIN = $PIN
				}
			}
			else 
			{			
				[pscustomobject] @{
					Count = $i
					PIN = $PIN
				}	
			}
		}
	}

	End{
		
	}
}