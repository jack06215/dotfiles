function Get-RandomPassword
{
	<#
		.SYNOPSIS
		Generate one or more random passwords.

		.DESCRIPTION
		Draws from lower case letters, upper case letters, digits and the
		special characters $%&/()=?+*#[]{}-_@. Each -Disable switch drops one
		of those sets; leave at least one. The letters j, o, q, I, J, O and Q
		are never used.

		A single password comes back as an object with a Password property;
		with a -Count above 1, each also carries its number in Count.
		-CopyToClipboard is for a single password, so it cannot be combined
		with -Count.

		.PARAMETER Length
		Characters per password. Default 8.

		.PARAMETER Count
		Number of passwords to generate. Default 1.

		.PARAMETER CopyToClipboard
		Also copy the password to the clipboard.

		.PARAMETER DisableLowerCase
		Leave out lower case letters.

		.PARAMETER DisableUpperCase
		Leave out upper case letters.

		.PARAMETER DisableNumbers
		Leave out digits.

		.PARAMETER DisableSpecialChars
		Leave out special characters.

		.EXAMPLE
		Get-RandomPassword -Length 20 -CopyToClipboard

		.EXAMPLE
		Get-RandomPassword -Length 12 -Count 5 -DisableSpecialChars
	#>
	[CmdletBinding(DefaultParameterSetName='NoClipboard')]
	param(
		[Parameter(
			Position=0,
			HelpMessage='Length of the Password  (Default=8)')]
		[ValidateScript({
			if($_ -eq 0)
			{
				throw "Length of the password can not be 0!"
			}
			else 
			{
				return $true	
			}
		})]
		[Int32]$Length=8,

		[Parameter(
			ParameterSetName='NoClipboard',
			Position=1,
			HelpMessage='Number of Passwords to be generated (Default=1)')]
		[ValidateScript({
			if($_ -eq 0)
			{
				throw "Number of Passwords to be generated can not be 0"
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
			HelpMessage='Copy password to clipboard')]
		[switch]$CopyToClipboard,

		[Parameter(
			Position=2,
			HelpMessage='Use lower case characters (Default=$true')]
		[switch]$DisableLowerCase,

		[Parameter(
			Position=3,
			HelpMessage='Use upper case characters (Default=$true)')]
		[switch]$DisableUpperCase,
		
		[Parameter(
			Position=4,
			HelpMessage='Use upper case characters (Default=$true)')]
		[switch]$DisableNumbers,

		[Parameter(
			Position=5,
			HelpMessage='Use upper case characters (Default=$true)')]
		[ValidateScript({
			if($DisableLowerCase -and $DisableUpperCase -and $DisableNumbers -and $_)
			{
				throw "Select at least 1 character set (lower case, upper case, numbers or special chars) to create a password."
			}
			else 
			{
				return $true
			}
		})]
		[switch]$DisableSpecialChars
	)

	Begin{

	}

	Process{
		$Character_LowerCase = "abcdefghiklmnprstuvwxyz"
		$Character_UpperCase = "ABCDEFGHKLMNPRSTUVWXYZ"
		$Character_Numbers = "0123456789"
		$Character_SpecialChars = "$%&/()=?+*#[]{}-_@"

		$Characters = [String]::Empty
			
		# Built string with characters
		if($DisableLowerCase -eq $false)
		{
			$Characters += $Character_LowerCase
		}

		if($DisableUpperCase -eq $false)
		{
			$Characters += $Character_UpperCase
		}

		if($DisableNumbers -eq $false)
		{
			$Characters += $Character_Numbers
		}
		
		if($DisableSpecialChars -eq $false)
		{
			$Characters += $Character_SpecialChars
		}
		
		for($i = 1; $i -ne $Count + 1; $i++)
		{
			$Password = [String]::Empty
					
			# Create random password
			while($Password.Length -lt $Length)
			{
				# Create random numbers
				$RandomNumber = Get-Random -Maximum $Characters.Length
				$Password += $Characters[$RandomNumber]
			}
			
			# Return result
			if($Count -eq 1)
			{
				# Set to clipboard
				if($CopyToClipboard)
				{
					Set-Clipboard -Value $Password
				}

				[pscustomobject] @{
					Password = $Password
				}
			}
			else 
			{
				[pscustomobject] @{
					Count = $i
					Password = $Password
				}	
			}
		}
	}

	End{
		
	}
}