function sed($file, $find, $replace) {
    <#
        .SYNOPSIS
        Replace text in a file, in place.

        .DESCRIPTION
        Replaces every occurrence of -find with -replace, one line at a time,
        and writes the file back. Unlike sed, -find is plain text rather than
        a regular expression, matched case-sensitively, and it cannot span a
        line break.

        .PARAMETER file
        The file to edit.

        .PARAMETER find
        The text to replace.

        .PARAMETER replace
        The text to put in its place.

        .EXAMPLE
        sed .\config.ini 'localhost' '127.0.0.1'
    #>
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}
