[CmdletBinding()]
param(
    [string]$CatalogPath,
    [string]$StartPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-AdvanceCatalog {
    param([Parameter(Mandatory)][string]$Candidate)

    return (
        (Test-Path -LiteralPath (Join-Path $Candidate 'PROCESS_MANIFEST.json') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Candidate 'software-lifecycle.ps1') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Candidate '.agents/skills/advance-app-start/SKILL.md') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Candidate '.agents/skills/advance-app-continue/SKILL.md') -PathType Leaf)
    )
}

$candidatePaths = [System.Collections.Generic.List[string]]::new()

function Add-Candidate {
    param([string]$Candidate)

    if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
        $candidatePaths.Add($Candidate)
    }
}

if (-not [string]::IsNullOrWhiteSpace($CatalogPath)) {
    try {
        $explicitCatalogPath = [System.IO.Path]::GetFullPath($CatalogPath)
    }
    catch {
        throw "CatalogPath is invalid: $CatalogPath"
    }
    if (-not (Test-AdvanceCatalog -Candidate $explicitCatalogPath)) {
        throw "CatalogPath is not a valid PromptsAdvance catalog: $explicitCatalogPath"
    }
    Write-Output $explicitCatalogPath
    exit 0
}

Add-Candidate -Candidate ([Environment]::GetEnvironmentVariable('PROMPTS_ADVANCE_ROOT'))

if ([string]::IsNullOrWhiteSpace($StartPath)) {
    $StartPath = (Get-Location).Path
}

if (Test-Path -LiteralPath $StartPath -PathType Leaf) {
    $StartPath = Split-Path $StartPath -Parent
}
if (Test-Path -LiteralPath $StartPath -PathType Container) {
    $current = [System.IO.DirectoryInfo]::new(
        [System.IO.Path]::GetFullPath($StartPath))
    while ($null -ne $current) {
        Add-Candidate -Candidate $current.FullName
        $current = $current.Parent
    }
}

$userProfilePath = [Environment]::GetFolderPath(
    [Environment+SpecialFolder]::UserProfile)
if (-not [string]::IsNullOrWhiteSpace($userProfilePath)) {
    Add-Candidate -Candidate (Join-Path $userProfilePath '.codex/.tmp/marketplaces/promptsadvance')
    Add-Candidate -Candidate (Join-Path $userProfilePath 'Documents/PromptsAdvance')
    Add-Candidate -Candidate (Join-Path $userProfilePath 'PromptsAdvance')
}
if ($IsWindows) {
    Add-Candidate -Candidate 'C:\Work\PromptsAdvance'
}

$visited = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
foreach ($candidate in $candidatePaths) {
    try {
        $resolvedCandidate = [System.IO.Path]::GetFullPath($candidate)
    }
    catch {
        continue
    }
    if (-not $visited.Add($resolvedCandidate)) {
        continue
    }
    if (Test-AdvanceCatalog -Candidate $resolvedCandidate) {
        Write-Output $resolvedCandidate
        exit 0
    }
}

throw @'
PromptsAdvance catalog not found. Pass -CatalogPath with the exact clone path or
set PROMPTS_ADVANCE_ROOT. No files were changed.
'@
