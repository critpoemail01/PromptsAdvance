[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$lifecycle = Join-Path $root 'software-lifecycle.ps1'
$powerShell = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $powerShell) { $powerShell = Get-Command powershell -ErrorAction Stop }
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('advance-lifecycle-migration-' + [Guid]::NewGuid().ToString('N'))

function Invoke-Lifecycle {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& $powerShell.Source -NoProfile -File $lifecycle @Arguments 2>&1)
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
}

function Assert-ExitCode {
    param($Execution, [int]$Expected, [string]$Label)
    if ($Execution.ExitCode -ne $Expected) {
        throw "$Label expected $Expected, found $($Execution.ExitCode). Output: $($Execution.Output)"
    }
}

function Write-Json {
    param([string]$Path, $Value)
    [System.IO.File]::WriteAllText(
        $Path,
        (($Value | ConvertTo-Json -Depth 40) + [Environment]::NewLine),
        $utf8NoBom)
}

try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    $boilerplate = Join-Path $temporaryRoot 'BoilerPlateAdvance'
    New-Item -ItemType Directory -Path $boilerplate | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $boilerplate 'README.md'), "fixture`n", $utf8NoBom)
    $process = Join-Path $temporaryRoot 'legacy-process'
    Assert-ExitCode (Invoke-Lifecycle @(
        'start', '-Name', 'legacy-migration-test', '-Owner', 'Fixture owner',
        '-ProcessRoot', $process, '-BoilerplatePath', $boilerplate
    )) 0 'start current fixture'

    $manifestPath = Join-Path $process 'PROCESS_MANIFEST.json'
    $statePath = Join-Path $process 'LIFECYCLE_STATE.json'
    $gateEvidencePath = Join-Path $process 'LIFECYCLE_GATE_EVIDENCE.json'
    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    $state = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
    $gateEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath | ConvertFrom-Json
    $legacyVersion = '2026-07-31.11'

    foreach ($stage in @($manifest.stages)) {
        $stage.promptIds = @($stage.promptIds | Where-Object { $_ -notin @('74', '75') })
        if ($stage.PSObject.Properties.Name -contains 'conditionalPromptIds') {
            $stage.conditionalPromptIds = @($stage.conditionalPromptIds | Where-Object { $_ -notin @('74', '75') })
        }
        if ($stage.PSObject.Properties.Name -contains 'repeatablePromptIds') {
            $stage.repeatablePromptIds = @($stage.repeatablePromptIds | Where-Object { $_ -notin @('74', '75') })
        }
    }
    $manifest.catalogVersion = $legacyVersion
    $manifest.promptCount = 73
    $manifest.releaseChannel = 'stable'
    $manifest.executionPolicy.workflowMode = 'governed'
    $manifest.executionPolicy.manualPromptAdvance = $false
    $manifest.executionPolicy.taskLedgerRequired = $true
    $manifest.executionPolicy.findingsGateRequired = $true
    $state.catalogVersion = $legacyVersion
    $state.prompts.PSObject.Properties.Remove('74')
    $state.prompts.PSObject.Properties.Remove('75')
    foreach ($id in @('01', '02', '03')) {
        $state.prompts.$id.status = 'completed'
        $state.prompts.$id.evidence = "fixture://prompt-$id"
    }
    foreach ($id in @('05', '06', '09', '10')) {
        $state.prompts.$id.applicability = 'required'
        $state.prompts.$id.status = 'pending'
    }
    $state.prompts.'04'.status = 'partial'
    $state.prompts.'04'.evidence = 'fixture://prompt-04-partial'
    $state.currentPrompt = '04'
    $state.currentStage = '01'
    $state.status = 'partial'
    $state.nextAction = 'resolve_current_prompt'
    $state.blockers = @('Direct validation and viability are still missing.')
    $state.history = @(
        [pscustomobject]@{ at = '2026-07-31T10:00:00+01:00'; promptId = '01'; result = 'completed'; evidence = 'fixture://prompt-01'; nextPrompt = '02' },
        [pscustomobject]@{ at = '2026-07-31T10:01:00+01:00'; promptId = '02'; result = 'completed'; evidence = 'fixture://prompt-02'; nextPrompt = '03' },
        [pscustomobject]@{ at = '2026-07-31T10:02:00+01:00'; promptId = '03'; result = 'completed'; evidence = 'fixture://prompt-03'; nextPrompt = '04' },
        [pscustomobject]@{ at = '2026-07-31T10:03:00+01:00'; promptId = '04'; result = 'partial'; evidence = 'fixture://prompt-04-partial'; nextPrompt = '' }
    )
    $state.revision = @($state.history).Count
    $state.activeWorkAttemptId = $null
    $gateEvidence.catalogVersion = $legacyVersion
    Write-Json -Path $manifestPath -Value $manifest
    Write-Json -Path $statePath -Value $state
    Write-Json -Path $gateEvidencePath -Value $gateEvidence
    foreach ($id in @('74', '75')) {
        $promptFile = Get-ChildItem -LiteralPath (Join-Path $process 'prompts') -Recurse -File -Filter "$id-*.md"
        Remove-Item -LiteralPath $promptFile.FullName -Force
    }
    foreach ($id in @('05', '06', '09', '10')) {
        $promptFile = Get-ChildItem -LiteralPath (Join-Path $process 'prompts') -Recurse -File -Filter "$id-*.md"
        Move-Item -LiteralPath $promptFile.FullName `
            -Destination (Join-Path (Split-Path $promptFile.DirectoryName -Parent) $promptFile.Name)
    }

    $contextBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $process 'APP_CONTEXT.md')
    $legacyHistoryBefore = ($state.history | ConvertTo-Json -Depth 20 -Compress)
    $legacyGatesBefore = ($state.gates | ConvertTo-Json -Depth 20 -Compress)
    $legacyPrompt04Before = [string]$state.prompts.'04'.evidence

    $defaultCandidate = Invoke-Lifecycle @('upgrade', '-ProcessRoot', $process)
    if ($defaultCandidate.ExitCode -eq 0 -or
        $defaultCandidate.Output -notmatch 'stable catalog automatically') {
        throw 'Candidate migration did not require explicit confirmation.'
    }

    Assert-ExitCode (Invoke-Lifecycle @(
        'upgrade', '-ProcessRoot', $process, '-ConfirmMigration', '-AcceptCandidateCatalog',
        '-Objective', 'Migrate legacy state while preserving evidence'
    )) 0 'controlled legacy migration'

    $migrated = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
    $migratedManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    if ($migratedManifest.promptCount -ne 75 -or
        $null -eq $migrated.prompts.PSObject.Properties['74'] -or
        $null -eq $migrated.prompts.PSObject.Properties['75']) {
        throw 'Controlled migration did not add prompts 74 and 75.'
    }
    $migratedPromptFiles = @(Get-ChildItem -LiteralPath (Join-Path $process 'prompts') -Recurse -File -Filter '*.md')
    if ($migratedPromptFiles.Count -ne 75 -or
        @($migratedPromptFiles | Where-Object {
            $_.Name -match '^(05|06|09|10)-' -and $_.Directory.Name -ne 'Optional'
        }).Count -ne 0) {
        throw 'Controlled migration did not remove stale prompt paths after catalog moves.'
    }
    if ($migrated.status -ne 'awaiting_programmer' -or
        $null -ne $migrated.currentPrompt -or
        $migrated.lastPrompt -ne '04' -or
        $migrated.nextAction -ne 'next | repeat | correct | skip_and_advance') {
        throw 'Legacy partial result was not converted to programmer-controlled waiting state.'
    }
    if ($migrated.prompts.'04'.status -ne 'partial' -or
        [string]$migrated.prompts.'04'.evidence -ne $legacyPrompt04Before -or
        @($migrated.prompts.'04'.remainingWork).Count -lt 1) {
        throw 'Prompt 04 result, evidence or remaining work was not preserved.'
    }
    $preservedHistory = @($migrated.history | Select-Object -First 4) | ConvertTo-Json -Depth 20 -Compress
    if ($preservedHistory -ne $legacyHistoryBefore -or
        ($migrated.gates | ConvertTo-Json -Depth 20 -Compress) -ne $legacyGatesBefore -or
        (Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $process 'APP_CONTEXT.md')) -ne $contextBefore) {
        throw 'Controlled migration changed prior history, gates or product context.'
    }
    foreach ($id in @('05', '06', '09', '10')) {
        if ($migrated.prompts.$id.applicability -ne 'conditional' -or
            $migrated.prompts.$id.status -ne 'not_selected') {
            throw "Untouched prompt $id did not adopt current conditional applicability."
        }
    }
    Assert-ExitCode (Invoke-Lifecycle @('validate', '-ProcessRoot', $process)) 0 'validate migrated lifecycle'
    Assert-ExitCode (Invoke-Lifecycle @(
        'advance', '-ProcessRoot', $process, '-AcceptIncomplete',
        '-Objective', 'Programmer accepted the recorded gaps for this iteration'
    )) 0 'advance after accepting gaps'
    $advanced = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
    if ($advanced.currentPrompt -ne '07' -or $advanced.status -ne 'ready' -or
        $advanced.gates.G01.status -ne 'pending' -or
        @($advanced.history | Where-Object {
            $null -ne $_.PSObject.Properties['action'] -and
            [string]$_.action -match '^skip-incomplete-and-advance:04->07$'
        }).Count -ne 1) {
        throw 'Accepted incomplete prompt did not advance to the next applicable prompt while preserving G01.'
    }
    Assert-ExitCode (Invoke-Lifecycle @('validate', '-ProcessRoot', $process)) 0 'validate advanced lifecycle'
    Write-Host 'PASS: controlled legacy migration preserves evidence and supports accepted incomplete advance.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
