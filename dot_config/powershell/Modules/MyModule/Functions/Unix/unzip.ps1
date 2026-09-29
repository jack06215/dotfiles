function unzip ($file) {
    <#
        .SYNOPSIS
        Extract a zip file from the current folder into the current folder.

        .DESCRIPTION
        The archive is looked up by name in the current folder only, so give
        a file name rather than a path.

        .PARAMETER file
        Name of a .zip file in the current folder.

        .EXAMPLE
        unzip release.zip
    #>
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
