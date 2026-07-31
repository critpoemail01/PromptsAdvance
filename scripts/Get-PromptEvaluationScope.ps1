[CmdletBinding()]
param(
    [string[]]$ChangedPath,
    [switch]$StablePromotion,
    [string]$MapPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($MapPath)) {
    $MapPath = Join-Path $root 'EVALUATION_IMPACT_MAP.json'
}
$map = Get-Content -Raw -Encoding UTF8 -LiteralPath $MapPath | ConvertFrom-Json

if ($StablePromotion) {
    $promotionPaths = @($ChangedPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    [pscustomobject]@{
        mode = 'full'
        changedPaths = $promotionPaths
        cases = @($map.policy.fullSuiteCaseIds)
        reason = 'stable promotion requires the complete current-version pilot'
    } | ConvertTo-Json -Depth 10
    exit 0
}

if ($null -eq $ChangedPath -or $ChangedPath.Count -eq 0) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $git) {
        throw 'Provide -ChangedPath when Git is unavailable.'
    }
    $ChangedPath = @(
        & $git.Source -C $root diff --name-only --diff-filter=ACMR HEAD
        & $git.Source -C $root ls-files --others --exclude-standard
    )
}
$normalized = @($ChangedPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { (([string]$_).Replace('\', '/') -replace '^\./', '') } | Sort-Object -Unique)

$selected = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$matchedRules = [System.Collections.Generic.List[string]]::new()
foreach ($rule in @($map.rules)) {
    if (@($normalized | Where-Object { $_ -match [string]$rule.pathRegex }).Count -eq 0) {
        continue
    }
    $matchedRules.Add([string]$rule.name)
    foreach ($case in @($rule.cases)) {
        $null = $selected.Add([string]$case)
    }
}
if ($selected.Count -eq 0) {
    foreach ($case in @($map.fallbackCases)) {
        $null = $selected.Add([string]$case)
    }
    $matchedRules.Add('fallback')
}

[pscustomobject]@{
    mode = 'targeted'
    changedPaths = $normalized
    matchedRules = @($matchedRules)
    cases = @($selected | Sort-Object)
    reason = 'impact-based regression; full suite remains mandatory before stable promotion'
} | ConvertTo-Json -Depth 10
