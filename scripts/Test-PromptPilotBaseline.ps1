[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
$solutionFilter = Join-Path $ProjectPath 'BoilerPlateAdvance.Web.slnf'
$testProject = Join-Path $ProjectPath 'src/Tests/BoilerPlateAdvance.Tests.csproj'
$evidencePath = Join-Path $ProjectPath 'PILOT_BASELINE.json'

foreach ($requiredPath in @($solutionFilter, $testProject, $evidencePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Portable pilot baseline file is missing: $requiredPath"
    }
}
$beforeSha = [string]@(& git -C $ProjectPath rev-parse HEAD)[0]
$beforeStatus = @(& git -C $ProjectPath status --porcelain=v1)
if ($beforeStatus.Count -ne 0) {
    throw "Pilot baseline must start clean: $($beforeStatus -join ', ')"
}
$evidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $evidencePath | ConvertFrom-Json
if ($evidence.schemaVersion -ne 1 -or
    $evidence.solutionFilter -ne 'BoilerPlateAdvance.Web.slnf' -or
    $evidence.testProject -ne 'src/Tests/BoilerPlateAdvance.Tests.csproj') {
    throw 'PILOT_BASELINE.json does not describe the supported portable profile.'
}
$solutionFilterText = Get-Content -Raw -Encoding UTF8 -LiteralPath $solutionFilter
if ($solutionFilterText -match '(?i)Maui|net\d+\.\d+-(android|ios|maccatalyst)') {
    throw 'The Web solution filter includes a mobile target.'
}

Push-Location $ProjectPath
try {
    & dotnet restore BoilerPlateAdvance.Web.slnf --locked-mode
    if ($LASTEXITCODE -ne 0) { throw 'Locked portable Web restore failed.' }
    & dotnet build BoilerPlateAdvance.Web.slnf --no-restore --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Portable Web build failed.' }
    & dotnet test --project src/Tests/BoilerPlateAdvance.Tests.csproj `
        --no-build --no-restore -v:q --no-progress --no-ansi
    if ($LASTEXITCODE -ne 0) { throw 'Portable Web test suite failed.' }
}
finally {
    Pop-Location
}

$afterSha = [string]@(& git -C $ProjectPath rev-parse HEAD)[0]
$afterStatus = @(& git -C $ProjectPath status --porcelain=v1)
if ($beforeSha -ne $afterSha -or $afterStatus.Count -ne 0) {
    throw 'Baseline validation changed the immutable pilot candidate.'
}
Write-Host 'PASS: portable pilot baseline is clean and executable.' -ForegroundColor Green
Write-Host " - Baseline SHA: $beforeSha"
Write-Host ' - Scope: Web/API/Shared/Tests (MAUI excluded)'
