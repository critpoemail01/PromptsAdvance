[CmdletBinding()]
param(
    [string]$ProjectsRoot,
    [switch]$AcceptCandidateCatalog,
    [string]$Objective = 'Propagate the updated Advance tool catalog to known local lifecycle instances'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$catalogRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($ProjectsRoot)) {
    $ProjectsRoot = Join-Path (Split-Path $catalogRoot -Parent) 'SoftwareProcesses'
}
$ProjectsRoot = [System.IO.Path]::GetFullPath($ProjectsRoot)
$lifecycle = Join-Path $catalogRoot 'software-lifecycle.ps1'
$catalogManifest = Get-Content -Raw -Encoding UTF8 `
    -LiteralPath (Join-Path $catalogRoot 'PROCESS_MANIFEST.json') | ConvertFrom-Json
$powerShell = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $powerShell) { $powerShell = Get-Command powershell -ErrorAction Stop }

if (-not (Test-Path -LiteralPath $ProjectsRoot -PathType Container)) {
    throw "Known lifecycle root does not exist: $ProjectsRoot"
}
if ([string]$catalogManifest.releaseChannel -ne 'stable' -and -not $AcceptCandidateCatalog) {
    throw "Catalog $($catalogManifest.catalogVersion) is '$($catalogManifest.releaseChannel)'. Use -AcceptCandidateCatalog only with explicit programmer authorization."
}
if ([string]::IsNullOrWhiteSpace($Objective) -or $Objective.Contains('|') -or
    $Objective.Contains("`r") -or $Objective.Contains("`n")) {
    throw 'Objective must be non-empty and cannot contain pipes or new lines.'
}

$updated = [System.Collections.Generic.List[string]]::new()
$skipped = [System.Collections.Generic.List[string]]::new()
$failed = [System.Collections.Generic.List[string]]::new()
$candidates = @(
    Get-ChildItem -LiteralPath $ProjectsRoot -Directory |
        Where-Object {
            $_.Name -notmatch '-(?:tool-update-backup|failed-upgrade)-\d{8}-\d{6}$' -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'LIFECYCLE_STATE.json') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'PROCESS_MANIFEST.json') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $_.FullName 'software-lifecycle.ps1') -PathType Leaf)
        } |
        Sort-Object Name
)

foreach ($candidate in $candidates) {
    $name = $candidate.Name
    $root = $candidate.FullName
    $recoveryMarkers = @(
        Get-ChildItem -LiteralPath $ProjectsRoot -Directory -Filter "$name-*" |
            Where-Object { $_.Name -match "^$([regex]::Escape($name))-(?:tool-update-backup|failed-upgrade)-\d{8}-\d{6}$" }
    )
    if ($recoveryMarkers.Count -gt 0) {
        $skipped.Add("${name}: recovery/concurrent-update marker exists ($($recoveryMarkers.Name -join ', '))")
        continue
    }

    try {
        $state = Get-Content -Raw -Encoding UTF8 `
            -LiteralPath (Join-Path $root 'LIFECYCLE_STATE.json') | ConvertFrom-Json
        if ([string]$state.status -eq 'completed') {
            $skipped.Add("${name}: completed immutable lifecycle")
            continue
        }
        if ($null -ne $state.PSObject.Properties['activeWorkAttemptId'] -and
            -not [string]::IsNullOrWhiteSpace([string]$state.activeWorkAttemptId)) {
            $skipped.Add("${name}: active work attempt $($state.activeWorkAttemptId)")
            continue
        }

        $embeddedLifecycle = Join-Path $root 'software-lifecycle.ps1'
        $validationOutput = @(
            & $powerShell.Source -NoProfile -File $embeddedLifecycle `
                validate -ProcessRoot $root 2>&1
        )
        if ($LASTEXITCODE -ne 0) {
            $failed.Add("${name}: existing lifecycle validation failed — $($validationOutput -join ' ')")
            continue
        }

        $upgradeArguments = @(
            '-NoProfile', '-File', $lifecycle,
            'upgrade', '-ProcessRoot', $root,
            '-ConfirmMigration', '-Objective', $Objective
        )
        if ([string]$catalogManifest.releaseChannel -ne 'stable') {
            $upgradeArguments += '-AcceptCandidateCatalog'
        }
        $upgradeOutput = @(& $powerShell.Source @upgradeArguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            $failed.Add("${name}: upgrade failed — $($upgradeOutput -join ' ')")
            continue
        }

        $finalOutput = @(
            & $powerShell.Source -NoProfile -File $embeddedLifecycle `
                validate -ProcessRoot $root 2>&1
        )
        if ($LASTEXITCODE -ne 0) {
            $failed.Add("${name}: final validation failed — $($finalOutput -join ' ')")
            continue
        }
        $updated.Add("$name -> $($catalogManifest.catalogVersion)")
    }
    catch {
        $failed.Add("${name}: $($_.Exception.Message)")
    }
}

Write-Host "Advance local lifecycle propagation: $($catalogManifest.catalogVersion)" -ForegroundColor Cyan
Write-Host " - Updated: $(if ($updated.Count -eq 0) { 'none' } else { $updated -join '; ' })"
Write-Host " - Skipped: $(if ($skipped.Count -eq 0) { 'none' } else { $skipped -join '; ' })"
Write-Host " - Failed: $(if ($failed.Count -eq 0) { 'none' } else { $failed -join '; ' })"
if ($failed.Count -gt 0) { exit 1 }
