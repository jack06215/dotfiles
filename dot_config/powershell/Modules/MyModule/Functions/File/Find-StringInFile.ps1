function Find-StringInFile
{
	<#
		.SYNOPSIS
		Search every file under a folder for a literal string.

		.DESCRIPTION
		Walks -Path recursively and reports each line that contains -Search.
		The string is matched literally, not as a regular expression, and
		ignoring case unless -CaseSensitive is given.

		Each match comes back as an object with the file's Filename and Path,
		the LineNumber, the Matches text, and IsBinary from Test-IsFileBinary,
		so hits inside binaries can be filtered out.

		.PARAMETER Search
		The string to find. Also accepted from the pipeline.

		.PARAMETER Path
		The folder to search, recursively. Defaults to the current location.

		.PARAMETER CaseSensitive
		Match case exactly.

		.EXAMPLE
		Find-StringInFile -Search 'TODO'

		.EXAMPLE
		Find-StringInFile 'ConnectionString' -Path C:\src -CaseSensitive |
			Where-Object { -not $_.IsBinary }
	#>
	[CmdletBinding()]
	param(
	[Parameter(
			Position=0,
			Mandatory=$true, ValueFromPipeline=$true,
			HelpMessage="String to find")]
		[String]$Search,

		[Parameter(
			Position=1,
			HelpMessage="Folder where the files are stored (search is recursive)")]
		[ValidateScript({
			if(Test-Path -Path $_)
			{
				return $true
			}
			else 
			{
				throw "Enter a valid path!"	
			}
		})]
		[String]$Path = (Get-Location),
		
		[Parameter(
			Position=2,
			HelpMessage="String must be case sensitive (Default=false)")]
		[switch]$CaseSensitive
	)

	Begin{
		
	}

	Process{
		# Files with string to find
		$Strings = Get-ChildItem -Path $Path -Recurse | Select-String -Pattern ([regex]::Escape($Search)) -CaseSensitive:$CaseSensitive | Group-Object -Property Path 
		
		# Go through each file
		foreach($String in $Strings)
		{		
			$IsBinary = Test-IsFileBinary -FilePath $String.Name

			# Go through each group
			foreach($Group in $String.Group)
			{	
				[pscustomobject] @{
					Filename = $Group.Filename
					Path = $Group.Path
					LineNumber = $Group.LineNumber
					IsBinary = $IsBinary
					Matches = $Group.Matches.Value
				}
			}   
		}
	}

	End{
		
	}
}