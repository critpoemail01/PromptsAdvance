[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifestPath = Join-Path $root 'PROCESS_MANIFEST.json'
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

$promptFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'prompts') -Recurse -File -Filter '*.md')
$promptById = @{}
foreach ($file in $promptFiles) {
    if ($file.Name -notmatch '^(?<id>\d{2})-(?<identity>.+)\.md$') {
        Add-Failure "Nome de prompt inválido: $($file.FullName)"
        continue
    }
    $id = $Matches.id
    if ($promptById.ContainsKey($id)) {
        Add-Failure "ID de prompt duplicado: $id"
        continue
    }
    $promptById[$id] = $Matches.identity
}

$manifestIds = @(
    foreach ($stage in @($manifest.stages)) {
        foreach ($id in @($stage.promptIds)) { [string]$id }
    }
)
if (@($manifestIds | Select-Object -Unique).Count -ne $manifestIds.Count) {
    Add-Failure 'O manifesto contém IDs repetidos entre etapas.'
}
foreach ($id in $manifestIds) {
    if (-not $promptById.ContainsKey($id)) {
        Add-Failure "O manifesto referencia o prompt inexistente $id."
    }
}
foreach ($id in $promptById.Keys) {
    if ($manifestIds -notcontains $id) {
        Add-Failure "O ficheiro do prompt $id não está no manifesto."
    }
}

$contextDocuments = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($document in @($manifest.contextRouting.always)) {
    $null = $contextDocuments.Add([string]$document)
}
foreach ($group in @($manifest.contextRouting.groups)) {
    foreach ($id in @($group.promptIds)) {
        if (-not $promptById.ContainsKey([string]$id)) {
            Add-Failure "O grupo de contexto '$($group.name)' referencia o prompt inexistente $id."
        }
    }
    foreach ($document in @($group.documents)) {
        $null = $contextDocuments.Add([string]$document)
    }
}
foreach ($document in $contextDocuments) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $document) -PathType Leaf)) {
        Add-Failure "O routing de contexto exige o documento inexistente '$document'."
    }
}
foreach ($document in @($manifest.authoritativeReferences)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$document)) -PathType Leaf)) {
        Add-Failure "A referência autoritativa '$document' não existe."
    }
}

function Assert-Sequence {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object[]]$Actual,
        [Parameter(Mandatory)][string[]]$Expected
    )
    $actualText = (@($Actual) -join ' -> ')
    $expectedText = ($Expected -join ' -> ')
    if ($actualText -cne $expectedText) {
        Add-Failure "Routing $Name divergente: esperado '$expectedText'; encontrado '$actualText'."
    }
}

Assert-Sequence -Name 'firstSliceFoundation' -Actual @($manifest.routing.firstSliceFoundation) `
    -Expected @('21', '22', '23', '24')
Assert-Sequence -Name 'pageSlice' -Actual @($manifest.routing.pageSlice) `
    -Expected @('27', 'SURFACE_IMPROVEMENT', '20', '28')
Assert-Sequence -Name 'featureSlice' -Actual @($manifest.routing.featureSlice) `
    -Expected @('29', 'SURFACE_IMPROVEMENT', '20', '30')

$surfaceMap = $manifest.routing.surfaceImprovement
foreach ($surface in @('ssr', 'web', 'maui')) {
    $legacy = [string]$surfaceMap.$surface
    $page = [string]$manifest.routing.sliceWorkflows.page.surfacePromptBySurface.$surface
    $feature = [string]$manifest.routing.sliceWorkflows.feature.surfacePromptBySurface.$surface
    if ($legacy -ne $page -or $legacy -ne $feature) {
        Add-Failure "O prompt visual da superfície '$surface' diverge entre os routings."
    }
}

$workflowChecks = @(
    @{ Kind = 'page'; Start = '27'; Reconcile = '20'; Test = '28' },
    @{ Kind = 'feature'; Start = '29'; Reconcile = '20'; Test = '30' }
)
foreach ($check in $workflowChecks) {
    $workflow = $manifest.routing.sliceWorkflows.($check.Kind)
    if ([string]$workflow.implementationPrompt -ne $check.Start -or
        [string]$workflow.requirementsReconciliationPrompt -ne $check.Reconcile -or
        [string]$workflow.acceptanceTestPrompt -ne $check.Test) {
        Add-Failure "O workflow semântico '$($check.Kind)' diverge da sequência canónica."
    }
}

foreach ($path in @('README.md', 'PROMPT_EVALUATION.md', '.agents/skills/advance-app-continue/references/workflow.md')) {
    $fullPath = Join-Path $root $path
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $fullPath
    foreach ($match in [regex]::Matches($content, '(?i)\bprompts?\s+(?<id>\d{2})\b')) {
        $id = $match.Groups['id'].Value
        if (-not $promptById.ContainsKey($id)) {
            Add-Failure "$path referencia o prompt inexistente $id."
        }
    }
}

$routeMarker = 'ROUTE-EVAL-06: 21 -> 22 -> 23 -> 24 -> (27 -> 14|16|18 -> 20 -> 28 | 29 -> 14|16|18 -> 20 -> 30)'
$evaluation = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'PROMPT_EVALUATION.md')
if (-not $evaluation.Contains($routeMarker)) {
    Add-Failure 'EVAL-06 não contém o marcador canónico de routing atual.'
}

if ($failures.Count -gt 0) {
    Write-Host "FAIL: $($failures.Count) referência(s) inválida(s)." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: identidades e routing dos prompts são semanticamente coerentes.' -ForegroundColor Green
Write-Host " - Prompts: $($promptById.Count); manifesto: $($manifestIds.Count)."
Write-Host ' - Routing: fundação, página, funcionalidade e prompts de superfície verificados.'
Write-Host " - Contexto: $($contextDocuments.Count) documento(s) roteado(s) existente(s)."
