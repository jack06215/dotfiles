function Clear-Cache {
    <#
        .SYNOPSIS
        Empty the Windows prefetch, temp and Internet cache folders.

        .DESCRIPTION
        Deletes everything in $env:SystemRoot\Prefetch, $env:SystemRoot\Temp,
        your own $env:TEMP and %LOCALAPPDATA%\Microsoft\Windows\INetCache.
        Errors are silenced, so files in use are skipped, and without
        administrator rights the two folders under $env:SystemRoot are left
        largely as they were.

        .EXAMPLE
        Clear-Cache
    #>
    Write-Host "Clearing cache..." -ForegroundColor Cyan

    # Clear Windows Prefetch
    Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

    # Clear Windows Temp
    Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear User Temp
    Write-Host "Clearing User Temp..." -ForegroundColor Yellow
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear Internet Explorer Cache
    Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "Cache clearing completed." -ForegroundColor Green
}
