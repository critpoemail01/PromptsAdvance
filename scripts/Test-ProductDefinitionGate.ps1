[CmdletBinding()]
param(
    [string]$DefinitionPath,
    [string]$StatusPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ([string]::IsNullOrWhiteSpace($DefinitionPath)) {
    $DefinitionPath = Join-Path $root 'PRODUCT_DEFINITION.md'
}
if ([string]::IsNullOrWhiteSpace($StatusPath)) {
    $StatusPath = Join-Path $root 'IMPLEMENTATION_STATUS.md'
}

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

function Get-Marker {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Name
    )

    $match = [regex]::Match(
        $Content,
        "(?m)^$([regex]::Escape($Name)):\s*(\S.*?)\s*$"
    )
    if (-not $match.Success) {
        return $null
    }
    return $match.Groups[1].Value.Trim()
}

function Test-UsefulEvidence {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    $normalized = $Value.Trim().ToLowerInvariant()
    return $normalized -notin @(
        '-',
        'a preencher',
        'pendente',
        'n/a'
    )
}

foreach ($path in @($DefinitionPath, $StatusPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Required file is missing: $path"
    }
}

if ($failures.Count -eq 0) {
    $definition = Get-Content -Raw -Encoding UTF8 -LiteralPath $DefinitionPath
    $status = Get-Content -Raw -Encoding UTF8 -LiteralPath $StatusPath

    $markers = @{
        GATE_A_VERSION = Get-Marker -Content $definition -Name 'GATE_A_VERSION'
        GATE_A_DOCUMENT_STATUS = Get-Marker -Content $definition -Name 'GATE_A_DOCUMENT_STATUS'
        GATE_A_DECISION = Get-Marker -Content $definition -Name 'GATE_A_DECISION'
        GATE_A_PRODUCT_OWNER = Get-Marker -Content $definition -Name 'GATE_A_PRODUCT_OWNER'
        GATE_A_APPROVER = Get-Marker -Content $definition -Name 'GATE_A_APPROVER'
        GATE_A_DECISION_DATE = Get-Marker -Content $definition -Name 'GATE_A_DECISION_DATE'
        GATE_A_APPROVAL_EVIDENCE = Get-Marker -Content $definition -Name 'GATE_A_APPROVAL_EVIDENCE'
    }

    if ($markers.GATE_A_DOCUMENT_STATUS -ne 'aprovado') {
        Add-Failure "GATE_A_DOCUMENT_STATUS must be 'aprovado'; found '$($markers.GATE_A_DOCUMENT_STATUS)'."
    }
    if ($markers.GATE_A_DECISION -ne 'GO') {
        Add-Failure "GATE_A_DECISION must be 'GO'; found '$($markers.GATE_A_DECISION)'."
    }

    foreach ($name in @(
        'GATE_A_VERSION',
        'GATE_A_PRODUCT_OWNER',
        'GATE_A_APPROVER',
        'GATE_A_DECISION_DATE',
        'GATE_A_APPROVAL_EVIDENCE'
    )) {
        if (-not (Test-UsefulEvidence -Value $markers[$name])) {
            Add-Failure "Required marker has no useful value: $name."
        }
    }

    if ($definition -notmatch '(?m)^\|\s*Estado do documento\s*\|\s*aprovado\s*\|') {
        Add-Failure "The human-readable document state is not 'aprovado'."
    }
    if ($definition -notmatch '(?m)^\|\s*Decis.o do Gate A\s*\|\s*GO\s*\|') {
        Add-Failure "The human-readable Gate A decision is not 'GO'."
    }

    foreach ($number in 1..12) {
        $id = 'DOR-{0:D2}' -f $number
        $row = [regex]::Match(
            $definition,
            "(?m)^\|\s*$([regex]::Escape($id))\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|"
        )

        if (-not $row.Success) {
            Add-Failure "Missing or malformed criterion: $id."
            continue
        }

        $criterionState = $row.Groups[2].Value.Trim()
        $evidence = $row.Groups[3].Value.Trim()
        if ($criterionState -ne 'passou') {
            Add-Failure "$id did not pass: state '$criterionState'."
        }
        if (-not (Test-UsefulEvidence -Value $evidence)) {
            Add-Failure "$id has no useful evidence."
        }

        $statusRow = [regex]::Match(
            $status,
            "(?m)^\|\s*$([regex]::Escape($id))\s+[^|]*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|"
        )
        if (-not $statusRow.Success) {
            Add-Failure "$id is not registered in the status gate summary."
        }
        else {
            $statusCriterionState = $statusRow.Groups[1].Value.Trim()
            $statusCriterionEvidence = $statusRow.Groups[2].Value.Trim()
            if ($statusCriterionState -ne 'passou') {
                Add-Failure "$id did not pass in the status summary: '$statusCriterionState'."
            }
            if (-not (Test-UsefulEvidence -Value $statusCriterionEvidence)) {
                Add-Failure "$id has no useful evidence in the status summary."
            }
        }
    }

    foreach ($number in 1..4) {
        $prefix = '{0:D2}-' -f $number
        $row = [regex]::Match(
            $status,
            "(?m)^\|\s*$([regex]::Escape($prefix))[^|]*\|\s*[^|]+\|\s*([^|]+?)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|"
        )

        if (-not $row.Success) {
            Add-Failure "Prompt $prefix is not registered in the progress table."
            continue
        }

        $promptState = $row.Groups[1].Value.Trim()
        $promptEvidence = $row.Groups[3].Value.Trim()
        if ($promptState -notmatch '^conclu.do$') {
            Add-Failure "Prompt $prefix is not complete: state '$promptState'."
        }
        if (-not (Test-UsefulEvidence -Value $promptEvidence)) {
            Add-Failure "Prompt $prefix has no useful evidence."
        }
    }

    $gateRow = [regex]::Match(
        $status,
        '(?m)^\|\s*A\s+.\s+defini..o do produto\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|'
    )
    if (-not $gateRow.Success) {
        Add-Failure 'Gate A is missing from IMPLEMENTATION_STATUS.md.'
    }
    else {
        $statusGateState = $gateRow.Groups[1].Value.Trim()
        $statusGateEvidence = $gateRow.Groups[2].Value.Trim()
        if ($statusGateState -notmatch '^conclu.do$') {
            Add-Failure "Gate A is not complete in IMPLEMENTATION_STATUS.md: '$statusGateState'."
        }
        if (-not (Test-UsefulEvidence -Value $statusGateEvidence)) {
            Add-Failure 'Gate A has no useful evidence in IMPLEMENTATION_STATUS.md.'
        }
    }

    $statusDecision = Get-Marker -Content $status -Name 'GATE_A_DECISION'
    if ($statusDecision -ne 'GO') {
        Add-Failure "IMPLEMENTATION_STATUS.md must contain GATE_A_DECISION: GO; found '$statusDecision'."
    }
}

if ($failures.Count -gt 0) {
    Write-Host "BLOCKED: Gate A is invalid ($($failures.Count) problem(s))." -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: Gate A is valid; stage 2 may start.' -ForegroundColor Green
Write-Host " - Definition: $([System.IO.Path]::GetFullPath($DefinitionPath))"
Write-Host " - Status: $([System.IO.Path]::GetFullPath($StatusPath))"
Write-Host ' - DOR-01 through DOR-12 passed with evidence.'
Write-Host ' - Prompts 01 through 04 completed with evidence.'
exit 0
