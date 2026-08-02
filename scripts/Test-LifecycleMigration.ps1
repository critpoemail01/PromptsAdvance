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
        $stage.promptIds = @($stage.promptIds | Where-Object { $_ -notin @('74', '75', '76') })
        if ($stage.PSObject.Properties.Name -contains 'conditionalPromptIds') {
            $stage.conditionalPromptIds = @($stage.conditionalPromptIds | Where-Object { $_ -notin @('74', '75', '76') })
        }
        if ($stage.PSObject.Properties.Name -contains 'repeatablePromptIds') {
            $stage.repeatablePromptIds = @($stage.repeatablePromptIds | Where-Object { $_ -notin @('74', '75', '76') })
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
    $state.prompts.PSObject.Properties.Remove('76')
    foreach ($id in @('01', '02', '03')) {
        $state.prompts.$id.status = 'completed'
        $state.prompts.$id.evidence = "fixture://prompt-$id"
    }
    foreach ($id in @('05', '06', '10', '11')) {
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
    foreach ($id in @('74', '75', '76')) {
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

    $prompt08 = Get-ChildItem -LiteralPath (Join-Path $process 'prompts') `
        -Recurse -File -Filter '08-*.md'
    $prompt08OriginalPath = $prompt08.FullName
    $prompt08ChangedPath = Join-Path $prompt08.DirectoryName '08-reused-identity.md'
    Move-Item -LiteralPath $prompt08OriginalPath -Destination $prompt08ChangedPath
    $identityMismatch = Invoke-Lifecycle @(
        'upgrade', '-ProcessRoot', $process, '-ConfirmMigration', '-AcceptCandidateCatalog',
        '-Objective', 'Prove that reused prompt identities fail closed'
    )
    if ($identityMismatch.ExitCode -eq 0 -or
        $identityMismatch.Output -notmatch 'prompt 08 identity' -or
        $identityMismatch.Output -notmatch 'mapping' -or
        $identityMismatch.Output -notmatch 'changed') {
        throw "Controlled migration did not reject a reused prompt identity. Output: $($identityMismatch.Output)"
    }
    Move-Item -LiteralPath $prompt08ChangedPath -Destination $prompt08OriginalPath

    Assert-ExitCode (Invoke-Lifecycle @(
        'upgrade', '-ProcessRoot', $process, '-ConfirmMigration', '-AcceptCandidateCatalog',
        '-Objective', 'Migrate legacy state while preserving evidence'
    )) 0 'controlled legacy migration'

    $migrated = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
    $migratedManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    if ($migratedManifest.promptCount -ne 76 -or
        $null -eq $migrated.prompts.PSObject.Properties['74'] -or
        $null -eq $migrated.prompts.PSObject.Properties['75'] -or
        $null -eq $migrated.prompts.PSObject.Properties['76']) {
        throw 'Controlled migration did not add prompts 74, 75 and 76.'
    }
    $migratedPromptFiles = @(Get-ChildItem -LiteralPath (Join-Path $process 'prompts') -Recurse -File -Filter '*.md')
    if ($migratedPromptFiles.Count -ne 76 -or
        @($migratedPromptFiles | Where-Object {
            $_.Name -match '^(05|06|10|11)-' -and $_.Directory.Name -ne 'Optional'
        }).Count -ne 0) {
        throw 'Controlled migration did not remove stale prompt paths after catalog moves.'
    }
    if ($migrated.status -ne 'awaiting_programmer' -or
        $null -ne $migrated.currentPrompt -or
        $migrated.lastPrompt -ne '04' -or
        $migrated.nextAction -ne 'next | repeat | correct | skip_and_advance | decide') {
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
    foreach ($id in @('05', '06', '10', '11')) {
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

    $identityShiftProcess = Join-Path $temporaryRoot 'identity-shift-process'
    Assert-ExitCode (Invoke-Lifecycle @(
        'start', '-Name', 'identity-shift-migration-test', '-Owner', 'Fixture owner',
        '-ProcessRoot', $identityShiftProcess, '-BoilerplatePath', $boilerplate
    )) 0 'start identity-shift fixture'
    $shiftManifestPath = Join-Path $identityShiftProcess 'PROCESS_MANIFEST.json'
    $shiftStatePath = Join-Path $identityShiftProcess 'LIFECYCLE_STATE.json'
    $shiftGateEvidencePath = Join-Path $identityShiftProcess 'LIFECYCLE_GATE_EVIDENCE.json'
    $shiftManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $shiftManifestPath | ConvertFrom-Json
    $shiftState = Get-Content -Raw -Encoding UTF8 -LiteralPath $shiftStatePath | ConvertFrom-Json
    $shiftGateEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $shiftGateEvidencePath | ConvertFrom-Json
    foreach ($stage in @($shiftManifest.stages)) {
        $stage.promptIds = @($stage.promptIds | Where-Object { $_ -ne '09' })
        foreach ($propertyName in @('conditionalPromptIds', 'repeatablePromptIds')) {
            if ($stage.PSObject.Properties.Name -contains $propertyName) {
                $stage.$propertyName = @($stage.$propertyName | Where-Object { $_ -ne '09' })
            }
        }
    }
    $shiftManifest.catalogVersion = '2026-08-01.6'
    $shiftManifest.promptCount = 75
    $shiftManifest.releaseChannel = 'stable'
    $shiftState.catalogVersion = [string]$shiftManifest.catalogVersion
    $shiftedPromptState = $shiftState.prompts.'09'
    $shiftedPromptState.evidence = 'fixture://stable-identity-preserved'
    $shiftState.prompts.PSObject.Properties.Remove('08')
    $shiftState.prompts.PSObject.Properties.Remove('09')
    $shiftState.prompts | Add-Member -MemberType NoteProperty -Name '08' -Value $shiftedPromptState
    $shiftGateEvidence.catalogVersion = [string]$shiftManifest.catalogVersion
    Write-Json -Path $shiftManifestPath -Value $shiftManifest
    Write-Json -Path $shiftStatePath -Value $shiftState
    Write-Json -Path $shiftGateEvidencePath -Value $shiftGateEvidence
    $oldPrompt08 = Get-ChildItem -LiteralPath (Join-Path $identityShiftProcess 'prompts') `
        -Recurse -File -Filter '08-*.md'
    $oldPrompt09 = Get-ChildItem -LiteralPath (Join-Path $identityShiftProcess 'prompts') `
        -Recurse -File -Filter '09-*.md'
    Remove-Item -LiteralPath $oldPrompt08.FullName -Force
    Move-Item -LiteralPath $oldPrompt09.FullName `
        -Destination (Join-Path $oldPrompt09.DirectoryName ($oldPrompt09.Name -replace '^09-', '08-'))

    $shiftUpgrade = Invoke-Lifecycle @(
        'upgrade', '-ProcessRoot', $identityShiftProcess,
        '-ConfirmMigration', '-AcceptCandidateCatalog',
        '-Objective', 'Preserve state while a stable prompt identity moves to another ID'
    )
    Assert-ExitCode $shiftUpgrade 0 'identity-shift migration'
    if ($shiftUpgrade.Output -notmatch '08->09') {
        throw "Identity-shift migration did not report the remap. Output: $($shiftUpgrade.Output)"
    }
    $shiftMigrated = Get-Content -Raw -Encoding UTF8 -LiteralPath $shiftStatePath | ConvertFrom-Json
    $currentCatalogVersion = [string](
        Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root 'PROCESS_MANIFEST.json') |
            ConvertFrom-Json
    ).catalogVersion
    if ([string]$shiftMigrated.prompts.'09'.evidence -ne 'fixture://stable-identity-preserved' -or
        $null -eq $shiftMigrated.prompts.PSObject.Properties['08'] -or
        $shiftMigrated.catalogVersion -ne $currentCatalogVersion) {
        throw 'Identity-shift migration did not preserve evidence under the new ID and add the inserted prompt.'
    }
    Assert-ExitCode (Invoke-Lifecycle @(
        'validate', '-ProcessRoot', $identityShiftProcess
    )) 0 'validate identity-shift migration'

    $recoveryMarker = Join-Path $temporaryRoot `
        'identity-shift-process-tool-update-backup-20260802-000000'
    New-Item -ItemType Directory -Path $recoveryMarker | Out-Null
    $localUpdater = Join-Path $root 'scripts/Update-AdvanceLocalProjects.ps1'
    $propagationOutput = @(
        & $powerShell.Source -NoProfile -File $localUpdater `
            -ProjectsRoot $temporaryRoot -AcceptCandidateCatalog `
            -Objective 'Validate propagation and safe skipping in disposable fixtures' 2>&1
    ) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0 -or
        $propagationOutput -notmatch 'Updated: legacy-process ->' -or
        $propagationOutput -notmatch 'Skipped: identity-shift-process: recovery/concurrent-update marker exists' -or
        $propagationOutput -match 'BoilerPlateAdvance ->') {
        throw "Local lifecycle propagation did not update and skip the expected roots. Output: $propagationOutput"
    }
    Write-Host 'PASS: controlled legacy migration preserves evidence and supports accepted incomplete advance.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
