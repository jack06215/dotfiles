function Test-IsFileBinary
{
	<#
		.SYNOPSIS
		Guess whether a file is binary or text from its first 1024 bytes.

		.DESCRIPTION
		A file that starts with a UTF-8, UTF-16 or UTF-32 byte-order mark is
		text. Otherwise it is binary if those bytes contain a NUL - the same
		heuristic GNU grep and diff use - and text if they do not.

		Returns $true for binary, $false for text. Find-StringInFile uses it
		to flag matches inside binaries.

		.PARAMETER FilePath
		The file to check. Must exist and must not be a folder.

		.EXAMPLE
		Test-IsFileBinary -FilePath C:\Windows\notepad.exe

		.EXAMPLE
		Get-ChildItem -File | Where-Object { -not (Test-IsFileBinary $_.FullName) }
	#>
	[CmdletBinding()]
	[OutputType('System.Boolean')]
	Param(
		[Parameter(
			Position=0,
			Mandatory=$true,
			HelpMessage="Path to file which should be checked")]
		[ValidateScript({
			if(Test-Path -Path $_ -PathType Leaf)
			{
				return $true
			}
			else 
			{
				throw "Enter a valid file path!"	
			}
		})]
		[String]$FilePath
	)

	Begin{
		
	}

	Process{
		# Encoding variable
		$Encoding = [String]::Empty

        # Get the first 1024 bytes from the file
        $ByteCount = 1024
        		
		$ByteArray = Get-Content -Path $FilePath -AsByteStream -TotalCount $ByteCount

        if($ByteArray.Count -ge $ByteCount)
        {
            Write-Verbose -Message "Could only read $($ByteArray.Count)/$ByteCount Bytes. File "
        }
      
        if(($ByteArray.Count -ge 4) -and (("{0:X}{1:X}{2:X}{3:X}" -f $ByteArray) -eq "FFFE0000"))
		{
			Write-Verbose -Message "UTF-32 detected!"
			$Encoding = "UTF-32"
		}
		elseif(($ByteArray.Count -ge 4) -and (("{0:X}{1:X}{2:X}{3:X}" -f $ByteArray) -eq "0000FEFF"))
		{
			Write-Verbose -Message "UTF-32 BE detected!"
			$Encoding = "UTF-32 BE"
		}
        elseif(($ByteArray.Count -ge 3) -and (("{0:X}{1:X}{2:X}" -f $ByteArray) -eq "EFBBBF"))
		{
			Write-Verbose -Message "UTF-8 detected!"
			$Encoding = "UTF-8"
		}
		elseif(($ByteArray.Count -ge 2) -and (("{0:X}{1:X}" -f $ByteArray) -eq "FFFE"))
		{
			Write-Verbose -Message "UTF-16 detected!"
			$Encoding = "UTF-16"
		}
		elseif(($ByteArray.Count -ge 2) -and (("{0:X}{1:X}" -f $ByteArray) -eq "FEFF"))
		{
            Write-Verbose "UTF-16 BE detected!"
			$Encoding = "UTF-16 BE"
		}

		if(-not([String]::IsNullOrEmpty($Encoding)))
		{
            Write-Verbose -Message "File is text encoded!"
			return $false
		}

		# So now we're done with Text encodings that commonly have '0's
		# in their byte steams.  ASCII may have the NUL or '0' code in
		# their streams but that's rare apparently.

		# Both GNU Grep and Diff use variations of this heuristic

		if($byteArray -contains 0 )
		{
			Write-Verbose -Message "File is a binary!"
			return $true
		}

        Write-Verbose -Message "File should be ASCII encoded!"
		return $false
	}

	End{
		
	}
}