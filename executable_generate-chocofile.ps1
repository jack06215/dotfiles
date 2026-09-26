#!/usr/bin/env pwsh
# Windows counterpart of generate-brewfile.sh: rewrites the Chocolatey manifest
# from what this machine currently has installed.
#
#     pwsh ./generate-chocofile.ps1
#
# There is no Bazel target for this one: no rule in the workspace can wrap a
# .ps1 - not sh_binary, and not the py_binary that //:export_powertoys_settings
# runs on - and rewriting this in Python just to get one has not been worth it.
# `pwsh ./generate-chocofile.ps1` is the entry point.
#
# Chocolatey has no `brew leaves`, so this derives one: every installed package
# that appears as a <dependency> of another installed package is a dependency,
# not something asked for. That drops the `*.install` shim packages, vcredist*,
# the KB* hotfixes, chocolatey-*.extension and webview2-runtime - on a machine
# with 122 packages installed it leaves 87.
#
# Like `brew bundle dump`, this replaces the manifest wholesale. Two kinds of
# hand-curation in the existing file are therefore lost and have to be
# reapplied from the diff:
#   - packages deliberately absent because mise owns them (nodejs, python, jq,
#     kubernetes-cli, kubernetes-helm, openjdk) come back;
#   - packages listed but not installed here (git from the official installer,
#     anything added for a future machine) are dropped, and reported as such.
# Read the diff before committing.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Resolved at runtime so this file needs no chezmoi rendering and works both as
# the ~/generate-chocofile.ps1 target and from a checkout.
$sourceDir = if ($env:BUILD_WORKSPACE_DIRECTORY) {
    $env:BUILD_WORKSPACE_DIRECTORY
}
else {
    (chezmoi source-path)
}
$manifest = Join-Path $sourceDir 'dot_config/powershell/chocolatey/packages.config'

function Assert-Choco {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error 'generate-chocofile: choco not found in PATH. Run setup.ps1 first.'
        exit 1
    }
}

# Every package id named as a dependency by any installed package's nuspec.
function Get-DependencyIds {
    $deps = @{}
    $lib = Join-Path $env:ChocolateyInstall 'lib'
    if (-not (Test-Path -LiteralPath $lib)) {
        return $deps
    }

    foreach ($dir in Get-ChildItem -LiteralPath $lib -Directory) {
        $nuspec = Join-Path $dir.FullName "$($dir.Name).nuspec"
        if (-not (Test-Path -LiteralPath $nuspec)) { continue }
        try {
            $xml = [xml](Get-Content -LiteralPath $nuspec -Raw)
        }
        catch {
            Write-Warning "generate-chocofile: could not parse $nuspec, ignoring"
            continue
        }
        # XPath rather than dotted property access: a nuspec with no
        # dependencies has no such node at all, which Set-StrictMode turns into
        # an error, and local-name() sidesteps the nuspec XML namespace.
        foreach ($d in $xml.SelectNodes('//*[local-name()="dependency"]')) {
            $id = $d.GetAttribute('id')
            if ($id) { $deps[$id.ToLowerInvariant()] = $true }
        }
    }
    return $deps
}

function Get-LeafPackages {
    $deps = Get-DependencyIds

    # `choco list -r` is id|version, one per line.
    $installed = choco list --limit-output | Where-Object { $_ } | ForEach-Object {
        $parts = $_ -split '\|'
        [pscustomobject]@{ Id = $parts[0]; Version = $parts[1] }
    }

    # chocolatey itself is the package manager, not a package it manages.
    $installed |
        Where-Object { -not $deps.ContainsKey($_.Id.ToLowerInvariant()) } |
        Where-Object { $_.Id -ne 'chocolatey' } |
        Sort-Object { $_.Id.ToLowerInvariant() }
}

function Get-ManifestIds {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    try {
        ([xml](Get-Content -LiteralPath $Path -Raw)).SelectNodes('//package[@id]') |
            ForEach-Object { $_.GetAttribute('id') }
    }
    catch {
        Write-Warning "generate-chocofile: could not parse the existing $Path"
        @()
    }
}

function Write-Manifest {
    param($Leaves)

    $header = @'
<?xml version="1.0" encoding="utf-8"?>
<!--
  Chocolatey package manifest, the Windows counterpart of brewfiles/. setup.ps1
  feeds it to `choco install`, then follows with `choco upgrade all`.

  Regenerate with generate-chocofile.ps1, which lists the packages this machine
  has installed that nothing else depends on - Chocolatey's equivalent of
  `brew leaves`. It replaces this file wholesale, so re-apply the curation
  below from the diff afterwards.

  Curation rules:
  - Language runtimes pinned in .tool-versions are NOT here. mise installs
    those (nodejs, python, jq, kubectl, helm, kustomize, kind, dasel,
    shellcheck, shfmt, poetry), reading the same file asdf reads on
    macOS/WSL2. Listing them here too would give one tool two owners and let
    the versions drift, which is how this machine ended up running node 24.2.0
    against a `nodejs 23.9.0` pin.
  - Tools Chocolatey does not carry are in ../winget/packages.json instead:
    atuin, carapace, gum, grpcurl, zellij, btop, sd, and mise itself.
  - `sd` is deliberately absent: Chocolatey's `sd` is an HF contest logger for
    ham radio, not the sed alternative. The real one is chmln.sd on winget.
  - win32yank stays on Chocolatey even though winget has a newer 0.1.1:
    .chezmoi.toml.tmpl locates it under C:\ProgramData\chocolatey\lib, and
    WSL2's pbcopy/pbpaste break if it moves.
  - git is listed although it is absent from `choco list` on this machine - it
    was installed from the official installer. A fresh machine needs it.
-->
<packages>
'@

    $lines = foreach ($p in $Leaves) {
        '  <package id="{0}" />' -f $p.Id
    }

    $body = $header + "`n" + ($lines -join "`n") + "`n</packages>`n"

    $dir = Split-Path -Parent $manifest
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    # UTF-8 without BOM: the XML declaration says utf-8 and choco's parser is
    # happier without the mark.
    [System.IO.File]::WriteAllText($manifest, $body, [System.Text.UTF8Encoding]::new($false))
}

function Write-DroppedReport {
    param([string[]]$Before, $Leaves)

    $after = $Leaves | ForEach-Object { $_.Id.ToLowerInvariant() }
    $dropped = $Before | Where-Object { $after -notcontains $_.ToLowerInvariant() }
    if (-not $dropped) { return }

    Write-Host ''
    Write-Warning 'Dropped (in the old manifest, not installed on request now):'
    $dropped | Sort-Object | ForEach-Object { Write-Host "  $_" }
    Write-Host 'Reinstall them and rerun, or restore the lines, if they are still wanted.'
}

Assert-Choco
$before = @(Get-ManifestIds -Path $manifest)
$leaves = @(Get-LeafPackages)
Write-Manifest -Leaves $leaves
Write-DroppedReport -Before $before -Leaves $leaves

Write-Host ''
Write-Host "Wrote $manifest"
Write-Host "  $($leaves.Count) packages"
