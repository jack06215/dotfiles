function grep($regex, $dir) {
    <#
        .SYNOPSIS
        Search the files in a folder, or piped-in text, for a regular expression.

        .DESCRIPTION
        Given -dir, searches the files directly inside it - not those in its
        subfolders. Otherwise searches whatever is piped in. Either way it is
        Select-String underneath: matching ignores case, and each hit comes
        back as a MatchInfo.

        Piped-in objects are matched on their ToString(), which for most is
        just the type name; to filter objects by how they display, use
        grep-table.

        .PARAMETER regex
        The regular expression to search for.

        .PARAMETER dir
        The folder whose files to search. Leave it out to search the pipeline.

        .EXAMPLE
        grep 'TODO' .\src

        .EXAMPLE
        Get-Content .\app.log | grep 'error|warn'
    #>
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}
