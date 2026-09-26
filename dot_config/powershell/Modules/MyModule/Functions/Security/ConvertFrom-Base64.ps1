function ConvertFrom-Base64
{
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