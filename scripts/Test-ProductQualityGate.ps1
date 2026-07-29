[CmdletBinding()]
param(
    [string]$BaselinePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

if ([string]::IsNullOrWhiteSpace($BaselinePath)) {
    $BaselinePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'PRODUCT_QUALITY_BASELINE.md'
}
$BaselinePath = [System.IO.Path]::GetFullPath($BaselinePath)
if (-not (Test-Path -LiteralPath $BaselinePath -PathType Leaf)) {
    throw "Product quality baseline is missing: $BaselinePath"
}

$baselineContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $BaselinePath
$issues = [System.Collections.Generic.List[string]]::new()

function Get-Section {
    param([Parameter(Mandatory)][string]$HeadingPattern)

    $match = [regex]::Match(
        $script:baselineContent,
        "(?ms)^## $HeadingPattern\s*\r?\n(?<body>.*?)(?=^## |\z)")
    if (-not $match.Success) {
        $issues.Add("Missing section matching: $HeadingPattern")
        return ''
    }
    return $match.Groups['body'].Value
}

function Get-TableRows {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Section)

    $rows = @()
    foreach ($line in ($Section -split "\r?\n")) {
        if ($line -notmatch '^\s*\|.*\|\s*$') {
            continue
        }
        $cells = @($line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -eq 0 -or $cells[0] -match '^-{3,}$') {
            continue
        }
        if ($cells[0] -match '^(Campo|Refer.ncia|ID|Dimens.o|Tarefa|Superf.cie/componente|Gate)$') {
            continue
        }
        $rows += ,$cells
    }
    return $rows
}

function Test-MaterialValue {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }
    return $Value -notmatch '(?i)^(a preencher|pendente|-|n/?a)$' -and
        $Value -ne [string][char]0x2014
}

function Test-Passed {
    param([AllowNull()][string]$Value)
    return (-not [string]::IsNullOrWhiteSpace($Value)) -and
        $Value -match '(?i)^(passou|aprovado|confirmado)$'
}

$identification = @(Get-TableRows (Get-Section 'Identifica..o'))
$requiredIdentity = @(
    '^Produto$',
    '^Vers.o da baseline$',
    '^Jornadas/superf.cies abrangidas$',
    '^P.blico e contexto de uso$',
    '^Owner de produto$',
    '^Revisor de Product Design/UX$',
    '^Revisor de engenharia/frontend$',
    '^Data da aprova..o$'
)
foreach ($fieldPattern in $requiredIdentity) {
    $row = @($identification | Where-Object { $_[0] -match $fieldPattern })
    if ($row.Count -ne 1 -or
        $row[0].Count -lt 4 -or
        -not (Test-MaterialValue $row[0][1]) -or
        -not (Test-Passed $row[0][2]) -or
        -not (Test-MaterialValue $row[0][3])) {
        $issues.Add("Identification field is incomplete or unapproved: $fieldPattern")
    }
}

$benchmarks = @(
    Get-TableRows (Get-Section 'Benchmark aprovado') |
        Where-Object { $_.Count -ge 9 -and (Test-MaterialValue $_[0]) }
)
if ($benchmarks.Count -lt 3) {
    $issues.Add('Benchmark requires at least three populated, approved references.')
}
foreach ($row in $benchmarks) {
    foreach ($column in 0..8) {
        if (-not (Test-MaterialValue $row[$column])) {
            $issues.Add("Benchmark '$($row[0])' has an incomplete field.")
            break
        }
    }
}

$principles = @(
    Get-TableRows (Get-Section 'Princ.pios de experi.ncia') |
        Where-Object { $_.Count -ge 5 -and $_[0] -match '^XP-\d{2}$' }
)
if ($principles.Count -lt 5 -or $principles.Count -gt 10) {
    $issues.Add('Experience principles require between five and ten populated XP rows.')
}
foreach ($row in $principles) {
    foreach ($column in 1..4) {
        if (-not (Test-MaterialValue $row[$column])) {
            $issues.Add("Experience principle '$($row[0])' is incomplete.")
            break
        }
    }
}

$rubric = @(Get-TableRows (Get-Section 'Rubrica m.nima profissional'))
if ($rubric.Count -lt 10) {
    $issues.Add('The professional rubric is incomplete.')
}
foreach ($row in $rubric) {
    if ($row.Count -lt 5) {
        $issues.Add('A professional rubric row has fewer than five columns.')
        continue
    }
    if ($row[1] -match '(?i)cr.tica') {
        $notApplicable = $row[4] -match '(?i)^n.o aplic.vel$'
        if (-not (Test-Passed $row[4]) -and -not $notApplicable) {
            $issues.Add("Critical rubric item did not pass: $($row[0])")
        }
        if ($notApplicable -and (-not (Test-MaterialValue $row[3]) -or $row[3].Length -lt 20)) {
            $issues.Add("Critical not-applicable item lacks a material justification: $($row[0])")
        }
        if (-not (Test-MaterialValue $row[2]) -or -not (Test-MaterialValue $row[3])) {
            $issues.Add("Critical rubric item lacks a specific criterion or evidence: $($row[0])")
        }
    }
}

$firstSlice = @(Get-TableRows (Get-Section 'Primeira vertical slice'))
if ($firstSlice.Count -lt 8) {
    $issues.Add('The first vertical-slice evidence table is incomplete.')
}
foreach ($row in $firstSlice) {
    if ($row.Count -lt 3 -or
        -not (Test-MaterialValue $row[1]) -or
        -not (Test-Passed $row[2])) {
        $issues.Add("First-slice evidence did not pass: $($row[0])")
    }
}

$usability = @(
    Get-TableRows (Get-Section 'Teste de usabilidade') |
        Where-Object { $_.Count -ge 6 -and (Test-MaterialValue $_[0]) }
)
if ($usability.Count -lt 1) {
    $issues.Add('Usability evidence or an explicitly approved exception is missing.')
}
foreach ($row in $usability) {
    foreach ($column in 0..5) {
        if (-not (Test-MaterialValue $row[$column])) {
            $issues.Add("Usability row '$($row[0])' is incomplete.")
            break
        }
    }
}

$visual = @(
    Get-TableRows (Get-Section 'Regress.o visual') |
        Where-Object { $_.Count -ge 7 -and (Test-MaterialValue $_[0]) }
)
$passingVisual = @(
    $visual |
        Where-Object {
            (Test-Passed $_[5]) -and
            (Test-MaterialValue $_[3]) -and
            (Test-MaterialValue $_[4]) -and
            (Test-MaterialValue $_[6])
        }
)
if ($passingVisual.Count -lt 1) {
    $issues.Add('No reproducible visual-regression row passed with baseline, environment and approver.')
}

$findings = @(Get-TableRows (Get-Section 'Findings e exce..es'))
foreach ($row in $findings) {
    if ($row.Count -lt 7) {
        continue
    }
    $isMaterialFinding = Test-MaterialValue $row[1]
    $isSevere = $row[1] -match '(?i)^(cr.tica|critica|alta)$'
    $isOpen = $row[6] -notmatch '(?i)^(fechado|corrigido|aceite com exce..o aprovada)$'
    if ($isMaterialFinding -and $isSevere -and $isOpen) {
        $issues.Add("Open critical/high product-quality finding: $($row[0])")
    }
}

$decision = @(
    Get-TableRows (Get-Section 'Decis.o') |
        Where-Object { $_[0] -match '^Primeira slice pronta para propaga..o$' }
)
if ($decision.Count -ne 1 -or
    $decision[0].Count -lt 4 -or
    -not (Test-Passed $decision[0][1]) -or
    -not (Test-MaterialValue $decision[0][2]) -or
    -not (Test-MaterialValue $decision[0][3])) {
    $issues.Add('The first-slice propagation decision is not approved with evidence and approver.')
}

if ($issues.Count -gt 0) {
    Write-Host "FAIL: product quality gate found $($issues.Count) issue(s)." -ForegroundColor Red
    $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'PASS: product quality gate is supported by structured evidence.' -ForegroundColor Green
Write-Host " - Baseline: $BaselinePath"
Write-Host " - Benchmarks: $($benchmarks.Count)"
Write-Host " - Experience principles: $($principles.Count)"
Write-Host " - Critical rubric rows: $(@($rubric | Where-Object { $_[1] -match '(?i)cr.tica' }).Count)"
Write-Host " - Usability rows: $($usability.Count)"
Write-Host " - Passing visual-regression rows: $($passingVisual.Count)"
exit 0
