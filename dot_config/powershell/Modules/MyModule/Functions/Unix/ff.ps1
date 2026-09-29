function ff($name) {
    <#
        .SYNOPSIS
        Find files and folders by name under the current folder.

        .DESCRIPTION
        Searches the current location recursively and prints the full path
        of every file and folder whose name contains -name, ignoring case.
        -name may itself hold wildcards. Folders that cannot be read are
        skipped silently.

        .PARAMETER name
        Part of the name to look for.

        .EXAMPLE
        ff profile

        .EXAMPLE
        ff 'test*.ps1'
    #>
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}
