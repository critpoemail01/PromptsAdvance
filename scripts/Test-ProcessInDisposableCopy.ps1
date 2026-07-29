[CmdletBinding()]
param(
    [string]$CatalogRoot,
    [switch]$BrownfieldOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

if ([string]::IsNullOrWhiteSpace($CatalogRoot)) {
    $CatalogRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
else {
    $CatalogRoot = [System.IO.Path]::GetFullPath($CatalogRoot)
}

$boilerplateSource = [System.IO.Path]::GetFullPath((Join-Path $CatalogRoot '..\BoilerPlateAdvance'))
if (-not (Test-Path -LiteralPath $boilerplateSource -PathType Container)) {
    throw "BoilerPlateAdvance is missing: $boilerplateSource"
}

$evaluationRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('prompts-advance-evaluation-' + [Guid]::NewGuid().ToString('N'))
$catalogCopy = Join-Path $evaluationRoot 'PromptsAdvance'
$boilerplateLink = Join-Path $evaluationRoot 'BoilerPlateAdvance'
$powerShellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $powerShellExe -PathType Leaf)) {
    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    $powerShellExe = $pwshCommand.Source
}
if ([string]::IsNullOrWhiteSpace([string]$powerShellExe)) {
    throw 'PowerShell executable was not found.'
}

try {
    New-Item -ItemType Directory -Path $evaluationRoot | Out-Null
    Copy-Item -LiteralPath $CatalogRoot -Destination $catalogCopy -Recurse
    $linkItemType = $(if ($IsWindows) { 'Junction' } else { 'SymbolicLink' })
    New-Item -ItemType $linkItemType -Path $boilerplateLink -Target $boilerplateSource | Out-Null

    & git -C $catalogCopy init --quiet --initial-branch=main
    & git -C $catalogCopy config core.autocrlf false
    & git -C $catalogCopy config user.name 'Disposable Process Evaluator'
    & git -C $catalogCopy config user.email 'process-evaluator@example.invalid'
    & git -C $catalogCopy add --all
    & git -C $catalogCopy commit --quiet -m 'disposable catalog candidate'
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not create the disposable catalog Git baseline.'
    }
    $beforeSha = [string]@(& git -C $catalogCopy rev-parse HEAD)[0]

    & $powerShellExe -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $catalogCopy 'scripts\Test-PromptProcess.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw 'Disposable static process validation failed.'
    }

    $lifecycleArguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', (Join-Path $catalogCopy 'scripts\Test-SoftwareLifecycle.ps1'),
        '-CatalogRoot', $catalogCopy
    )
    if ($BrownfieldOnly) {
        $lifecycleArguments += '-BrownfieldOnly'
    }
    & $powerShellExe @lifecycleArguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Disposable lifecycle E2E failed.'
    }

    $afterSha = [string]@(& git -C $catalogCopy rev-parse HEAD)[0]
    $afterStatus = @(& git -C $catalogCopy status --porcelain=v1)
    if ($beforeSha -ne $afterSha -or $afterStatus.Count -ne 0) {
        throw "Disposable catalog changed during evaluation: before=$beforeSha after=$afterSha paths=$($afterStatus -join ', ')"
    }

    Write-Host 'PASS: disposable catalog evaluation.' -ForegroundColor Green
    Write-Host " - Candidate SHA: $beforeSha"
    Write-Host ' - Working tree clean after evaluation: true'
    Write-Host " - Lifecycle scope: $(if ($BrownfieldOnly) { 'brownfield only' } else { 'full E2E' })"
}
finally {
    if (Test-Path -LiteralPath $boilerplateLink) {
        $linkItem = Get-Item -Force -LiteralPath $boilerplateLink
        if (($linkItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "Refusing to remove non-junction evaluation path: $boilerplateLink"
        }
        Remove-Item -LiteralPath $boilerplateLink -Force
    }
    if (Test-Path -LiteralPath $evaluationRoot -PathType Container) {
        $resolvedEvaluation = [System.IO.Path]::GetFullPath($evaluationRoot)
        $resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)
        $requiredPrefix = $resolvedTemp +
            [System.IO.Path]::DirectorySeparatorChar +
            'prompts-advance-evaluation-'
        if (-not $resolvedEvaluation.StartsWith(
            $requiredPrefix,
            [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unverified evaluation root: $resolvedEvaluation"
        }
        Remove-Item -LiteralPath $resolvedEvaluation -Recurse -Force
    }
}
