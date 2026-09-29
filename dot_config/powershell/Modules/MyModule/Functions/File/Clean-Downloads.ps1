function Clean-Downloads {
    <#
        .SYNOPSIS
        Delete the files in Downloads that have not changed in -Days days.

        .DESCRIPTION
        Walks %USERPROFILE%\Downloads recursively and deletes, without
        asking, every file last written more than -Days days ago. Folders are
        kept, even once they are empty.

        .PARAMETER Days
        How old a file must be, by last write time, to be deleted. Default 30.

        .EXAMPLE
        Clean-Downloads

        .EXAMPLE
        Clean-Downloads -Days 7
    #>
    param([int]$Days = 30)
    $cutoff = (Get-Date).AddDays(-$Days)
    Get-ChildItem "$env:USERPROFILE\Downloads" -Recurse |
    Where-Object { !$_.PsIsContainer -and $_.LastWriteTime -lt $cutoff } |
    Remove-Item -Force
}
