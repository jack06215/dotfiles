function ConvertFrom-Base64
{
    <#
        .SYNOPSIS
        Decode Base64 made by ConvertTo-Base64, or for pwsh -EncodedCommand.

        .DESCRIPTION
        The decoded bytes are read as UTF-16LE, the encoding -EncodedCommand
        uses, so this reverses ConvertTo-Base64. Base64 of UTF-8 or ASCII
        text - what most other tools produce - comes out garbled.

        .PARAMETER Text
        The Base64 string to decode.

        .EXAMPLE
        ConvertFrom-Base64 -Text 'RwBlAHQALQBEAGEAdABlAA=='
        # Get-Date
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage='Base64 encoded string, which is to be converted to an plain text string')]
        [String]$Text
    )

    Begin{

    }

    Process{
        try{
            # Convert Base64 to bytes
            $Bytes = [System.Convert]::FromBase64String($Text)

            # Convert Bytes to Unicode and return it
            [System.Text.Encoding]::Unicode.GetString($Bytes)
        }
        catch{
            throw
        }
    }

    End{

    }
}