[CmdletBinding()]
param(
    [string]$ApprovalPath,
    [string]$ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

$root = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($ApprovalPath)) {
    $ApprovalPath = Join-Path $root 'PILOT_APPROVAL.md'
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $root 'PROCESS_MANIFEST.json'
}
$ApprovalPath = [System.IO.Path]::GetFullPath($ApprovalPath)
$ManifestPath = [System.IO.Path]::GetFullPath($ManifestPath)

foreach ($path in @($ApprovalPath, $ManifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Implementation-readiness evidence is missing: $path"
    }
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $ManifestPath | ConvertFrom-Json
$content = Get-Content -Raw -Encoding UTF8 -LiteralPath $ApprovalPath
$values = @{}
foreach ($line in ($content -split "\r?\n")) {
    if ($line -notmatch '^\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$') {
        continue
    }
    $key = $Matches[1].Trim()
    $value = $Matches[2].Trim()
    if ($key -notin @('Campo', '---')) {
        $values[$key] = $value
    }
}

$issues = [System.Collections.Generic.List[string]]::new()
$manifestChannel = if ($manifest.PSObject.Properties.Name -contains 'releaseChannel') {
    [string]$manifest.releaseChannel
}
else {
    'missing'
}
if ($manifestChannel -ne 'stable') {
    $issues.Add("Manifest releaseChannel must be 'stable' before implementation; found '$manifestChannel'.")
}
function Require-Exact {
    param([string]$Key, [string]$Expected)
    if (-not $values.ContainsKey($Key) -or $values[$Key] -ne $Expected) {
        $issues.Add("$Key must be '$Expected'.")
    }
}
function Require-Material {
    param([string]$Key)
    if (-not $values.ContainsKey($Key) -or
        [string]::IsNullOrWhiteSpace([string]$values[$Key]) -or
        $values[$Key] -match '(?i)^(pending|a preencher|-)$' -or
        $values[$Key] -eq [string][char]0x2014) {
        $issues.Add("$Key must contain durable current-version evidence.")
    }
}

Require-Exact -Key 'Catalog version' -Expected ([string]$manifest.catalogVersion)
Require-Exact -Key 'Status' -Expected 'approved'
Require-Exact -Key 'Suite cases' -Expected '15/15'
Require-Exact -Key 'Critical failures' -Expected '0'
foreach ($key in @('Human evaluator', 'Independent reviewer', 'Evidence', 'Approved at')) {
    Require-Material -Key $key
}
if ($values.ContainsKey('Human evaluator') -and
    $values.ContainsKey('Independent reviewer') -and
    $values['Human evaluator'] -eq $values['Independent reviewer']) {
    $issues.Add('Human evaluator and independent reviewer must be different identities.')
}

if ($issues.Count -gt 0) {
    Write-Host "FAIL: implementation readiness gate found $($issues.Count) issue(s)." -ForegroundColor Red
    $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: the current catalog version has approved pilot evidence.' -ForegroundColor Green
Write-Host " - Catalog version: $($manifest.catalogVersion)"
Write-Host " - Suite: $($values['Suite cases'])"
Write-Host " - Critical failures: $($values['Critical failures'])"
Write-Host " - Human evaluator: $($values['Human evaluator'])"
Write-Host " - Independent reviewer: $($values['Independent reviewer'])"
exit 0
