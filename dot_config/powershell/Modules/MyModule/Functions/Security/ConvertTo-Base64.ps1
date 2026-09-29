function ConvertTo-Base64
{
    <#
        .SYNOPSIS
        Encode a command as Base64 for pwsh -EncodedCommand.

        .DESCRIPTION
        The text is encoded as UTF-16LE first, which is what -EncodedCommand
        expects, so the result can be handed to pwsh or powershell.exe to run
        a command without any quoting trouble. Warns when the result is over
        8100 characters, which may be too long for a command line.

        ConvertFrom-Base64 reverses it.

        .PARAMETER Text
        The text to encode.

        .PARAMETER FilePath
        A file whose contents to encode instead.

        .EXAMPLE
        ConvertTo-Base64 -Text 'Get-Date'
        # RwBlAHQALQBEAGEAdABlAA==

        .EXAMPLE
        pwsh -EncodedCommand (ConvertTo-Base64 'Get-Process | Sort-Object CPU -Descending')

        .EXAMPLE
        pwsh -EncodedCommand (ConvertTo-Base64 -FilePath .\script.ps1)
    #>
    [CmdletBinding(DefaultParameterSetName='Text')]
    param(
        [Parameter(
            ParameterSetName='Text',
            Mandatory=$true,
            Position=0,
            HelpMessage='Text (command), which is to be converted to a Base64 encoded string')]
        [String]$Text,

        [Parameter(
            ParameterSetName='File',
            Mandatory=$true,
            Position=0,
            HelpMessage='Path to the file where the text (command) is stored, which is to be converterd to a Base64 encoded string')]
        [String]$FilePath
    )

    Begin{

    }

    Process{
        switch ($PSCmdlet.ParameterSetName) 
        {
            "Text" {
                $TextToConvert = $Text
            }

            "File" {
                if(Test-Path -Path $FilePath -PathType Leaf)
                {
                    # -Raw keeps the file as one string. Without it the lines
                    # come back as an array, which GetBytes joins with spaces,
                    # turning a multi-line script into one broken line.
                    $TextToConvert = Get-Content -Path $FilePath -Raw
                }
                else 
                {
                    throw "No valid file path entered... Check your input!"
                }
            }                                   
        }

        try{
            # Convert plain text to bytes
            $BytesToConvert = [Text.Encoding]::Unicode.GetBytes($TextToConvert)

            # Convert Bytes to Base64
            $EncodedText = [Convert]::ToBase64String($BytesToConvert)
        }
        catch{
            throw
        }

        if($EncodedText.Length -gt 8100)
        {
            Write-Warning -Message "Encoded command may be to long to run via ""-EncodedCommand"" of PowerShell.exe"    
        }

        $EncodedText
    }

    End{

    }
}