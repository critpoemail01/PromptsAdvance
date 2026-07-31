[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourcePath,
    [Parameter(Mandatory)][string]$DestinationPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Copy-PilotSourceTree {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    $excludedDirectories = @('.git', 'bin', 'obj', 'node_modules')
    foreach ($item in @(Get-ChildItem -LiteralPath $Source -Force)) {
        if ($item.PSIsContainer -and $item.Name -in $excludedDirectories) {
            continue
        }
        $target = Join-Path $Destination $item.Name
        if ($item.PSIsContainer) {
            New-Item -ItemType Directory -Path $target | Out-Null
            Copy-PilotSourceTree -Source $item.FullName -Destination $target
        }
        else {
            Copy-Item -LiteralPath $item.FullName -Destination $target -Force
        }
    }
}

$SourcePath = [System.IO.Path]::GetFullPath($SourcePath)
$DestinationPath = [System.IO.Path]::GetFullPath($DestinationPath)
if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "Boilerplate source does not exist: $SourcePath"
}
if (Test-Path -LiteralPath $DestinationPath) {
    throw "Destination already exists; refusing to replace it: $DestinationPath"
}
$destinationParent = Split-Path -Parent $DestinationPath
if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
    New-Item -ItemType Directory -Path $destinationParent | Out-Null
}

$sourceSha = $null
$sourceStatus = @()
if (Test-Path -LiteralPath (Join-Path $SourcePath '.git')) {
    $sourceSha = [string]@(& git -C $SourcePath rev-parse HEAD)[0]
    $sourceStatus = @(& git -C $SourcePath status --porcelain=v1)
}

New-Item -ItemType Directory -Path $DestinationPath | Out-Null
Copy-PilotSourceTree -Source $SourcePath -Destination $DestinationPath
if (Test-Path -LiteralPath (Join-Path $DestinationPath '.git')) {
    throw 'Disposable baseline inherited source Git metadata.'
}

$solutionFilter = Join-Path $DestinationPath 'BoilerPlateAdvance.Web.slnf'
$testProject = Join-Path $DestinationPath 'src/Tests/BoilerPlateAdvance.Tests.csproj'
foreach ($requiredPath in @($solutionFilter, $testProject)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Portable pilot input is missing: $requiredPath"
    }
}
$solutionFilterText = Get-Content -Raw -Encoding UTF8 -LiteralPath $solutionFilter
if ($solutionFilterText -match '(?i)Maui|net\d+\.\d+-(android|ios|maccatalyst)') {
    throw 'The Web solution filter includes a mobile target and is not portable.'
}

& git -C $DestinationPath init --quiet --initial-branch=main
& git -C $DestinationPath config core.autocrlf false
& git -C $DestinationPath config user.name 'Advance Pilot Baseline'
& git -C $DestinationPath config user.email 'advance-pilot@example.invalid'
if ($LASTEXITCODE -ne 0) {
    throw 'Could not initialize the disposable pilot repository.'
}

$commands = @(
    'dotnet restore BoilerPlateAdvance.Web.slnf --force-evaluate',
    'dotnet build BoilerPlateAdvance.Web.slnf --no-restore --nologo',
    'dotnet test --project src/Tests/BoilerPlateAdvance.Tests.csproj --no-build --no-restore -v:q --no-progress --no-ansi'
)
Push-Location $DestinationPath
try {
    & dotnet restore BoilerPlateAdvance.Web.slnf --force-evaluate
    if ($LASTEXITCODE -ne 0) { throw 'Portable Web restore failed.' }
    & dotnet build BoilerPlateAdvance.Web.slnf --no-restore --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Portable Web build failed.' }
    & dotnet test --project src/Tests/BoilerPlateAdvance.Tests.csproj `
        --no-build --no-restore -v:q --no-progress --no-ansi
    if ($LASTEXITCODE -ne 0) { throw 'Portable Web test suite failed.' }
}
finally {
    Pop-Location
}

$sourceSnapshot = @()
foreach ($file in @(Get-ChildItem -LiteralPath $DestinationPath -Recurse -File -Force)) {
    if ($file.FullName -like "$(Join-Path $DestinationPath '.git')*") {
        continue
    }
    $relativePath = [System.IO.Path]::GetRelativePath($DestinationPath, $file.FullName).Replace('\', '/')
    if ($relativePath -match '(^|/)(bin|obj|node_modules)/') {
        continue
    }
    $sourceSnapshot += [ordered]@{
        path = $relativePath
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()
    }
}
$sourceSnapshot = @($sourceSnapshot | Sort-Object { $_.path })
$baselineEvidence = [ordered]@{
    schemaVersion = 1
    sourcePath = $SourcePath
    sourceSha = $sourceSha
    sourceDirty = $sourceStatus.Count -gt 0
    sourceStatus = $sourceStatus
    platform = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    dotnetVersion = (& dotnet --version | Out-String).Trim()
    solutionFilter = 'BoilerPlateAdvance.Web.slnf'
    testProject = 'src/Tests/BoilerPlateAdvance.Tests.csproj'
    commands = $commands
    normalizedFileSnapshot = $sourceSnapshot
}
[System.IO.File]::WriteAllText(
    (Join-Path $DestinationPath 'PILOT_BASELINE.json'),
    (($baselineEvidence | ConvertTo-Json -Depth 8) + "`n"),
    $utf8NoBom)

& git -C $DestinationPath add --all
& git -C $DestinationPath commit --quiet -m 'Create portable disposable pilot baseline'
if ($LASTEXITCODE -ne 0) {
    throw 'Could not commit the disposable pilot baseline.'
}

$baselineSha = [string]@(& git -C $DestinationPath rev-parse HEAD)[0]
$status = @(& git -C $DestinationPath status --porcelain=v1)
if ($status.Count -ne 0) {
    throw "Disposable baseline is not clean: $($status -join ', ')"
}

Write-Host 'PASS: portable disposable pilot baseline is ready.' -ForegroundColor Green
Write-Host " - Baseline SHA: $baselineSha"
Write-Host ' - Scope: Web/API/Shared/Tests (MAUI excluded)'
Write-Host " - Source dirty snapshot recorded: $($sourceStatus.Count -gt 0)"
Write-Host " - Path: $DestinationPath"
