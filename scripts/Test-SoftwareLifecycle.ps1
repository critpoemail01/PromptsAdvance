[CmdletBinding()]
param(
    [string]$CatalogRoot,
    [switch]$KeepFixture,
    [switch]$BrownfieldOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$env:ADVANCE_LIFECYCLE_MODE = 'governed'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom
if (-not (Test-Path -LiteralPath 'variable:IsWindows')) {
    $IsWindows = $env:OS -eq 'Windows_NT'
}

if ([string]::IsNullOrWhiteSpace($CatalogRoot)) {
    $CatalogRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
else {
    $CatalogRoot = [System.IO.Path]::GetFullPath($CatalogRoot)
}

$entryPoint = Join-Path $CatalogRoot 'software-lifecycle.ps1'
if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
    throw "Lifecycle entry point is missing: $entryPoint"
}

$powerShellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $powerShellExe -PathType Leaf)) {
    $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
    $powerShellExe = $pwshCommand.Source
}
if ([string]::IsNullOrWhiteSpace([string]$powerShellExe)) {
    throw 'PowerShell executable was not found.'
}
$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("prompts-lifecycle-e2e-" + [Guid]::NewGuid().ToString('N'))
$junctionRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("prompts-lifecycle-junction-" + [Guid]::NewGuid().ToString('N'))
$brownfieldFixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("prompts-brownfield-e2e-" + [Guid]::NewGuid().ToString('N'))
$brownfieldProjectRoot = Join-Path $brownfieldFixtureRoot 'existing-application'
$brownfieldProcessRoot = Join-Path $brownfieldFixtureRoot 'isolated-process'
$brownfieldCollisionRoot = Join-Path $brownfieldFixtureRoot 'occupied-process'
$stableCatalogRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("prompts-stable-catalog-" + [Guid]::NewGuid().ToString('N'))
$boilerplate = [System.IO.Path]::GetFullPath((Join-Path $CatalogRoot '..\BoilerPlateAdvance'))
$ownedBoilerplateFixture = $null
if (-not (Test-Path -LiteralPath $boilerplate -PathType Container)) {
    $ownedBoilerplateFixture = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("prompts-boilerplate-fixture-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $ownedBoilerplateFixture | Out-Null
    [System.IO.File]::WriteAllText(
        (Join-Path $ownedBoilerplateFixture 'README.md'),
        "Disposable BoilerPlateAdvance fixture for lifecycle tests.`n",
        $utf8NoBom)
    $boilerplate = [System.IO.Path]::GetFullPath($ownedBoilerplateFixture)
}
$results = [System.Collections.Generic.List[string]]::new()

function Invoke-RawLifecycle {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$ScriptPath = $entryPoint
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = @(& $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output | Out-String).Trim()
    }
}

function Get-LifecycleArgument {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Name
    )

    $index = [Array]::IndexOf($Arguments, $Name)
    if ($index -lt 0 -or $index + 1 -ge $Arguments.Count) {
        return $null
    }
    return [string]$Arguments[$index + 1]
}

function Prepare-TestWorkCloseout {
    param([Parameter(Mandatory)][string[]]$Arguments)

    if ($Arguments.Count -lt 1 -or [string]$Arguments[0] -ne 'record') {
        return
    }
    $root = Get-LifecycleArgument -Arguments $Arguments -Name '-ProcessRoot'
    $promptId = Get-LifecycleArgument -Arguments $Arguments -Name '-PromptId'
    if ([string]::IsNullOrWhiteSpace($root) -or
        [string]::IsNullOrWhiteSpace($promptId) -or
        -not (Test-Path -LiteralPath (Join-Path $root 'LIFECYCLE_STATE.json') -PathType Leaf)) {
        return
    }

    try {
        $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'PROCESS_MANIFEST.json') |
            ConvertFrom-Json
        $state = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'LIFECYCLE_STATE.json') |
            ConvertFrom-Json
    }
    catch {
        return
    }
    $ledgerRequired = [string]$env:ADVANCE_LIFECYCLE_MODE -eq 'governed' -or
        ($null -ne $manifest.executionPolicy.PSObject.Properties['taskLedgerRequired'] -and
            [bool]$manifest.executionPolicy.taskLedgerRequired)
    if (-not $ledgerRequired -or
        [string]$state.currentPrompt -ne $promptId) {
        return
    }

    if ([string]::IsNullOrWhiteSpace([string]$state.activeWorkAttemptId)) {
        $start = Invoke-RawLifecycle @(
            'work-start',
            '-ProcessRoot', $root
        )
        if ($start.ExitCode -ne 0) {
            return
        }
    }
    $closeout = Invoke-RawLifecycle @(
        'closeout',
        '-ProcessRoot', $root,
        '-Evidence', "fixture://work-$promptId",
        '-VerificationKind', 'command',
        '-VerifyCommand', "fixture://verify-$promptId",
        '-VerifyExitCode', '0',
        '-VerifyEvidence', "fixture://verification-$promptId",
        '-ReviewEvidence', "fixture://adversarial-review-$promptId"
    )
    if ($closeout.ExitCode -ne 0) {
        return
    }
}

function Invoke-Lifecycle {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$ScriptPath = $entryPoint
    )

    Prepare-TestWorkCloseout -Arguments $Arguments
    return Invoke-RawLifecycle -Arguments $Arguments -ScriptPath $ScriptPath
}

function Require-ExitCode {
    param(
        [Parameter(Mandatory)]$Execution,
        [Parameter(Mandatory)][int]$Expected,
        [Parameter(Mandatory)][string]$Label
    )

    if ($Execution.ExitCode -ne $Expected) {
        throw "$Label expected exit code $Expected, found $($Execution.ExitCode). Output: $($Execution.Output)"
    }
    $results.Add("$Label -> $Expected")
}

try {
    New-Item -ItemType Directory -Path $brownfieldProjectRoot | Out-Null
    $brownfieldSentinel = Join-Path $brownfieldProjectRoot 'existing-file.txt'
    [System.IO.File]::WriteAllText(
        $brownfieldSentinel,
        "existing application content`r`n",
        $utf8NoBom)
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    $brownfieldGitHead = $null
    $brownfieldGitRemote = $null
    $brownfieldGitStatus = $null
    $brownfieldGitMetadataHashes = @{}
    if ($null -ne $gitCommand) {
        & $gitCommand.Source -C $brownfieldProjectRoot init --quiet --initial-branch=main
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not initialize the disposable brownfield Git repository.'
        }
        & $gitCommand.Source -C $brownfieldProjectRoot config user.name 'Brownfield Fixture'
        & $gitCommand.Source -C $brownfieldProjectRoot config user.email 'brownfield-fixture@example.invalid'
        & $gitCommand.Source -C $brownfieldProjectRoot add -- 'existing-file.txt'
        & $gitCommand.Source -C $brownfieldProjectRoot commit --quiet -m 'fixture baseline'
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not commit the disposable brownfield Git baseline.'
        }
        & $gitCommand.Source -C $brownfieldProjectRoot remote add origin 'https://example.invalid/existing-application.git'
        [System.IO.File]::AppendAllText(
            $brownfieldSentinel,
            "preserve this local change`r`n",
            $utf8NoBom)
        $brownfieldGitHead = [string]@(& $gitCommand.Source --no-optional-locks -C $brownfieldProjectRoot rev-parse HEAD)[0]
        $brownfieldGitRemote = [string]@(& $gitCommand.Source --no-optional-locks -C $brownfieldProjectRoot remote get-url origin)[0]
        $brownfieldGitStatus = (@(& $gitCommand.Source --no-optional-locks -C $brownfieldProjectRoot status --porcelain=v1) -join "`n")
        foreach ($relativeGitPath in @('config', 'HEAD', 'index')) {
            $gitMetadataPath = Join-Path (Join-Path $brownfieldProjectRoot '.git') $relativeGitPath
            $brownfieldGitMetadataHashes[$relativeGitPath] = (
                Get-FileHash -Algorithm SHA256 -LiteralPath $gitMetadataPath).Hash
        }
    }
    $brownfieldBeforeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $brownfieldSentinel).Hash
    $brownfieldContinue = Invoke-Lifecycle @(
        'continue',
        '-ProjectPath', $brownfieldProjectRoot,
        '-ProcessRoot', $brownfieldProcessRoot,
        '-Owner', 'Brownfield Fixture Owner',
        '-BoilerplatePath', $boilerplate
    )
    Require-ExitCode -Execution $brownfieldContinue -Expected 0 -Label 'brownfield continue initializes adoption'
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $brownfieldSentinel).Hash -ne $brownfieldBeforeHash) {
        throw 'Brownfield continue changed an existing application file.'
    }
    if (Test-Path -LiteralPath (Join-Path $brownfieldProjectRoot 'LIFECYCLE_STATE.json')) {
        throw 'Brownfield continue wrote lifecycle state into the existing application.'
    }
    $brownfieldStatePath = Join-Path $brownfieldProcessRoot 'LIFECYCLE_STATE.json'
    $brownfieldStateJson = Get-Content -Raw -Encoding UTF8 -LiteralPath $brownfieldStatePath
    $brownfieldState = $brownfieldStateJson | ConvertFrom-Json
    if ($brownfieldState.initiativeMode -ne 'brownfield' -or
        [System.IO.Path]::GetFullPath([string]$brownfieldState.applicationRoot) -ne
            [System.IO.Path]::GetFullPath($brownfieldProjectRoot) -or
        $brownfieldState.currentPrompt -ne '01' -or
        $brownfieldState.repositoryBaseline.status -notin @('captured', 'not_detected')) {
        throw 'Brownfield lifecycle state did not preserve mode, application root, baseline and prompt 01.'
    }
    if ($null -ne $gitCommand -and
        ($brownfieldState.repositoryBaseline.status -ne 'captured' -or
            $brownfieldState.repositoryBaseline.head -ne $brownfieldGitHead -or
            $brownfieldState.repositoryBaseline.dirty -ne $true -or
            [int]$brownfieldState.repositoryBaseline.remoteCount -ne 1)) {
        throw 'Brownfield lifecycle did not capture the existing dirty Git baseline.'
    }
    $brownfieldPacket = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $brownfieldProcessRoot 'NEXT_TASK.md')
    if ($brownfieldPacket -notmatch 'Initiative mode: brownfield' -or
        $brownfieldPacket -notmatch [regex]::Escape($brownfieldProjectRoot)) {
        throw 'Brownfield NEXT_TASK.md does not identify the mode and existing application.'
    }
    $brownfieldContinueAgain = Invoke-Lifecycle @(
        'continue',
        '-ProjectPath', $brownfieldProjectRoot,
        '-ProcessRoot', $brownfieldProcessRoot,
        '-BoilerplatePath', $boilerplate
    )
    Require-ExitCode -Execution $brownfieldContinueAgain -Expected 0 -Label 'brownfield continue resolves existing process'
    if ((Get-Content -Raw -Encoding UTF8 -LiteralPath $brownfieldStatePath) -ne $brownfieldStateJson) {
        throw 'Resolving an existing brownfield lifecycle mutated its durable state.'
    }
    $brownfieldContinueByProcess = Invoke-Lifecycle @(
        'continue',
        '-ProjectPath', $brownfieldProcessRoot,
        '-BoilerplatePath', $boilerplate
    )
    Require-ExitCode -Execution $brownfieldContinueByProcess -Expected 0 -Label 'continue accepts lifecycle root directly'
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $brownfieldSentinel).Hash -ne $brownfieldBeforeHash) {
        throw 'Resolving the brownfield lifecycle changed the existing application.'
    }
    if ($null -ne $gitCommand) {
        foreach ($relativeGitPath in @('config', 'HEAD', 'index')) {
            $gitMetadataPath = Join-Path (Join-Path $brownfieldProjectRoot '.git') $relativeGitPath
            $metadataHashAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath $gitMetadataPath).Hash
            if ($metadataHashAfter -ne $brownfieldGitMetadataHashes[$relativeGitPath]) {
                throw "Brownfield continue changed .git/$relativeGitPath."
            }
        }
        $brownfieldGitHeadAfter = [string]@(& $gitCommand.Source --no-optional-locks -C $brownfieldProjectRoot rev-parse HEAD)[0]
        $brownfieldGitRemoteAfter = [string]@(& $gitCommand.Source --no-optional-locks -C $brownfieldProjectRoot remote get-url origin)[0]
        $brownfieldGitStatusAfter = (@(& $gitCommand.Source --no-optional-locks -C $brownfieldProjectRoot status --porcelain=v1) -join "`n")
        if ($brownfieldGitHeadAfter -ne $brownfieldGitHead -or
            $brownfieldGitRemoteAfter -ne $brownfieldGitRemote -or
            $brownfieldGitStatusAfter -ne $brownfieldGitStatus) {
            throw 'Brownfield continue changed HEAD, remote or local working-tree changes.'
        }
    }
    $otherBrownfieldProject = Join-Path $brownfieldFixtureRoot 'other-application'
    New-Item -ItemType Directory -Path $otherBrownfieldProject | Out-Null
    $mismatchedContinue = Invoke-Lifecycle @(
        'continue',
        '-ProjectPath', $otherBrownfieldProject,
        '-ProcessRoot', $brownfieldProcessRoot,
        '-BoilerplatePath', $boilerplate
    )
    if ($mismatchedContinue.ExitCode -eq 0) {
        throw 'Continue reused a lifecycle that belongs to another application.'
    }
    $corruptBrownfieldState = $brownfieldStateJson | ConvertFrom-Json
    $corruptBrownfieldState.applicationRoot = $brownfieldProcessRoot
    [System.IO.File]::WriteAllText(
        $brownfieldStatePath,
        ($corruptBrownfieldState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $corruptBrownfieldValidate = Invoke-Lifecycle @(
        'validate',
        '-ProcessRoot', $brownfieldProcessRoot
    )
    if ($corruptBrownfieldValidate.ExitCode -eq 0) {
        throw 'Validate accepted a brownfield applicationRoot nested in processRoot.'
    }
    [System.IO.File]::WriteAllText($brownfieldStatePath, $brownfieldStateJson, $utf8NoBom)
    $results.Add('brownfield adoption -> isolated, idempotent and application-preserving')

    New-Item -ItemType Directory -Path $brownfieldCollisionRoot | Out-Null
    $collisionSentinel = Join-Path $brownfieldCollisionRoot 'do-not-overwrite.txt'
    [System.IO.File]::WriteAllText($collisionSentinel, "occupied`r`n", $utf8NoBom)
    $collisionContinue = Invoke-Lifecycle @(
        'continue',
        '-ProjectPath', $brownfieldProjectRoot,
        '-ProcessRoot', $brownfieldCollisionRoot,
        '-BoilerplatePath', $boilerplate
    )
    if ($collisionContinue.ExitCode -eq 0 -or
        -not (Test-Path -LiteralPath $collisionSentinel -PathType Leaf)) {
        throw 'Brownfield continue overwrote or accepted an occupied process root.'
    }
    $insideBoilerplateProcess = Join-Path $brownfieldFixtureRoot 'must-not-adopt-boilerplate'
    $insideBoilerplateAdopt = Invoke-Lifecycle @(
        'adopt',
        '-ProjectPath', $boilerplate,
        '-ProcessRoot', $insideBoilerplateProcess,
        '-Owner', 'Fixture Owner',
        '-BoilerplatePath', $boilerplate
    )
    if ($insideBoilerplateAdopt.ExitCode -eq 0 -or
        (Test-Path -LiteralPath $insideBoilerplateProcess)) {
        throw 'Adopt accepted BoilerplatePath as the existing application.'
    }
    $missingProjectPath = Join-Path $brownfieldFixtureRoot 'missing-application'
    $missingProcessPath = Join-Path $brownfieldFixtureRoot 'must-not-create-for-missing'
    $missingContinue = Invoke-Lifecycle @(
        'continue',
        '-ProjectPath', $missingProjectPath,
        '-ProcessRoot', $missingProcessPath,
        '-BoilerplatePath', $boilerplate
    )
    if ($missingContinue.ExitCode -eq 0 -or (Test-Path -LiteralPath $missingProcessPath)) {
        throw 'Continue initialized a lifecycle for a missing application path.'
    }
    if ($null -ne $gitCommand) {
        $monorepoRoot = Join-Path $brownfieldFixtureRoot 'existing-monorepo'
        $monorepoProjectRoot = Join-Path $monorepoRoot 'application'
        $monorepoProcessRoot = Join-Path $monorepoRoot 'lifecycle-process'
        New-Item -ItemType Directory -Path $monorepoProjectRoot | Out-Null
        [System.IO.File]::WriteAllText(
            (Join-Path $monorepoProjectRoot 'app.txt'),
            "monorepo application`r`n",
            $utf8NoBom)
        & $gitCommand.Source -C $monorepoRoot init --quiet --initial-branch=main
        & $gitCommand.Source -C $monorepoRoot config user.name 'Monorepo Fixture'
        & $gitCommand.Source -C $monorepoRoot config user.email 'monorepo-fixture@example.invalid'
        & $gitCommand.Source -C $monorepoRoot add --all
        & $gitCommand.Source -C $monorepoRoot commit --quiet -m 'monorepo fixture'
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not create the disposable monorepo fixture.'
        }
        $monorepoContinue = Invoke-Lifecycle @(
            'continue',
            '-ProjectPath', $monorepoProjectRoot,
            '-ProcessRoot', $monorepoProcessRoot,
            '-BoilerplatePath', $boilerplate
        )
        if ($monorepoContinue.ExitCode -eq 0 -or (Test-Path -LiteralPath $monorepoProcessRoot)) {
            throw 'Continue created ProcessRoot inside the existing Git repository tree.'
        }
    }
    $results.Add('brownfield collisions, boilerplate adoption and missing path -> blocked')

    $disposableCatalogRoot = Join-Path $brownfieldFixtureRoot 'catalog-copy'
    Copy-Item -LiteralPath $CatalogRoot -Destination $disposableCatalogRoot -Recurse
    $naturalProjectRoot = Join-Path $brownfieldFixtureRoot 'natural-existing-app'
    New-Item -ItemType Directory -Path $naturalProjectRoot | Out-Null
    [System.IO.File]::WriteAllText(
        (Join-Path $naturalProjectRoot 'app.txt'),
        "natural-language fixture`r`n",
        $utf8NoBom)
    $naturalEntryPoint = Join-Path $disposableCatalogRoot 'software-lifecycle.ps1'
    $naturalContinue = Invoke-Lifecycle `
        -ScriptPath $naturalEntryPoint `
        -Arguments @(
            'continue',
            '-ProjectPath', $naturalProjectRoot,
            '-BoilerplatePath', $boilerplate
        )
    Require-ExitCode -Execution $naturalContinue -Expected 0 -Label 'path-only continue uses deterministic process root'
    $naturalSlug = Split-Path $naturalProjectRoot -Leaf
    $naturalProcessRoot = Join-Path $brownfieldFixtureRoot "SoftwareProcesses\$naturalSlug"
    $naturalStatePath = Join-Path $naturalProcessRoot 'LIFECYCLE_STATE.json'
    if (-not (Test-Path -LiteralPath $naturalStatePath -PathType Leaf)) {
        throw 'Path-only continue did not create the deterministic isolated lifecycle.'
    }
    $naturalState = Get-Content -Raw -Encoding UTF8 -LiteralPath $naturalStatePath | ConvertFrom-Json
    if ($naturalState.initiativeMode -ne 'brownfield' -or
        $null -ne $naturalState.productOwner -or
        [System.IO.Path]::GetFullPath([string]$naturalState.applicationRoot) -ne
            [System.IO.Path]::GetFullPath($naturalProjectRoot)) {
        throw 'Path-only continue did not bind the application while preserving the pending owner.'
    }
    $naturalContinueAgain = Invoke-Lifecycle `
        -ScriptPath $naturalEntryPoint `
        -Arguments @(
            'continue',
            '-ProjectPath', $naturalProjectRoot,
            '-BoilerplatePath', $boilerplate
        )
    Require-ExitCode -Execution $naturalContinueAgain -Expected 0 -Label 'path-only continue resolves deterministic process'
    $results.Add('natural path-only continue -> deterministic adoption and resolution')

    if ($BrownfieldOnly) {
        Write-Host 'PASS: brownfield lifecycle test.' -ForegroundColor Green
        $results | ForEach-Object { Write-Host " - $_" }
        return
    }

    $forbiddenRoot = Join-Path $boilerplate ("forbidden-lifecycle-" + [Guid]::NewGuid().ToString('N'))
    $forbiddenStart = Invoke-Lifecycle @(
        'start',
        '-Name', 'forbidden-lifecycle',
        '-Owner', 'Fixture Owner',
        '-ProcessRoot', $forbiddenRoot,
        '-BoilerplatePath', $boilerplate
    )
    if ($forbiddenStart.ExitCode -eq 0 -or (Test-Path -LiteralPath $forbiddenRoot)) {
        throw 'Start accepted or created a process root inside BoilerplatePath.'
    }
    $results.Add('process root inside boilerplate -> blocked')

    $linkItemType = $(if ($IsWindows) { 'Junction' } else { 'SymbolicLink' })
    New-Item -ItemType $linkItemType -Path $junctionRoot -Target $boilerplate | Out-Null
    $junctionProcessRoot = Join-Path $junctionRoot ("junction-child-" + [Guid]::NewGuid().ToString('N'))
    $junctionStart = Invoke-Lifecycle @(
        'start',
        '-Name', 'junction-lifecycle',
        '-Owner', 'Fixture Owner',
        '-ProcessRoot', $junctionProcessRoot,
        '-BoilerplatePath', $boilerplate
    )
    if ($junctionStart.ExitCode -eq 0 -or (Test-Path -LiteralPath $junctionProcessRoot)) {
        throw 'Start accepted a junction that resolves ProcessRoot inside BoilerplatePath.'
    }
    $results.Add('junction into boilerplate -> blocked')

    $start = Invoke-Lifecycle @(
        'start',
        '-Name', 'lifecycle-e2e',
        '-Owner', 'Fixture Owner',
        '-ProcessRoot', $fixtureRoot,
        '-BoilerplatePath', $boilerplate
    )
    Require-ExitCode -Execution $start -Expected 0 -Label 'start'

    foreach ($required in @(
        'LIFECYCLE_STATE.json',
        'LIFECYCLE_GATE_EVIDENCE.json',
        'NEXT_TASK.md',
        'PROCESS_MANIFEST.json',
        'QUALITY_GATES.md',
        'HELP_AND_ACADEMY.md',
        'CHANGE_CONTROL.md',
        'CLAUDE.md',
        '.agents\skills\advance-app-continue\SKILL.md'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $fixtureRoot $required))) {
            throw "Start did not create required path: $required"
        }
    }

    $validateInitial = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    Require-ExitCode -Execution $validateInitial -Expected 0 -Label 'initial validate'

    $statePath = Join-Path $fixtureRoot 'LIFECYCLE_STATE.json'
    $originalStateJson = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath
    $startedState = $originalStateJson | ConvertFrom-Json
    if ([System.IO.Path]::GetFullPath([string]$startedState.boilerplatePath) -ne
        [System.IO.Path]::GetFullPath($boilerplate)) {
        throw 'Start did not persist the exact resolved BoilerplatePath.'
    }
    $instanceContext = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'APP_CONTEXT.md')
    if (-not $instanceContext.Contains("| Raiz do BoilerPlateAdvance | $boilerplate | confirmado | Sistema de ficheiros |")) {
        throw 'Start did not confirm the resolved BoilerplatePath in APP_CONTEXT.md.'
    }
    $nextTask = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'NEXT_TASK.md')
    if (-not $nextTask.Contains('[PASTA_ORIGEM_BOILERPLATE]')) {
        throw 'Prompt 01 no longer resolves the boilerplate through the lifecycle context placeholder.'
    }
    if ($nextTask -notmatch 'Execution profile:\s*deep' -or
        $nextTask -notmatch '## Required context' -or
        $nextTask -notmatch 'EXECUTION_CONTRACT\.md.*SHA-256' -or
        $nextTask -notmatch 'PRODUCT_EXCELLENCE\.md.*SHA-256' -or
        $nextTask -notmatch 'at most\s+one immediately related prompt') {
        throw 'NEXT_TASK.md does not expose the proportional profile, hashed context route and bounded continuation rule.'
    }

    $sourceManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $CatalogRoot 'PROCESS_MANIFEST.json') |
        ConvertFrom-Json
    $staleVersion = '2026-01-01.1'
    $staleManifestPath = Join-Path $fixtureRoot 'PROCESS_MANIFEST.json'
    $staleManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $staleManifestPath | ConvertFrom-Json
    $staleManifest.catalogVersion = $staleVersion
    [System.IO.File]::WriteAllText(
        $staleManifestPath,
        ($staleManifest | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $staleState = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
    $staleState.catalogVersion = $staleVersion
    [System.IO.File]::WriteAllText(
        $statePath,
        ($staleState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $gateEvidencePath = Join-Path $fixtureRoot 'LIFECYCLE_GATE_EVIDENCE.json'
    $staleGateEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath | ConvertFrom-Json
    $staleGateEvidence.catalogVersion = $staleVersion
    [System.IO.File]::WriteAllText(
        $gateEvidencePath,
        ($staleGateEvidence | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $contextBeforeUpgrade = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'APP_CONTEXT.md')
    [System.IO.File]::WriteAllText(
        (Join-Path $fixtureRoot 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md'),
        "# stale prompt 04`n",
        $utf8NoBom)

    $candidateStateBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath
    $candidateManifestBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath $staleManifestPath
    $candidateUpgrade = Invoke-RawLifecycle @('upgrade', '-ProcessRoot', $fixtureRoot)
    if ($candidateUpgrade.ExitCode -eq 0 -or
        $candidateUpgrade.Output -notmatch 'only accepts a stable catalog' -or
        (Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath) -ne $candidateStateBefore -or
        (Get-Content -Raw -Encoding UTF8 -LiteralPath $staleManifestPath) -ne $candidateManifestBefore) {
        throw 'Catalog upgrade accepted a candidate source or mutated the instance before refusing it.'
    }
    $results.Add('candidate catalog upgrade -> refused without mutation')

    New-Item -ItemType Directory -Path $stableCatalogRoot | Out-Null
    foreach ($directory in @('prompts', 'scripts', '.agents')) {
        Copy-Item -LiteralPath (Join-Path $CatalogRoot $directory) -Destination $stableCatalogRoot -Recurse
    }
    foreach ($file in @(
        'AGENTS.md', 'CHANGE_CONTROL.md', 'CLAUDE.md', 'EXECUTION_CONTRACT.md',
        'EVALUATION_IMPACT_MAP.json', 'HELP_AND_ACADEMY.md', 'PILOT_APPROVAL.md',
        'PRODUCT_EXCELLENCE.md', 'PROMPT_EVALUATION.md', 'QUALITY_GATES.md',
        'PROCESS_MANIFEST.json', 'README.md', 'START_HERE.md', 'software-lifecycle.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $CatalogRoot $file) -Destination $stableCatalogRoot
    }
    $stableManifestPath = Join-Path $stableCatalogRoot 'PROCESS_MANIFEST.json'
    $stableManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $stableManifestPath | ConvertFrom-Json
    $stableManifest.releaseChannel = 'stable'
    [System.IO.File]::WriteAllText(
        $stableManifestPath,
        ($stableManifest | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    Copy-Item -LiteralPath (Join-Path $CatalogRoot 'pilot/fixtures/implementation-readiness-gate/valid-pilot-approval.md') `
        -Destination (Join-Path $stableCatalogRoot 'PILOT_APPROVAL.md') -Force

    $upgrade = Invoke-RawLifecycle -Arguments @('upgrade', '-ProcessRoot', $fixtureRoot) `
        -ScriptPath (Join-Path $stableCatalogRoot 'software-lifecycle.ps1')
    Require-ExitCode -Execution $upgrade -Expected 0 -Label 'approved stable catalog upgrade'
    $upgradedState = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
    $upgradedManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $staleManifestPath | ConvertFrom-Json
    $upgradedGateEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath | ConvertFrom-Json
    $upgradedPrompt04 = Get-Content -Raw -Encoding UTF8 -LiteralPath `
        (Join-Path $fixtureRoot 'prompts/01-preparacao-e-definicao/04-identificar-requisitos-em-falta.md')
    $contextAfterUpgrade = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'APP_CONTEXT.md')
    if ([string]$upgradedState.catalogVersion -ne [string]$sourceManifest.catalogVersion -or
        [string]$upgradedManifest.catalogVersion -ne [string]$sourceManifest.catalogVersion -or
        [string]$upgradedGateEvidence.catalogVersion -ne [string]$sourceManifest.catalogVersion -or
        -not $upgradedPrompt04.Contains('Triagem de pendências sem ciclo de prompts') -or
        $contextAfterUpgrade -ne $contextBeforeUpgrade) {
        throw 'Compatible upgrade did not synchronize process files while preserving product context.'
    }
    $validateUpgrade = Invoke-RawLifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    Require-ExitCode -Execution $validateUpgrade -Expected 0 -Label 'upgraded lifecycle validate'
    $results.Add('stable catalog upgrade -> process synchronized and product context preserved')

    $futureVersion = '2099-01-01.1'
    $futureState = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
    $futureManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $staleManifestPath | ConvertFrom-Json
    $futureGateEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath | ConvertFrom-Json
    $futureState.catalogVersion = $futureVersion
    $futureManifest.catalogVersion = $futureVersion
    $futureGateEvidence.catalogVersion = $futureVersion
    [System.IO.File]::WriteAllText(
        $statePath,
        ($futureState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    [System.IO.File]::WriteAllText(
        $staleManifestPath,
        ($futureManifest | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    [System.IO.File]::WriteAllText(
        $gateEvidencePath,
        ($futureGateEvidence | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $futureStateBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath
    $futureManifestBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath $staleManifestPath
    $futureGateEvidenceBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath
    $downgrade = Invoke-RawLifecycle -Arguments @('upgrade', '-ProcessRoot', $fixtureRoot) `
        -ScriptPath (Join-Path $stableCatalogRoot 'software-lifecycle.ps1')
    if ($downgrade.ExitCode -eq 0 -or
        (Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath) -ne $futureStateBefore -or
        (Get-Content -Raw -Encoding UTF8 -LiteralPath $staleManifestPath) -ne $futureManifestBefore -or
        (Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath) -ne $futureGateEvidenceBefore) {
        throw 'Catalog upgrade accepted a downgrade or mutated the instance before refusing it.'
    }
    $futureState.catalogVersion = [string]$sourceManifest.catalogVersion
    $futureManifest.catalogVersion = [string]$sourceManifest.catalogVersion
    $futureGateEvidence.catalogVersion = [string]$sourceManifest.catalogVersion
    [System.IO.File]::WriteAllText(
        $statePath,
        ($futureState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    [System.IO.File]::WriteAllText(
        $staleManifestPath,
        ($futureManifest | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    [System.IO.File]::WriteAllText(
        $gateEvidencePath,
        ($futureGateEvidence | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $results.Add('catalog downgrade -> refused without mutation')

    $missingLedgerRecord = Invoke-RawLifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '01',
        '-Result', 'completed', '-Evidence', 'fixture://missing-ledger'
    )
    if ($missingLedgerRecord.ExitCode -eq 0) {
        throw 'record completed accepted a prompt without work-start.'
    }
    $workStart = Invoke-RawLifecycle @(
        'work-start', '-ProcessRoot', $fixtureRoot
    )
    Require-ExitCode -Execution $workStart -Expected 0 -Label 'work-start'
    $checkpoint = Invoke-RawLifecycle @(
        'checkpoint', '-ProcessRoot', $fixtureRoot,
        '-GoalId', 'GOAL-001',
        '-CheckpointStatus', 'completed',
        '-Evidence', 'fixture://baseline-inspected'
    )
    Require-ExitCode -Execution $checkpoint -Expected 0 -Label 'goal checkpoint'
    $verification = Invoke-RawLifecycle @(
        'verify', '-ProcessRoot', $fixtureRoot,
        '-VerificationKind', 'command',
        '-VerifyCommand', 'fixture://targeted-check',
        '-VerifyExitCode', '0',
        '-VerifyEvidence', 'fixture://targeted-check-pass'
    )
    Require-ExitCode -Execution $verification -Expected 0 -Label 'work verification'
    $incompleteLedgerRecord = Invoke-RawLifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '01',
        '-Result', 'completed', '-Evidence', 'fixture://incomplete-ledger'
    )
    if ($incompleteLedgerRecord.ExitCode -eq 0) {
        throw 'record completed accepted incomplete goals and verification.'
    }
    $findingAdd = Invoke-RawLifecycle @(
        'finding-add', '-ProcessRoot', $fixtureRoot,
        '-Title', 'Seeded task-ledger regression',
        '-Severity', 'high',
        '-Source', 'fixture-adversarial-review',
        '-Location', 'software-lifecycle.ps1',
        '-Evidence', 'fixture://finding-open'
    )
    Require-ExitCode -Execution $findingAdd -Expected 0 -Label 'finding-add'
    $openFindingGate = Invoke-RawLifecycle @(
        'finding-gate', '-ProcessRoot', $fixtureRoot
    )
    if ($openFindingGate.ExitCode -eq 0) {
        throw 'finding-gate accepted an open finding.'
    }
    $openFindingCloseout = Invoke-RawLifecycle @(
        'closeout', '-ProcessRoot', $fixtureRoot,
        '-Evidence', 'fixture://work-closeout',
        '-VerificationKind', 'command',
        '-VerifyCommand', 'fixture://verify-ledger',
        '-VerifyExitCode', '0',
        '-VerifyEvidence', 'fixture://verification-ledger',
        '-ReviewEvidence', 'fixture://review-ledger'
    )
    if ($openFindingCloseout.ExitCode -eq 0) {
        throw 'closeout accepted an open finding.'
    }
    $findingResolve = Invoke-RawLifecycle @(
        'finding-resolve', '-ProcessRoot', $fixtureRoot,
        '-FindingId', 'FIND-001',
        '-ResolutionEvidence', 'fixture://finding-fixed',
        '-VerifyCommand', 'fixture://verify-finding',
        '-VerifyExitCode', '0',
        '-VerifyEvidence', 'fixture://finding-regression-pass'
    )
    Require-ExitCode -Execution $findingResolve -Expected 0 -Label 'finding-resolve'
    $closedLedger = Invoke-RawLifecycle @(
        'closeout', '-ProcessRoot', $fixtureRoot,
        '-Evidence', 'fixture://work-closeout',
        '-VerificationKind', 'command',
        '-VerifyCommand', 'fixture://verify-ledger',
        '-VerifyExitCode', '0',
        '-VerifyEvidence', 'fixture://verification-ledger',
        '-ReviewEvidence', 'fixture://review-ledger'
    )
    Require-ExitCode -Execution $closedLedger -Expected 0 -Label 'work closeout'
    $closedFindingGate = Invoke-RawLifecycle @(
        'finding-gate', '-ProcessRoot', $fixtureRoot
    )
    Require-ExitCode -Execution $closedFindingGate -Expected 0 -Label 'closed finding gate'

    $closedLedgerStateJson = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath
    $corruptLedgerState = $closedLedgerStateJson | ConvertFrom-Json
    $corruptLedgerState.activeWorkAttemptId = 'ATT-missing'
    [System.IO.File]::WriteAllText(
        $statePath,
        ($corruptLedgerState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $corruptLedgerValidate = Invoke-RawLifecycle @(
        'validate', '-ProcessRoot', $fixtureRoot
    )
    if ($corruptLedgerValidate.ExitCode -eq 0) {
        throw 'validate accepted a corrupt activeWorkAttemptId.'
    }
    [System.IO.File]::WriteAllText($statePath, $closedLedgerStateJson, $utf8NoBom)
    $completedLedgerRecord = Invoke-RawLifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '01',
        '-Result', 'completed', '-Evidence', 'fixture://closed-ledger'
    )
    Require-ExitCode -Execution $completedLedgerRecord -Expected 0 -Label 'record with closed ledger'
    [System.IO.File]::WriteAllText($statePath, $originalStateJson, $utf8NoBom)
    $results.Add('task ledger goals, verification, review and findings gate -> enforced')

    $corruptState = $originalStateJson | ConvertFrom-Json
    $corruptState.catalogVersion = 'CORRUPTED-CATALOG'
    $corruptState.processRoot = 'C:\wrong\root'
    $corruptState.prompts.'01'.status = 'invented-status'
    [System.IO.File]::WriteAllText(
        $statePath,
        ($corruptState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $corruptValidate = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    $corruptNext = Invoke-Lifecycle @('next', '-ProcessRoot', $fixtureRoot)
    $corruptRecord = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '01',
        '-Result', 'completed', '-Evidence', 'fixture://must-not-be-recorded'
    )
    if ($corruptValidate.ExitCode -eq 0 -or
        $corruptNext.ExitCode -eq 0 -or
        $corruptRecord.ExitCode -eq 0) {
        throw 'validate, next or a mutator accepted a materially corrupted lifecycle state.'
    }
    [System.IO.File]::WriteAllText($statePath, $originalStateJson, $utf8NoBom)
    $results.Add('corrupted catalog/root/status -> validate, next and mutator blocked')

    $invalidSliceState = $originalStateJson | ConvertFrom-Json
    $invalidSliceState.slices = @([pscustomobject][ordered]@{
        id = 'INVALID-001'
        kind = 'banana'
        surface = 'desktop'
        requirements = 'FR-INVALID'
        acceptanceCriteria = 'invalid fixture'
        outOfScope = 'none'
        evidence = 'fixture://invalid-slice'
        status = 'magical'
    })
    $invalidSliceState.activeSlice = $null
    [System.IO.File]::WriteAllText(
        $statePath,
        ($invalidSliceState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $invalidSliceValidate = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    $invalidSliceRecord = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '01',
        '-Result', 'completed', '-Evidence', 'fixture://must-not-be-recorded'
    )
    if ($invalidSliceValidate.ExitCode -eq 0 -or $invalidSliceRecord.ExitCode -eq 0) {
        throw 'A semantically invalid slice was accepted by validate or a mutator.'
    }
    [System.IO.File]::WriteAllText($statePath, $originalStateJson, $utf8NoBom)
    $results.Add('invalid slice kind/surface/status/pointer -> validate and mutator blocked')

    $deadEndState = $originalStateJson | ConvertFrom-Json
    $deadEndState.currentPrompt = $null
    $deadEndState.status = 'waiting_decision'
    $deadEndState.nextAction = 'nonsense_dead_end'
    [System.IO.File]::WriteAllText(
        $statePath,
        ($deadEndState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $deadEndValidate = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    if ($deadEndValidate.ExitCode -eq 0) {
        throw 'A waiting_decision dead end with a disconnected ready prompt was accepted.'
    }

    $forgedCompletedState = $originalStateJson | ConvertFrom-Json
    $forgedCompletedState.currentPrompt = $null
    $forgedCompletedState.status = 'completed'
    $forgedCompletedState.nextAction = 'none'
    [System.IO.File]::WriteAllText(
        $statePath,
        ($forgedCompletedState | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    $forgedCompletedValidate = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    if ($forgedCompletedValidate.ExitCode -eq 0) {
        throw 'A forged completed lifecycle without prompt 75 and G10 was accepted.'
    }
    [System.IO.File]::WriteAllText($statePath, $originalStateJson, $utf8NoBom)
    $results.Add('dead-end waiting state and forged completion -> blocked')

    foreach ($transition in @(
        @{ Id = '01'; Next = '02' },
        @{ Id = '02'; Next = '03' },
        @{ Id = '03'; Next = '04' }
    )) {
        $record = Invoke-Lifecycle @(
            'record',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $transition.Id,
            '-Result', 'completed',
            '-Evidence', "fixture://prompt-$($transition.Id)",
            '-NextPrompt', $transition.Next
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $($transition.Id)"
    }

    $blockedGate = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '04',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-04-invalid',
        '-NextPrompt', '05'
    )
    if ($blockedGate.ExitCode -eq 0) {
        throw 'Prompt 04 crossed G01 with an incomplete product definition.'
    }
    $results.Add('invalid G01 -> blocked')

    $gateFixtureRoot = Join-Path $fixtureRoot 'pilot\fixtures\product-definition-gate'
    Copy-Item -LiteralPath (Join-Path $gateFixtureRoot 'valid-product-definition.md') `
        -Destination (Join-Path $fixtureRoot 'PRODUCT_DEFINITION.md') -Force
    Copy-Item -LiteralPath (Join-Path $gateFixtureRoot 'implementation-status.md') `
        -Destination (Join-Path $fixtureRoot 'IMPLEMENTATION_STATUS.md') -Force

    $passedGate = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '04',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-04-valid',
        '-NextPrompt', '05'
    )
    Require-ExitCode -Execution $passedGate -Expected 0 -Label 'valid G01'

    $validateAfterGate = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    Require-ExitCode -Execution $validateAfterGate -Expected 0 -Label 'post-G01 validate'

    $state = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json') | ConvertFrom-Json
    if ($state.currentPrompt -ne '05' -or $state.gates.G01.status -ne 'passed') {
        throw "Unexpected state after G01: prompt=$($state.currentPrompt), G01=$($state.gates.G01.status)"
    }
    $results.Add('state after G01 -> prompt 05')

    $next = Invoke-Lifecycle @('next', '-ProcessRoot', $fixtureRoot)
    Require-ExitCode -Execution $next -Expected 0 -Label 'next'
    $task = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'NEXT_TASK.md')
    if ($task -notmatch 'Prompt:\s*05' -or $task -notmatch '\$advance-app-continue') {
        throw 'NEXT_TASK.md does not target prompt 05 through the lifecycle skill.'
    }
    $results.Add('NEXT_TASK -> prompt 05')

    $invalidOverride = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '05',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-05-invalid-route',
        '-NextPrompt', '42'
    )
    if ($invalidOverride.ExitCode -eq 0) {
        throw 'A deterministic transition accepted an arbitrary NextPrompt override.'
    }
    $results.Add('arbitrary NextPrompt -> blocked')

    foreach ($id in @('05', '06', '07', '08', '09', '10')) {
        $record = Invoke-Lifecycle @(
            'record',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $id,
            '-Result', 'completed',
            '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }

    $gateG02 = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '11',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-11',
        '-GateId', 'G02',
        '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://architecture-approved',
        '-ApprovedBy', 'Fixture Architecture Approver'
    )
    Require-ExitCode -Execution $gateG02 -Expected 0 -Label 'G02'

    $record12 = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '12',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-12'
    )
    Require-ExitCode -Execution $record12 -Expected 0 -Label 'record 12'

    $fixtureManifestPath = Join-Path $fixtureRoot 'PROCESS_MANIFEST.json'
    $candidateFixtureManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $fixtureManifestPath | ConvertFrom-Json
    $candidateFixtureManifest.releaseChannel = 'candidate'
    [System.IO.File]::WriteAllText(
        $fixtureManifestPath,
        ($candidateFixtureManifest | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)
    Copy-Item -LiteralPath (Join-Path $CatalogRoot 'PILOT_APPROVAL.md') `
        -Destination (Join-Path $fixtureRoot 'PILOT_APPROVAL.md') -Force

    $pendingPilot = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '13',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-13',
        '-GateId', 'G03',
        '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://pilot-pending',
        '-ApprovedBy', 'Fixture Implementation Approver'
    )
    if ($pendingPilot.ExitCode -eq 0) {
        throw 'G03 accepted a pending current-version pilot.'
    }
    $results.Add('pending pilot at G03 -> blocked')

    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'pilot\fixtures\implementation-readiness-gate\valid-pilot-approval.md') `
        -Destination (Join-Path $fixtureRoot 'PILOT_APPROVAL.md') -Force
    $stableFixtureManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $fixtureManifestPath | ConvertFrom-Json
    $stableFixtureManifest.releaseChannel = 'stable'
    [System.IO.File]::WriteAllText(
        $fixtureManifestPath,
        ($stableFixtureManifest | ConvertTo-Json -Depth 30) + [Environment]::NewLine,
        $utf8NoBom)

    $gateG03 = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '13',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-13',
        '-GateId', 'G03',
        '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://pilot-approved',
        '-ApprovedBy', 'Fixture Implementation Approver'
    )
    Require-ExitCode -Execution $gateG03 -Expected 0 -Label 'G03'

    $invalidSelection = Invoke-Lifecycle @(
        'select',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '66',
        '-Evidence', 'fixture://invalid-selection'
    )
    if ($invalidSelection.ExitCode -eq 0) {
        throw 'The post-definition selector accepted a release prompt.'
    }
    $results.Add('out-of-context selection -> blocked')

    $selectFoundation = Invoke-Lifecycle @(
        'select',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '21',
        '-SliceId', 'SLICE-001',
        '-SliceKind', 'page',
        '-Surface', 'web',
        '-Requirements', 'FR-001, SEC-001',
        '-AcceptanceCriteria', 'FR-001 succeeds and SEC-001 denies unauthorized access',
        '-OutOfScope', 'billing, native application and external identity providers',
        '-Evidence', 'fixture://slice-approved'
    )
    Require-ExitCode -Execution $selectFoundation -Expected 0 -Label 'select first slice foundation'

    foreach ($id in @('21', '22', '23', '24')) {
        $record = Invoke-Lifecycle @(
            'record',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $id,
            '-Result', 'completed',
            '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }

    $selectPage = Invoke-Lifecycle @(
        'select',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '27',
        '-SliceId', 'SLICE-001',
        '-SliceKind', 'page',
        '-Surface', 'web',
        '-Requirements', 'FR-001, SEC-001',
        '-AcceptanceCriteria', 'FR-001 succeeds and SEC-001 denies unauthorized access',
        '-OutOfScope', 'billing, native application and external identity providers',
        '-Evidence', 'fixture://slice-page-approved'
    )
    Require-ExitCode -Execution $selectPage -Expected 0 -Label 'select page slice'

    foreach ($transition in @(
        @{ Id = '27'; Expected = '16' },
        @{ Id = '16'; Expected = '20' },
        @{ Id = '20'; Expected = '28' }
    )) {
        $record = Invoke-Lifecycle @(
            'record',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $transition.Id,
            '-Result', 'completed',
            '-Evidence', "fixture://prompt-$($transition.Id)"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "route $($transition.Id)"
        $routeState = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json') | ConvertFrom-Json
        if ($routeState.currentPrompt -ne $transition.Expected) {
            throw "Prompt $($transition.Id) routed to $($routeState.currentPrompt), expected $($transition.Expected)."
        }
    }

    $invalidG04 = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '28',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-28',
        '-GateId', 'G04',
        '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://quality-template',
        '-ApprovedBy', 'Fixture UX Approver'
    )
    if ($invalidG04.ExitCode -eq 0) {
        throw 'G04 accepted the pending product-quality template.'
    }
    $results.Add('pending product quality at G04 -> blocked')

    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'pilot\fixtures\product-quality-gate\valid-product-quality-baseline.md') `
        -Destination (Join-Path $fixtureRoot 'PRODUCT_QUALITY_BASELINE.md') -Force

    $gateG04 = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '28',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-28',
        '-GateId', 'G04',
        '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://quality-approved',
        '-ApprovedBy', 'Fixture UX Approver'
    )
    Require-ExitCode -Execution $gateG04 -Expected 0 -Label 'G04'

    $finalState = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json') | ConvertFrom-Json
    if ($finalState.status -ne 'waiting_decision' -or
        $finalState.gates.G04.status -ne 'passed' -or
        $finalState.activeSlice.status -ne 'completed') {
        throw 'First-slice completion did not persist its gate, decision state and evidence.'
    }
    $results.Add('first professional slice -> completed and G04 passed')

    $earlyGlobal = Invoke-Lifecycle @(
        'select',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '25',
        '-Evidence', 'fixture://premature-global-exit'
    )
    if ($earlyGlobal.ExitCode -eq 0) {
        throw 'Global completion started before surface/page applicability decisions were resolved.'
    }
    $results.Add('early prompt 25 exit -> blocked')

    foreach ($id in @('14', '15', '17', '18', '19', '29', '30', '31')) {
        $decision = Invoke-Lifecycle @(
            'decide',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $id,
            '-Result', 'not_applicable',
            '-Evidence', "fixture://scope-excludes-$id"
        )
        Require-ExitCode -Execution $decision -Expected 0 -Label "decide $id"
    }

    $selectGlobal = Invoke-Lifecycle @(
        'select',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '25',
        '-Evidence', 'fixture://must-slices-complete'
    )
    Require-ExitCode -Execution $selectGlobal -Expected 0 -Label 'select global requirements'

    foreach ($id in @('25', '26')) {
        $record = Invoke-Lifecycle @(
            'record',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $id,
            '-Result', 'completed',
            '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }

    $earlySecurity = Invoke-Lifecycle @(
        'select',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '41',
        '-Evidence', 'fixture://premature-security-exit'
    )
    if ($earlySecurity.ExitCode -eq 0) {
        throw 'Security core started before optional capability decisions were resolved.'
    }
    $results.Add('early prompt 41 exit -> blocked')

    foreach ($id in 32..40 | ForEach-Object { '{0:D2}' -f $_ }) {
        $decision = Invoke-Lifecycle @(
            'decide',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $id,
            '-Result', 'not_applicable',
            '-Evidence', "fixture://scope-excludes-$id"
        )
        Require-ExitCode -Execution $decision -Expected 0 -Label "decide $id"
    }

    $gateG05 = Invoke-Lifecycle @(
        'gate',
        '-ProcessRoot', $fixtureRoot,
        '-GateId', 'G05',
        '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://must-journeys-approved',
        '-ApprovedBy', 'Fixture Product Approver'
    )
    Require-ExitCode -Execution $gateG05 -Expected 0 -Label 'G05'

    $selectSecurity = Invoke-Lifecycle @(
        'select',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '41',
        '-Evidence', 'fixture://security-required'
    )
    Require-ExitCode -Execution $selectSecurity -Expected 0 -Label 'select security'

    $record41 = Invoke-Lifecycle @(
        'record',
        '-ProcessRoot', $fixtureRoot,
        '-PromptId', '41',
        '-Result', 'completed',
        '-Evidence', 'fixture://prompt-41'
    )
    Require-ExitCode -Execution $record41 -Expected 0 -Label 'route 41'

    $postG05State = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json') | ConvertFrom-Json
    if ($postG05State.currentPrompt -ne '42' -or $postG05State.gates.G05.status -ne 'passed') {
        throw "G05/security routing failed: prompt=$($postG05State.currentPrompt), G05=$($postG05State.gates.G05.status)"
    }
    $results.Add('applicability decisions + G05 + route 41 -> 42')

    foreach ($id in @('42', '43', '44', '45', '46')) {
        $record = Invoke-Lifecycle @(
            'record',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $id,
            '-Result', 'completed',
            '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }
    foreach ($id in @('47', '48', '49')) {
        $decision = Invoke-Lifecycle @(
            'decide',
            '-ProcessRoot', $fixtureRoot,
            '-PromptId', $id,
            '-Result', 'not_applicable',
            '-Evidence', "fixture://scope-excludes-$id"
        )
        Require-ExitCode -Execution $decision -Expected 0 -Label "decide $id"
    }
    $select50 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '50',
        '-Evidence', 'fixture://hardening-required'
    )
    Require-ExitCode -Execution $select50 -Expected 0 -Label 'select hardening'
    foreach ($id in @('50', '51')) {
        $record = Invoke-Lifecycle @(
            'record', '-ProcessRoot', $fixtureRoot, '-PromptId', $id,
            '-Result', 'completed', '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }
    $decide52 = Invoke-Lifecycle @(
        'decide', '-ProcessRoot', $fixtureRoot, '-PromptId', '52',
        '-Result', 'not_applicable', '-Evidence', 'fixture://scope-excludes-50'
    )
    Require-ExitCode -Execution $decide52 -Expected 0 -Label 'decide 52'
    $select53 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '53',
        '-Evidence', 'fixture://quality-required'
    )
    Require-ExitCode -Execution $select53 -Expected 0 -Label 'select quality core'
    foreach ($id in @('53', '54', '55')) {
        $record = Invoke-Lifecycle @(
            'record', '-ProcessRoot', $fixtureRoot, '-PromptId', $id,
            '-Result', 'completed', '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }
    $invalidG06 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '56',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-56',
        '-GateId', 'G06', '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://unstructured-hardening',
        '-ApprovedBy', 'Fixture Security Approver'
    )
    if ($invalidG06.ExitCode -eq 0) {
        throw 'G06 accepted pending/unstructured gate evidence.'
    }
    $results.Add('pending structured G06 evidence -> blocked')
    Copy-Item -LiteralPath (Join-Path $fixtureRoot 'pilot\fixtures\lifecycle-gates\valid-lifecycle-gate-evidence.json') `
        -Destination (Join-Path $fixtureRoot 'LIFECYCLE_GATE_EVIDENCE.json') -Force
    $gateG06 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '56',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-56',
        '-GateId', 'G06', '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://hardening-approved',
        '-ApprovedBy', 'Fixture Security Approver'
    )
    Require-ExitCode -Execution $gateG06 -Expected 0 -Label 'G06'

    $select57 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '57',
        '-Evidence', 'fixture://delivery-required'
    )
    Require-ExitCode -Execution $select57 -Expected 0 -Label 'select delivery'
    $record57 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '57',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-57'
    )
    Require-ExitCode -Execution $record57 -Expected 0 -Label 'record 57'
    foreach ($id in @('58', '59')) {
        $decision = Invoke-Lifecycle @(
            'decide', '-ProcessRoot', $fixtureRoot, '-PromptId', $id,
            '-Result', 'not_applicable', '-Evidence', "fixture://scope-excludes-$id"
        )
        Require-ExitCode -Execution $decision -Expected 0 -Label "decide $id"
    }
    $select60 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '60',
        '-Evidence', 'fixture://operations-required'
    )
    Require-ExitCode -Execution $select60 -Expected 0 -Label 'select operations'
    foreach ($id in @('60', '61')) {
        $record = Invoke-Lifecycle @(
            'record', '-ProcessRoot', $fixtureRoot, '-PromptId', $id,
            '-Result', 'completed', '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }
    $gateG07 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '62',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-62',
        '-GateId', 'G07', '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://operations-approved',
        '-ApprovedBy', 'Fixture Operations Approver'
    )
    Require-ExitCode -Execution $gateG07 -Expected 0 -Label 'G07'

    $select63 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '63',
        '-Evidence', 'fixture://acceptance-required'
    )
    Require-ExitCode -Execution $select63 -Expected 0 -Label 'select acceptance'
    foreach ($id in @('63', '64')) {
        $record = Invoke-Lifecycle @(
            'record', '-ProcessRoot', $fixtureRoot, '-PromptId', $id,
            '-Result', 'completed', '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }
    $lifecycleEvidencePath = Join-Path $fixtureRoot 'LIFECYCLE_GATE_EVIDENCE.json'
    $validEvidenceBeforeG08 = Get-Content -Raw -Encoding UTF8 -LiteralPath $lifecycleEvidencePath
    $invalidG08Evidence = $validEvidenceBeforeG08 | ConvertFrom-Json
    $templateEvidence = Get-Content -Raw -Encoding UTF8 `
        -LiteralPath (Join-Path $CatalogRoot 'LIFECYCLE_GATE_EVIDENCE.json') | ConvertFrom-Json
    $invalidG08Evidence.gates.G08 = $templateEvidence.gates.G08
    [System.IO.File]::WriteAllText(
        $lifecycleEvidencePath,
        ($invalidG08Evidence | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
        $utf8NoBom)
    $invalidG08 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '65',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-65-read-only',
        '-GateId', 'G08', '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://fake-review-without-identifiers',
        '-ApprovedBy', 'Fixture Independent Reviewer'
    )
    if ($invalidG08.ExitCode -eq 0) {
        throw 'G08 accepted free-form review evidence without immutable identifiers and separation.'
    }
    $results.Add('free-form G08 review -> blocked')
    [System.IO.File]::WriteAllText($lifecycleEvidencePath, $validEvidenceBeforeG08, $utf8NoBom)
    $gateG08 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '65',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-65-read-only',
        '-GateId', 'G08', '-GateDecision', 'passed',
        '-GateEvidence', 'LIFECYCLE_GATE_EVIDENCE.json#G08',
        '-ApprovedBy', 'Fixture Independent Reviewer'
    )
    Require-ExitCode -Execution $gateG08 -Expected 0 -Label 'G08'
    $gateG09 = Invoke-Lifecycle @(
        'gate', '-ProcessRoot', $fixtureRoot,
        '-GateId', 'G09', '-GateDecision', 'passed',
        '-GateEvidence', 'LIFECYCLE_GATE_EVIDENCE.json#G09.authorization',
        '-ApprovedBy', 'Fixture Release Approver'
    )
    Require-ExitCode -Execution $gateG09 -Expected 0 -Label 'G09'

    $approvedEvidenceJson = Get-Content -Raw -Encoding UTF8 -LiteralPath $lifecycleEvidencePath
    $changedApprovedEvidence = $approvedEvidenceJson | ConvertFrom-Json
    $changedCandidateSha = '4444444444444444444444444444444444444444'
    $changedApprovedEvidence.gates.G08.candidate.candidateSha = $changedCandidateSha
    $changedApprovedEvidence.gates.G08.acceptance.candidateSha = $changedCandidateSha
    $changedApprovedEvidence.gates.G08.independentReview.candidateSha = $changedCandidateSha
    $changedApprovedEvidence.gates.G09.authorization.candidateSha = $changedCandidateSha
    $changedApprovedEvidence.gates.G09.deployment.candidateSha = $changedCandidateSha
    [System.IO.File]::WriteAllText(
        $lifecycleEvidencePath,
        ($changedApprovedEvidence | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
        $utf8NoBom)
    $changedEvidenceValidate = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    $changedEvidenceSelect = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '66',
        '-Evidence', 'LIFECYCLE_GATE_EVIDENCE.json#G09.authorization'
    )
    if ($changedEvidenceValidate.ExitCode -eq 0 -or $changedEvidenceSelect.ExitCode -eq 0) {
        throw "Approved G08/G09 evidence could be changed after approval. validate=$($changedEvidenceValidate.ExitCode), select=$($changedEvidenceSelect.ExitCode)."
    }
    [System.IO.File]::WriteAllText($lifecycleEvidencePath, $approvedEvidenceJson, $utf8NoBom)
    $results.Add('approved G08/G09 evidence mutation -> validate and mutator blocked')

    $select66 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '66',
        '-Evidence', 'LIFECYCLE_GATE_EVIDENCE.json#G09.authorization'
    )
    Require-ExitCode -Execution $select66 -Expected 0 -Label 'select authorized release'
    $record66 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '66',
        '-Result', 'completed', '-Evidence', 'LIFECYCLE_GATE_EVIDENCE.json#G09.deployment'
    )
    Require-ExitCode -Execution $record66 -Expected 0 -Label 'release execution evidence'

    foreach ($id in @('67', '68')) {
        $decision = Invoke-Lifecycle @(
            'decide', '-ProcessRoot', $fixtureRoot, '-PromptId', $id,
            '-Result', 'not_applicable', '-Evidence', "fixture://scope-excludes-$id"
        )
        Require-ExitCode -Execution $decision -Expected 0 -Label "decide $id"
    }
    $select69 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '69',
        '-Evidence', 'fixture://post-release-required'
    )
    Require-ExitCode -Execution $select69 -Expected 0 -Label 'select post-release validation'
    foreach ($id in @('69', '70')) {
        $record = Invoke-Lifecycle @(
            'record', '-ProcessRoot', $fixtureRoot, '-PromptId', $id,
            '-Result', 'completed', '-Evidence', "fixture://prompt-$id"
        )
        Require-ExitCode -Execution $record -Expected 0 -Label "record $id"
    }
    $decide73 = Invoke-Lifecycle @(
        'decide', '-ProcessRoot', $fixtureRoot, '-PromptId', '71',
        '-Result', 'not_applicable', '-Evidence', 'fixture://scope-excludes-69'
    )
    Require-ExitCode -Execution $decide73 -Expected 0 -Label 'decide 71'
    $select74 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '72',
        '-Evidence', 'fixture://vulnerability-monitoring-required'
    )
    Require-ExitCode -Execution $select74 -Expected 0 -Label 'select vulnerability monitoring'
    $record74 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '72',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-72'
    )
    Require-ExitCode -Execution $record74 -Expected 0 -Label 'record 72'
    $decide73 = Invoke-Lifecycle @(
        'decide', '-ProcessRoot', $fixtureRoot, '-PromptId', '73',
        '-Result', 'not_applicable', '-Evidence', 'fixture://scope-excludes-71'
    )
    Require-ExitCode -Execution $decide73 -Expected 0 -Label 'decide 73'
    $select74 = Invoke-Lifecycle @(
        'select', '-ProcessRoot', $fixtureRoot, '-PromptId', '74',
        '-Evidence', 'fixture://continuous-improvement-required'
    )
    Require-ExitCode -Execution $select74 -Expected 0 -Label 'select improvement'
    $record74 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '74',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-74'
    )
    Require-ExitCode -Execution $record74 -Expected 0 -Label 'record 74'
    $gateG10 = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $fixtureRoot, '-PromptId', '75',
        '-Result', 'completed', '-Evidence', 'fixture://prompt-75',
        '-GateId', 'G10', '-GateDecision', 'passed',
        '-GateEvidence', 'fixture://continuous-operations-established'
    )
    Require-ExitCode -Execution $gateG10 -Expected 0 -Label 'G10'

    $completedState = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json') | ConvertFrom-Json
    if ($completedState.status -ne 'completed' -or $completedState.nextAction -ne 'none') {
        throw "Lifecycle did not finish: status=$($completedState.status), nextAction=$($completedState.nextAction)"
    }
    $results.Add('G06 -> G10 -> lifecycle completed')

    $validateComplete = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    Require-ExitCode -Execution $validateComplete -Expected 0 -Label 'completed validate'

    $changeRoot = Join-Path $fixtureRoot 'changes\CHG-0001'
    New-Item -ItemType Directory -Path $changeRoot | Out-Null
    $changeProposalPath = Join-Path $changeRoot 'PROPOSAL.md'
    $changeProposal = @"
# Fixture change proposal

CHANGE_ID: CHG-0001
CHANGE_STATUS: pending
CHANGE_OWNER: fixture-owner
CHANGE_APPROVER: fixture-approver
CHANGE_BASELINE: fixture-release-v1
CHANGE_CREATED_AT: 2026-07-30T16:00:00+01:00
CHANGE_APPROVED_AT: 2026-07-30T16:30:00+01:00
"@
    [System.IO.File]::WriteAllText($changeProposalPath, $changeProposal, $utf8NoBom)
    $beforeRejectedCycle = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json')
    $rejectedCycle = Invoke-Lifecycle @(
        'cycle-start', '-ProcessRoot', $fixtureRoot, '-ChangeId', 'CHG-0001',
        '-Evidence', 'changes/CHG-0001/PROPOSAL.md'
    )
    Require-ExitCode -Execution $rejectedCycle -Expected 1 -Label 'cycle-start pending proposal'
    $afterRejectedCycle = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json')
    if ($afterRejectedCycle -ne $beforeRejectedCycle) {
        throw 'Rejected cycle-start changed lifecycle state.'
    }

    $approvedChangeProposal = $changeProposal.Replace('CHANGE_STATUS: pending', 'CHANGE_STATUS: approved')
    [System.IO.File]::WriteAllText($changeProposalPath, $approvedChangeProposal, $utf8NoBom)
    $startCycle = Invoke-Lifecycle @(
        'cycle-start', '-ProcessRoot', $fixtureRoot, '-ChangeId', 'CHG-0001',
        '-Evidence', 'changes/CHG-0001/PROPOSAL.md'
    )
    Require-ExitCode -Execution $startCycle -Expected 0 -Label 'cycle-start approved proposal'
    $cycleState = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_STATE.json') | ConvertFrom-Json
    if ([int]$cycleState.cycleNumber -ne 2 -or
        [string]$cycleState.currentPrompt -ne '01' -or
        [string]$cycleState.status -ne 'ready' -or
        [string]$cycleState.activeChange.id -ne 'CHG-0001' -or
        [string]$cycleState.gates.G10.status -ne 'pending') {
        throw 'cycle-start did not deterministically prepare cycle 2 at prompt 01.'
    }
    foreach ($archiveName in @(
        'BASELINE_LIFECYCLE_STATE.json',
        'BASELINE_LIFECYCLE_GATE_EVIDENCE.json'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $changeRoot $archiveName) -PathType Leaf)) {
            throw "cycle-start did not preserve archive: $archiveName"
        }
    }
    $cycleGateEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureRoot 'LIFECYCLE_GATE_EVIDENCE.json') | ConvertFrom-Json
    if ([int]$cycleGateEvidence.schemaVersion -ne 2 -or
        @($cycleGateEvidence.gates.PSObject.Properties | Where-Object { $_.Value.status -ne 'pending' }).Count -ne 0) {
        throw 'cycle-start did not reset structured gate evidence.'
    }
    $validateCycle = Invoke-Lifecycle @('validate', '-ProcessRoot', $fixtureRoot)
    Require-ExitCode -Execution $validateCycle -Expected 0 -Label 'cycle 2 validate'
    $duplicateCycle = Invoke-Lifecycle @(
        'cycle-start', '-ProcessRoot', $fixtureRoot, '-ChangeId', 'CHG-0001',
        '-Evidence', 'changes/CHG-0001/PROPOSAL.md'
    )
    Require-ExitCode -Execution $duplicateCycle -Expected 1 -Label 'cycle-start while cycle active'
    $results.Add('completed lifecycle -> approved CHG -> archived cycle 2 at prompt 01')

    Write-Host 'PASS: software lifecycle end-to-end test.' -ForegroundColor Green
    $results | ForEach-Object { Write-Host " - $_" }
    if ($KeepFixture) {
        Write-Host " - Fixture retained: $fixtureRoot"
    }
}
finally {
    if (Test-Path -LiteralPath $stableCatalogRoot -PathType Container) {
        $resolvedStableCatalog = [System.IO.Path]::GetFullPath($stableCatalogRoot)
        $resolvedTempForStable = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)
        $stablePrefix = $resolvedTempForStable + [System.IO.Path]::DirectorySeparatorChar + 'prompts-stable-catalog-'
        if (-not $resolvedStableCatalog.StartsWith($stablePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unverified stable catalog fixture: $resolvedStableCatalog"
        }
        Remove-Item -LiteralPath $resolvedStableCatalog -Recurse -Force
    }
    if (Test-Path -LiteralPath $junctionRoot) {
        $junctionItem = Get-Item -Force -LiteralPath $junctionRoot
        $resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)
        $resolvedJunction = [System.IO.Path]::GetFullPath($junctionRoot)
        $junctionPrefix = $resolvedTemp + [System.IO.Path]::DirectorySeparatorChar + 'prompts-lifecycle-junction-'
        if (-not $resolvedJunction.StartsWith($junctionPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
            ($junctionItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "Refusing to remove unverified junction fixture: $junctionRoot"
        }
        if ($IsWindows) {
            [System.IO.Directory]::Delete($junctionRoot)
        }
        else {
            Remove-Item -LiteralPath $junctionRoot -Force
        }
    }
    if (-not $KeepFixture -and (Test-Path -LiteralPath $fixtureRoot -PathType Container)) {
        $resolvedFixture = [System.IO.Path]::GetFullPath($fixtureRoot)
        $resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)
        $requiredPrefix = $resolvedTemp + [System.IO.Path]::DirectorySeparatorChar + 'prompts-lifecycle-e2e-'
        if (-not $resolvedFixture.StartsWith($requiredPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unverified fixture path: $resolvedFixture"
        }
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
    if (Test-Path -LiteralPath $brownfieldFixtureRoot -PathType Container) {
        $resolvedBrownfieldFixture = [System.IO.Path]::GetFullPath($brownfieldFixtureRoot)
        $resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)
        $requiredBrownfieldPrefix = $resolvedTemp + [System.IO.Path]::DirectorySeparatorChar + 'prompts-brownfield-e2e-'
        if (-not $resolvedBrownfieldFixture.StartsWith(
            $requiredBrownfieldPrefix,
            [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unverified brownfield fixture path: $resolvedBrownfieldFixture"
        }
        Remove-Item -LiteralPath $resolvedBrownfieldFixture -Recurse -Force
    }
    if (-not [string]::IsNullOrWhiteSpace($ownedBoilerplateFixture) -and
        (Test-Path -LiteralPath $ownedBoilerplateFixture -PathType Container)) {
        $resolvedBoilerplateFixture = [System.IO.Path]::GetFullPath($ownedBoilerplateFixture)
        $resolvedTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd(
            [System.IO.Path]::DirectorySeparatorChar,
            [System.IO.Path]::AltDirectorySeparatorChar)
        $requiredBoilerplatePrefix = $resolvedTemp +
            [System.IO.Path]::DirectorySeparatorChar +
            'prompts-boilerplate-fixture-'
        if (-not $resolvedBoilerplateFixture.StartsWith(
            $requiredBoilerplatePrefix,
            [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove unverified boilerplate fixture path: $resolvedBoilerplateFixture"
        }
        Remove-Item -LiteralPath $resolvedBoilerplateFixture -Recurse -Force
    }
}
