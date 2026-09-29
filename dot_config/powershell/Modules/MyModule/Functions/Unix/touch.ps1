function touch($file) {
    <#
        .SYNOPSIS
        Create an empty file, or update the timestamps of an existing one.

        .DESCRIPTION
        As Unix touch does: a file or folder that already exists keeps its
        contents and has its last write and last access times set to now; one
        that does not is created, empty.

        .PARAMETER file
        Path of the file to create or touch.

        .EXAMPLE
        touch notes.txt
    #>
    if (Test-Path -LiteralPath $file) {
        # -Force so a hidden file is found too
        $item = Get-Item -LiteralPath $file -Force
        $now = Get-Date
        $item.LastWriteTime = $now
        $item.LastAccessTime = $now
    }
    else {
        New-Item -ItemType File -Path $file | Out-Null
    }
}
