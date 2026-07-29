[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('start', 'adopt', 'continue', 'status', 'next', 'select', 'decide', 'gate', 'record', 'validate')]
    [string]$Command,

    [string]$Name,
    [string]$Owner,
    [string]$ProcessRoot,
    [string]$BoilerplatePath,
    [string]$ProjectPath,

    [string]$PromptId,
    [ValidateSet('completed', 'partial', 'blocked', 'not_applicable')]
    [string]$Result,
    [string]$Evidence,
    [string]$NextPrompt,

    [string]$GateId,
    [ValidateSet('passed', 'failed', 'pending')]
    [string]$GateDecision,
    [string]$GateEvidence,
    [string]$ApprovedBy,

    [string]$SliceId,
    [ValidateSet('page', 'feature')]
    [string]$SliceKind,
    [ValidateSet('ssr', 'web', 'maui')]
    [string]$Surface,
    [string]$Requirements,
    [string]$AcceptanceCriteria,
    [string]$OutOfScope
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

$catalogRoot = [System.IO.Path]::GetFullPath($PSScriptRoot).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar)
$powerShellCommand = Get-Command powershell -ErrorAction SilentlyContinue
if ($null -eq $powerShellCommand) {
    $powerShellCommand = Get-Command pwsh -ErrorAction SilentlyContinue
}
if ($null -eq $powerShellCommand) {
    throw 'PowerShell executable was not found.'
}
$powerShellExe = $powerShellCommand.Source

function Get-FullPath {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
}

function Get-PhysicalPath {
    param([Parameter(Mandatory)][string]$Path)

    $candidate = Get-FullPath $Path
    $visited = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($resolutionPass in 1..32) {
        if (-not $visited.Add($candidate)) {
            throw "Reparse-point cycle detected while resolving path: $Path"
        }
        $root = [System.IO.Path]::GetPathRoot($candidate)
        $relative = $candidate.Substring($root.Length)
        $segments = @($relative -split '[\\/]' | Where-Object { $_ -ne '' })
        $current = $root
        $resolvedReparsePoint = $false
        for ($index = 0; $index -lt $segments.Count; $index++) {
            $next = Join-Path $current $segments[$index]
            if (Test-Path -LiteralPath $next) {
                $item = Get-Item -Force -LiteralPath $next
                if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    $targetProperty = $item.PSObject.Properties['Target']
                    if ($null -eq $targetProperty -or @($item.Target).Count -lt 1) {
                        throw "Cannot resolve reparse-point target: $next"
                    }
                    $target = [string]@($item.Target)[0]
                    if (-not [System.IO.Path]::IsPathRooted($target)) {
                        $target = Join-Path ([System.IO.Path]::GetDirectoryName($next)) $target
                    }
                    $remaining = @($segments | Select-Object -Skip ($index + 1))
                    $candidate = Get-FullPath $target
                    foreach ($segment in $remaining) {
                        $candidate = Join-Path $candidate $segment
                    }
                    $candidate = Get-FullPath $candidate
                    $resolvedReparsePoint = $true
                    break
                }
            }
            $current = $next
        }
        if (-not $resolvedReparsePoint) {
            return Get-FullPath $candidate
        }
    }
    throw "Path contains too many nested reparse points: $Path"
}

function Test-IsSameOrChild {
    param(
        [Parameter(Mandatory)][string]$Candidate,
        [Parameter(Mandatory)][string]$Parent
    )

    $candidateFull = Get-PhysicalPath $Candidate
    $parentFull = Get-PhysicalPath $Parent
    if ($candidateFull.Equals($parentFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    $prefix = $parentFull + [System.IO.Path]::DirectorySeparatorChar
    return $candidateFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Require-SafeText {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Contains('|') -or $Value.Contains("`r") -or $Value.Contains("`n")) {
        throw "$Label must be non-empty and cannot contain pipes or new lines."
    }
}

function Convert-ToTimestamp {
    param([AllowNull()]$Value)
    if ($Value -is [DateTimeOffset]) {
        return [DateTimeOffset]$Value
    }
    if ($Value -is [DateTime]) {
        return [DateTimeOffset]([DateTime]$Value)
    }
    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse(
        [string]$Value,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::RoundtripKind,
        [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function Get-Manifest {
    param([Parameter(Mandatory)][string]$Root)
    $path = Join-Path $Root 'PROCESS_MANIFEST.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "PROCESS_MANIFEST.json is missing: $path"
    }
    return Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json
}

function Get-StatePath {
    param([Parameter(Mandatory)][string]$Root)
    return Join-Path $Root 'LIFECYCLE_STATE.json'
}

function Get-State {
    param([Parameter(Mandatory)][string]$Root)
    $path = Get-StatePath $Root
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "LIFECYCLE_STATE.json is missing: $path"
    }
    return Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json
}

function Save-State {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Root
    )
    $statePath = Get-StatePath $Root
    $lockPath = Join-Path $Root '.lifecycle-state.lock'
    $lockStream = $null
    $temporaryPath = Join-Path $Root ('.LIFECYCLE_STATE.' + [Guid]::NewGuid().ToString('N') + '.tmp')
    $backupPath = Join-Path $Root ('.LIFECYCLE_STATE.' + [Guid]::NewGuid().ToString('N') + '.bak')
    try {
        foreach ($attempt in 1..50) {
            try {
                $lockStream = [System.IO.File]::Open(
                    $lockPath,
                    [System.IO.FileMode]::OpenOrCreate,
                    [System.IO.FileAccess]::ReadWrite,
                    [System.IO.FileShare]::None)
                break
            }
            catch [System.IO.IOException] {
                if ($attempt -eq 50) {
                    throw 'Could not acquire the lifecycle state lock within five seconds.'
                }
                Start-Sleep -Milliseconds 100
            }
        }

        $diskState = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
        if ([int64]$diskState.revision -ne [int64]$State.revision) {
            throw "Concurrent lifecycle update detected: expected revision $($State.revision), found $($diskState.revision). Reload status before retrying."
        }
        $State.revision = [int64]$State.revision + 1
        $State.updatedAt = [DateTimeOffset]::Now.ToString('o')
        $json = $State | ConvertTo-Json -Depth 30
        [System.IO.File]::WriteAllText($temporaryPath, $json + [Environment]::NewLine, $utf8NoBom)
        [System.IO.File]::Replace($temporaryPath, $statePath, $backupPath)
    }
    finally {
        if ($null -ne $lockStream) {
            $lockStream.Dispose()
        }
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            Remove-Item -LiteralPath $backupPath -Force
        }
    }
}

function Normalize-PromptId {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }
    if ($Value -notmatch '^\d{1,2}$') {
        throw "Prompt id must contain one or two digits: $Value"
    }
    $number = [int]$Value
    if ($number -lt 1 -or $number -gt 73) {
        throw "Prompt id is outside 01-73: $Value"
    }
    return '{0:D2}' -f $number
}

function Get-PromptFile {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Id
    )
    $matches = @(Get-ChildItem -LiteralPath (Join-Path $Root 'prompts') -Recurse -File -Filter "$Id-*.md")
    if ($matches.Count -ne 1) {
        throw "Expected one prompt for $Id; found $($matches.Count)."
    }
    return $matches[0]
}

function Get-PromptStage {
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$Id
    )
    $matches = @($Manifest.stages | Where-Object { @($_.promptIds) -contains $Id })
    if ($matches.Count -ne 1) {
        throw "Prompt $Id must belong to exactly one stage; found $($matches.Count)."
    }
    return $matches[0]
}

function Get-PromptState {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Id
    )
    $property = $State.prompts.PSObject.Properties[$Id]
    if ($null -eq $property) {
        throw "Prompt $Id is missing from LIFECYCLE_STATE.json."
    }
    return $property.Value
}

function Get-GateState {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Id
    )
    $property = $State.gates.PSObject.Properties[$Id]
    if ($null -eq $property) {
        throw "Gate $Id is missing from LIFECYCLE_STATE.json."
    }
    return $property.Value
}

function Set-CurrentPrompt {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$Manifest,
        [AllowNull()][string]$Id
    )
    if ($null -eq $Id) {
        $State.currentPrompt = $null
        return
    }

    $promptState = Get-PromptState -State $State -Id $Id
    if ($promptState.status -eq 'not_selected') {
        $promptState.status = 'ready'
        $promptState.applicability = 'selected'
    }
    elseif ($promptState.status -in @('pending', 'partial', 'blocked', 'completed', 'not_applicable')) {
        $promptState.status = 'ready'
    }

    $stage = Get-PromptStage -Manifest $Manifest -Id $Id
    $State.currentPrompt = $Id
    $State.currentStage = $stage.id
    $State.status = 'ready'
    $State.nextAction = 'execute_prompt'
}

function Test-EntryGate {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$NextId
    )

    $stage = Get-PromptStage -Manifest $Manifest -Id $NextId
    $entryGate = $stage.entryGate
    if ($null -eq $entryGate -or [string]::IsNullOrWhiteSpace([string]$entryGate)) {
        return
    }

    $gate = Get-GateState -State $State -Id ([string]$entryGate)
    if ($gate.status -ne 'passed') {
        throw "Prompt $NextId cannot start because entry gate $entryGate is '$($gate.status)'."
    }

    if ([int]$NextId -ge 13 -and [int]$NextId -le 18) {
        $g03 = Get-GateState -State $State -Id 'G03'
        if ($g03.status -ne 'passed') {
            throw "Prompt $NextId cannot start because implementation gate G03 is '$($g03.status)'."
        }
    }

    if ($NextId -eq '64') {
        $g08 = Get-GateState -State $State -Id 'G08'
        if ($g08.status -ne 'passed') {
            throw "Prompt 64 cannot start because candidate/review gate G08 is '$($g08.status)'."
        }
        $g09 = Get-GateState -State $State -Id 'G09'
        if ($g09.status -ne 'passed') {
            throw "Prompt 64 cannot start because exact release authorization gate G09 is '$($g09.status)'."
        }
        foreach ($requiredPrompt in @('61', '62', '63')) {
            $requiredState = Get-PromptState -State $State -Id $requiredPrompt
            if ($requiredState.status -ne 'completed') {
                throw "Prompt 64 cannot start because prompt $requiredPrompt is '$($requiredState.status)'."
            }
        }
    }
}

function Invoke-ProductDefinitionGate {
    param([Parameter(Mandatory)][string]$Root)
    $script = Join-Path $Root 'scripts/Test-ProductDefinitionGate.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
        throw "Product definition gate script is missing: $script"
    }
    $validatorOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $script
    $validatorExitCode = $LASTEXITCODE
    $validatorOutput | Out-Host
    if ($validatorExitCode -ne 0) {
        throw 'Product definition gate failed.'
    }
}

function Invoke-ManifestGateValidator {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)]$GateDefinition,
        [AllowNull()][string]$RecordedApprover
    )

    if (-not ($GateDefinition.PSObject.Properties.Name -contains 'validator') -or
        [string]::IsNullOrWhiteSpace([string]$GateDefinition.validator)) {
        return
    }

    $validator = Join-Path $Root ([string]$GateDefinition.validator)
    if (-not (Test-Path -LiteralPath $validator -PathType Leaf)) {
        throw "Gate validator is missing: $validator"
    }
    if ([System.IO.Path]::GetFileName($validator) -eq 'Test-LifecycleGateEvidence.ps1') {
        $validatorArguments = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $validator,
            '-GateId', ([string]$GateDefinition.id),
            '-ProcessRoot', $Root
        )
        if (-not [string]::IsNullOrWhiteSpace($RecordedApprover)) {
            $validatorArguments += @('-ApprovedBy', $RecordedApprover)
        }
        $validatorOutput = & $powerShellExe @validatorArguments
    }
    else {
        $validatorOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $validator
    }
    $validatorExitCode = $LASTEXITCODE
    $validatorOutput | Out-Host
    if ($validatorExitCode -ne 0) {
        throw "Gate $($GateDefinition.id) validator failed."
    }
}

function Test-GatePrerequisites {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$GateDefinition
    )

    if ($GateDefinition.PSObject.Properties.Name -contains 'requiresGates') {
        foreach ($requiredGateId in @($GateDefinition.requiresGates)) {
            $requiredGate = Get-GateState -State $State -Id ([string]$requiredGateId)
            if ($requiredGate.status -ne 'passed') {
                throw "Gate $($GateDefinition.id) requires $requiredGateId to pass; found '$($requiredGate.status)'."
            }
        }
    }
    if ($GateDefinition.PSObject.Properties.Name -contains 'requiredPromptIds') {
        foreach ($requiredPromptId in @($GateDefinition.requiredPromptIds)) {
            $requiredPrompt = Get-PromptState -State $State -Id ([string]$requiredPromptId)
            $acceptable = $requiredPrompt.status -eq 'completed' -or
                ($requiredPrompt.applicability -ne 'required' -and $requiredPrompt.status -eq 'not_applicable')
            if (-not $acceptable) {
                throw "Gate $($GateDefinition.id) requires prompt $requiredPromptId to be completed or explicitly not applicable; found '$($requiredPrompt.status)'."
            }
        }
    }
    if ($GateDefinition.id -eq 'G04') {
        if ($null -eq $State.activeSlice -or $State.activeSlice.status -ne 'completed') {
            throw 'Gate G04 requires a completed active vertical slice.'
        }
    }
}

function Get-StructuredGateEvidence {
    param([Parameter(Mandatory)][string]$Root)
    $path = Join-Path $Root 'LIFECYCLE_GATE_EVIDENCE.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Structured lifecycle gate evidence is missing: $path"
    }
    return Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json
}

function Get-ObjectSha256 {
    param([Parameter(Mandatory)]$Value)
    $json = $Value | ConvertTo-Json -Depth 30 -Compress
    $bytes = $utf8NoBom.GetBytes($json)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}

function Set-GateSnapshot {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$GateId
    )

    if ($GateId -notin @('G06', 'G07', 'G08', 'G09', 'G10')) {
        return
    }
    $evidence = Get-StructuredGateEvidence -Root $Root
    $gateEvidence = $evidence.gates.$GateId
    $gateState = Get-GateState -State $State -Id $GateId
    $snapshot = if ($GateId -eq 'G09') {
        [ordered]@{
            kind = 'release_authorization'
            authorizationSha256 = Get-ObjectSha256 -Value $gateEvidence.authorization
            candidateSha = [string]$gateEvidence.authorization.candidateSha
            artifactDigest = [string]$gateEvidence.authorization.artifactDigest
            environment = [string]$gateEvidence.authorization.environment
            releaseWindow = [string]$gateEvidence.authorization.releaseWindow
            authorizedByIdentity = [string]$gateEvidence.authorization.authorizedByIdentity
            authorizedAt = [string]$gateEvidence.authorization.authorizedAt
            deploymentSha256 = $null
        }
    }
    else {
        [ordered]@{
            kind = 'gate_section'
            gateSectionSha256 = Get-ObjectSha256 -Value $gateEvidence
        }
    }
    if ($GateId -eq 'G08') {
        $snapshot['baseSha'] = [string]$gateEvidence.candidate.baseSha
        $snapshot['candidateSha'] = [string]$gateEvidence.candidate.candidateSha
        $snapshot['artifactDigest'] = [string]$gateEvidence.candidate.artifactDigest
        $snapshot['reviewerIdentity'] = [string]$gateEvidence.independentReview.reviewerIdentity
        $snapshot['independentTaskId'] = [string]$gateEvidence.independentReview.taskId
    }
    $gateState | Add-Member -NotePropertyName 'snapshot' -NotePropertyValue $snapshot -Force
}

function Set-G09DeploymentSnapshot {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Root
    )
    $evidence = Get-StructuredGateEvidence -Root $Root
    $gateState = Get-GateState -State $State -Id 'G09'
    if ($null -eq $gateState.snapshot) {
        throw 'G09 authorization snapshot is missing.'
    }
    $gateState.snapshot.deploymentSha256 = Get-ObjectSha256 -Value $evidence.gates.G09.deployment
}

function Test-GateSnapshot {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$GateId
    )

    if ($GateId -notin @('G06', 'G07', 'G08', 'G09', 'G10')) {
        return
    }
    $gateState = Get-GateState -State $State -Id $GateId
    if ($null -eq $gateState.PSObject.Properties['snapshot'] -or $null -eq $gateState.snapshot) {
        throw "Gate $GateId has no immutable approval snapshot."
    }
    $evidence = Get-StructuredGateEvidence -Root $Root
    $gateEvidence = $evidence.gates.$GateId
    if ($GateId -eq 'G09') {
        $authorizationHash = Get-ObjectSha256 -Value $gateEvidence.authorization
        if ($authorizationHash -ne [string]$gateState.snapshot.authorizationSha256) {
            throw 'G09 release authorization changed after approval.'
        }
        foreach ($field in @('candidateSha', 'artifactDigest', 'environment', 'releaseWindow', 'authorizedByIdentity', 'authorizedAt')) {
            if ([string]$gateEvidence.authorization.$field -ne [string]$gateState.snapshot.$field) {
                throw "G09 immutable authorization field changed: $field."
            }
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$gateState.snapshot.deploymentSha256)) {
            $deploymentHash = Get-ObjectSha256 -Value $gateEvidence.deployment
            if ($deploymentHash -ne [string]$gateState.snapshot.deploymentSha256) {
                throw 'G09 deployment evidence changed after release completion.'
            }
        }
    }
    else {
        $sectionHash = Get-ObjectSha256 -Value $gateEvidence
        if ($sectionHash -ne [string]$gateState.snapshot.gateSectionSha256) {
            throw "Gate $GateId structured evidence changed after approval."
        }
    }
}

function Get-AutomaticNextPrompt {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$CompletedId
    )

    $numericId = [int]$CompletedId
    if ($numericId -ge 1 -and $numericId -le 11) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($numericId -ge 19 -and $numericId -le 21) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -eq '23') {
        return '24'
    }
    if ($CompletedId -in @('25', '27')) {
        if ($null -eq $State.activeSlice -or [string]::IsNullOrWhiteSpace([string]$State.activeSlice.surface)) {
            throw "Prompt $CompletedId cannot route without an active slice surface."
        }
        $surfaceMap = @{
            ssr = '13'
            web = '15'
            maui = '17'
        }
        return $surfaceMap[[string]$State.activeSlice.surface]
    }
    if ($CompletedId -in @('13', '15', '17')) {
        if ($null -eq $State.activeSlice -or [string]::IsNullOrWhiteSpace([string]$State.activeSlice.kind)) {
            throw "Surface prompt $CompletedId cannot route without an active slice kind."
        }
        return $(if ($State.activeSlice.kind -eq 'page') { '26' } else { '28' })
    }
    if ($CompletedId -in @('39', '40', '41', '42', '43')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -eq '48') {
        return '49'
    }
    if ($CompletedId -in @('51', '52', '53')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -in @('58', '59')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -in @('61', '62')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -eq '67') {
        return '68'
    }
    if ($CompletedId -eq '72') {
        return '73'
    }
    return $null
}

function Get-DecisionHint {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$CompletedId
    )

    if ($CompletedId -eq '12') {
        return 'select_vertical_slice: choose 19 for required foundation, otherwise 25 for a page or 27 for a feature'
    }
    if ($CompletedId -eq '22') {
        return 'select_vertical_slice: choose 25 for a page or 27 for a feature'
    }
    if ($CompletedId -in @('26', '28')) {
        return 'select_next_slice_or_global_completion: choose 25/27 for another Must slice or 23 when Must slices are ready for global completion'
    }
    if ($CompletedId -in @('14', '16', '18')) {
        return 'select_next_slice_or_global_completion: close another active surface, choose 25/27 for another Must slice, or choose 23 for global completion'
    }
    if ([int]$CompletedId -ge 24 -and [int]$CompletedId -le 38) {
        return 'select_applicable_capability_or_security: decide 29-38 applicability, then continue with 39'
    }
    if ([int]$CompletedId -ge 44 -and [int]$CompletedId -le 47) {
        return 'select_growth_or_hardening: decide 45-47 applicability, then continue with 48'
    }
    if ($CompletedId -in @('49', '50')) {
        return 'select_pwa_or_continue: decide prompt 50 applicability, then continue with 51'
    }
    if ($CompletedId -eq '54') {
        return 'select_delivery: continue with 55 after G06 passes'
    }
    if ($CompletedId -in @('55', '56', '57')) {
        return 'select_distribution_or_operations: decide 56-57 applicability, then continue with 58'
    }
    if ($CompletedId -eq '60') {
        return 'select_acceptance: continue with 61 after G07 passes'
    }
    if ($CompletedId -eq '63') {
        return 'authorize_release: validate G09 for the exact environment, candidate, digest and window, then select 64'
    }
    if ($CompletedId -in @('64', '65', '66')) {
        return 'select_continuous_operations: decide 65-66 applicability, then continue with 67'
    }
    if ($CompletedId -in @('68', '69', '70', '71')) {
        return 'select_observability_and_improvement: decide 69, continue with 70, decide 71, then continue with 72'
    }
    if ($CompletedId -eq '73') {
        return 'complete_G10_gate: validate continuous-operation owners, cadences and evidence'
    }
    return 'select_next_prompt_from_workflow'
}

function Get-AllowedSelectionPromptIds {
    param([Parameter(Mandatory)]$State)

    $action = [string]$State.nextAction
    if ($action -match '^select_vertical_slice') {
        $lastPrompt = @($State.history | Where-Object { $_.PSObject.Properties.Name -contains 'promptId' })[-1].promptId
        return $(if ($lastPrompt -eq '22') { @('25', '27') } else { @('19', '25', '27') })
    }
    if ($action -match '^select_next_slice_or_global_completion') {
        return @('14', '16', '18', '23', '25', '27')
    }
    if ($action -match '^select_applicable_capability_or_security') {
        return @(29..39 | ForEach-Object { '{0:D2}' -f $_ })
    }
    if ($action -match '^select_growth_or_hardening') {
        return @('45', '46', '47', '48')
    }
    if ($action -match '^select_pwa_or_continue') {
        return @('50', '51')
    }
    if ($action -match '^select_delivery') {
        return @('55')
    }
    if ($action -match '^select_distribution_or_operations') {
        return @('56', '57', '58')
    }
    if ($action -match '^select_acceptance') {
        return @('61')
    }
    if ($action -match '^authorize_release') {
        return @('64')
    }
    if ($action -match '^select_continuous_operations') {
        return @('65', '66', '67')
    }
    if ($action -match '^select_observability_and_improvement') {
        return @('69', '70', '71', '72')
    }
    return @()
}

function Get-AllowedDecisionPromptIds {
    param([Parameter(Mandatory)]$State)

    $action = [string]$State.nextAction
    if ($action -match '^select_vertical_slice') {
        return @('19', '20', '21', '22')
    }
    if ($action -match '^select_next_slice_or_global_completion') {
        return @('13', '14', '15', '16', '17', '18', '25', '26', '27', '28', '29')
    }
    if ($action -match '^select_applicable_capability_or_security') {
        return @(29..38 | ForEach-Object { '{0:D2}' -f $_ })
    }
    if ($action -match '^select_growth_or_hardening') {
        return @('45', '46', '47')
    }
    if ($action -match '^select_pwa_or_continue') {
        return @('50')
    }
    if ($action -match '^select_distribution_or_operations') {
        return @('56', '57')
    }
    if ($action -match '^select_continuous_operations') {
        return @('65', '66')
    }
    if ($action -match '^select_observability_and_improvement') {
        return @('69', '71')
    }
    return @()
}

function Assert-ApplicabilityDecisions {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string[]]$PromptIds,
        [Parameter(Mandatory)][string]$BeforePrompt
    )

    $unresolved = @(
        foreach ($id in $PromptIds) {
            $prompt = Get-PromptState -State $State -Id $id
            if ($prompt.status -eq 'not_selected') {
                $id
            }
        }
    )
    if ($unresolved.Count -gt 0) {
        throw "Prompt $BeforePrompt cannot start until applicability is decided for: $($unresolved -join ', '). Use decide or execute the applicable prompt."
    }
}

function New-TaskPacket {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$Manifest
    )

    if ($null -eq $State.currentPrompt -or [string]::IsNullOrWhiteSpace([string]$State.currentPrompt)) {
        throw "There is no current prompt. Next action: $($State.nextAction)"
    }

    $id = Normalize-PromptId ([string]$State.currentPrompt)
    $promptFile = Get-PromptFile -Root $Root -Id $id
    $stage = Get-PromptStage -Manifest $Manifest -Id $id
    $promptContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $promptFile.FullName
    $relativePrompt = $promptFile.FullName.Substring($Root.Length + 1).Replace('\', '/')
    $packetPath = Join-Path $Root 'NEXT_TASK.md'

    $packet = @"
# Next lifecycle task

Process: $($State.processName)
Process ID: $($State.processId)
Initiative mode: $($State.initiativeMode)
Application root: $(if ([string]::IsNullOrWhiteSpace([string]$State.applicationRoot)) { 'pending until prompt 07' } else { $State.applicationRoot })
Stage: $($stage.id) - $($stage.name)
Prompt: $id
Source: $relativePrompt

## Execution contract

Use `$build-professional-web-software`.
Execute only this prompt in this task.
Read AGENTS.md and every mandatory document it references before acting.
Resolve material inputs from APP_CONTEXT.md, approved decisions and repository evidence.
For a brownfield initiative, treat the existing application as read-only evidence until the current prompt authorizes a scoped change. Never copy BoilerPlateAdvance over it, replace its Git history/remotes, or mark existing behavior complete without verification.
For non-trivial work, create and maintain a short staged plan before implementation.
Apply QUALITY_GATES.md and the prompt-specific acceptance criteria.
Perform the required adversarial review and do not claim independent review unless separation is real.
Update APP_CONTEXT.md, IMPLEMENTATION_STATUS.md, relevant quality artefacts and LIFECYCLE_STATE.json through the lifecycle recorder.
Do not perform GitHub, destructive, financial or production actions without exact authorization.

When the prompt finishes, record one honest result:

```powershell
.\software-lifecycle.ps1 record -ProcessRoot "$Root" -PromptId $id -Result completed -Evidence "path or durable evidence"
```

Use `partial` or `blocked` instead of `completed` when evidence is insufficient.
Omit `-NextPrompt` for deterministic transitions; the lifecycle selects them.
When a product/applicability decision is required, the result changes to
`waiting_decision` and `status` prints the valid next-action hint. After prompt
12, select a vertical slice using the workflow reference.

## Prompt

$promptContent
"@

    [System.IO.File]::WriteAllText($packetPath, $packet + [Environment]::NewLine, $utf8NoBom)
    return $packetPath
}

function Test-Lifecycle {
    param(
        [Parameter(Mandatory)][string]$Root,
        [switch]$Quiet,
        [switch]$SkipExternalGateValidators
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $manifest = Get-Manifest $Root
    $state = Get-State $Root

    if ([int]$state.schemaVersion -ne 1) {
        $issues.Add("Unsupported lifecycle state schemaVersion: $($state.schemaVersion).")
    }
    if ($null -eq $state.PSObject.Properties['revision'] -or [int64]$state.revision -lt 0) {
        $issues.Add('State revision is missing or invalid.')
    }
    elseif ([int64]$state.revision -ne [int64]@($state.history).Count) {
        $issues.Add("State revision $($state.revision) does not match history count $(@($state.history).Count).")
    }
    if ([string]$state.catalogVersion -ne [string]$manifest.catalogVersion) {
        $issues.Add("State catalogVersion '$($state.catalogVersion)' does not match manifest '$($manifest.catalogVersion)'.")
    }
    if ($null -eq $state.PSObject.Properties['initiativeMode'] -or
        [string]$state.initiativeMode -notin @('greenfield', 'brownfield')) {
        $issues.Add("State initiativeMode must be 'greenfield' or 'brownfield'.")
    }
    elseif ([string]$state.initiativeMode -eq 'brownfield') {
        if ($null -eq $state.PSObject.Properties['applicationRoot'] -or
            [string]::IsNullOrWhiteSpace([string]$state.applicationRoot)) {
            $issues.Add('Brownfield lifecycle must contain applicationRoot.')
        }
        else {
            try {
                $applicationRoot = Get-FullPath ([string]$state.applicationRoot)
                if (-not (Test-Path -LiteralPath $applicationRoot -PathType Container)) {
                    $issues.Add("Brownfield applicationRoot does not exist: $applicationRoot")
                }
                elseif ((Test-IsSameOrChild -Candidate $applicationRoot -Parent $Root) -or
                    (Test-IsSameOrChild -Candidate $Root -Parent $applicationRoot)) {
                    $issues.Add('Brownfield applicationRoot and processRoot must remain in separate directory trees.')
                }
                if ($null -ne $state.PSObject.Properties['boilerplatePath'] -and
                    -not [string]::IsNullOrWhiteSpace([string]$state.boilerplatePath)) {
                    $recordedBoilerplate = Get-FullPath ([string]$state.boilerplatePath)
                    if ((Test-IsSameOrChild -Candidate $applicationRoot -Parent $recordedBoilerplate) -or
                        (Test-IsSameOrChild -Candidate $recordedBoilerplate -Parent $applicationRoot)) {
                        $issues.Add('Brownfield applicationRoot must remain separate from BoilerplatePath.')
                    }
                }
            }
            catch {
                $issues.Add("Brownfield applicationRoot is invalid: $($_.Exception.Message)")
            }
        }
        if ($null -eq $state.PSObject.Properties['repositoryBaseline'] -or
            $null -eq $state.repositoryBaseline) {
            $issues.Add('Brownfield lifecycle must contain repositoryBaseline.')
        }
        elseif ([string]$state.repositoryBaseline.status -notin @('captured', 'not_detected', 'unavailable')) {
            $issues.Add("Brownfield repositoryBaseline has invalid status '$($state.repositoryBaseline.status)'.")
        }
        elseif (-not [string]::IsNullOrWhiteSpace([string]$state.repositoryBaseline.root)) {
            try {
                $repositoryRoot = Get-FullPath ([string]$state.repositoryBaseline.root)
                if ((Test-IsSameOrChild -Candidate $Root -Parent $repositoryRoot) -or
                    (Test-IsSameOrChild -Candidate $repositoryRoot -Parent $Root)) {
                    $issues.Add('Brownfield processRoot must remain outside the existing Git repository tree.')
                }
            }
            catch {
                $issues.Add("Brownfield repositoryBaseline root is invalid: $($_.Exception.Message)")
            }
        }
    }
    try {
        $stateRoot = Get-FullPath ([string]$state.processRoot)
        $actualRoot = Get-FullPath $Root
        if (-not $stateRoot.Equals($actualRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $issues.Add("State processRoot '$stateRoot' does not match actual root '$actualRoot'.")
        }
    }
    catch {
        $issues.Add("State processRoot is invalid: $($_.Exception.Message)")
    }
    $processGuid = [Guid]::Empty
    if (-not [Guid]::TryParse([string]$state.processId, [ref]$processGuid)) {
        $issues.Add("State processId is not a valid GUID: $($state.processId).")
    }
    if ($state.status -notin @('ready', 'partial', 'blocked', 'waiting_decision', 'completed')) {
        $issues.Add("Invalid lifecycle status: $($state.status).")
    }
    foreach ($historyItem in @($state.history)) {
        $historyTime = $(if ($null -eq $historyItem.PSObject.Properties['at']) {
            $null
        } else {
            Convert-ToTimestamp $historyItem.at
        })
        if ($null -eq $historyItem.PSObject.Properties['at'] -or
            $null -eq $historyTime) {
            $issues.Add('Lifecycle history contains an entry without a valid timestamp.')
        }
        $hasAction = $null -ne $historyItem.PSObject.Properties['action']
        $hasPromptResult = $null -ne $historyItem.PSObject.Properties['promptId'] -and
            $null -ne $historyItem.PSObject.Properties['result']
        if (-not $hasAction -and -not $hasPromptResult) {
            $issues.Add('Lifecycle history contains an unrecognized entry.')
        }
    }

    $promptFiles = @(Get-ChildItem -LiteralPath (Join-Path $Root 'prompts') -Recurse -File -Filter '*.md')
    if ($promptFiles.Count -ne [int]$manifest.promptCount) {
        $issues.Add("Expected $($manifest.promptCount) prompts; found $($promptFiles.Count).")
    }

    $numbers = @()
    foreach ($file in $promptFiles) {
        if ($file.Name -notmatch '^(\d{2})-') {
            $issues.Add("Prompt without numeric prefix: $($file.FullName)")
            continue
        }
        $numbers += [int]$Matches[1]
    }
    foreach ($number in 1..73) {
        if ($number -notin $numbers) {
            $issues.Add("Missing prompt id: $('{0:D2}' -f $number)")
        }
    }

    foreach ($id in 1..73 | ForEach-Object { '{0:D2}' -f $_ }) {
        if ($null -eq $state.prompts.PSObject.Properties[$id]) {
            $issues.Add("State is missing prompt $id.")
        }
    }

    foreach ($gateDefinition in $manifest.gates) {
        if ($null -eq $state.gates.PSObject.Properties[$gateDefinition.id]) {
            $issues.Add("State is missing gate $($gateDefinition.id).")
        }
    }

    foreach ($property in $state.prompts.PSObject.Properties) {
        $promptState = $property.Value
        if ($promptState.status -notin @($manifest.statuses)) {
            $issues.Add("Prompt $($property.Name) has invalid status '$($promptState.status)'.")
        }
        if ($promptState.applicability -notin @('required', 'conditional', 'selected')) {
            $issues.Add("Prompt $($property.Name) has invalid applicability '$($promptState.applicability)'.")
        }
        if ($promptState.status -eq 'completed' -and [string]::IsNullOrWhiteSpace([string]$promptState.evidence)) {
            $issues.Add("Completed prompt $($property.Name) has no evidence.")
        }
        if ($promptState.status -eq 'not_applicable' -and $promptState.applicability -eq 'required') {
            $issues.Add("Required prompt $($property.Name) is marked not_applicable.")
        }
    }

    $activePromptProperties = @(
        $state.prompts.PSObject.Properties |
            Where-Object { $_.Value.status -in @('ready', 'partial', 'blocked') }
    )
    $hasCurrentPrompt = $null -ne $state.currentPrompt -and
        -not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)
    if (-not $hasCurrentPrompt -and $activePromptProperties.Count -gt 0) {
        $issues.Add("Lifecycle has no currentPrompt but active prompt states exist: $($activePromptProperties.Name -join ', ').")
    }
    elseif ($hasCurrentPrompt -and
        ($activePromptProperties.Count -ne 1 -or
            [string]$activePromptProperties[0].Name -ne [string]$state.currentPrompt)) {
        $issues.Add("currentPrompt '$($state.currentPrompt)' does not uniquely match the active prompt state.")
    }

    if ($state.status -eq 'ready') {
        if (-not $hasCurrentPrompt -or [string]$state.nextAction -ne 'execute_prompt') {
            $issues.Add("Ready lifecycle must have a current prompt and nextAction 'execute_prompt'.")
        }
        if (@($state.blockers).Count -gt 0) {
            $issues.Add('Ready lifecycle cannot retain blockers.')
        }
    }
    if ($state.status -in @('partial', 'blocked')) {
        if (-not $hasCurrentPrompt -or [string]$state.nextAction -ne 'resolve_current_prompt') {
            $issues.Add("$($state.status) lifecycle must retain the current prompt and nextAction 'resolve_current_prompt'.")
        }
        if (@($state.blockers).Count -lt 1) {
            $issues.Add("$($state.status) lifecycle must contain at least one blocker.")
        }
    }
    if ($state.status -eq 'waiting_decision') {
        if ($hasCurrentPrompt) {
            $issues.Add('waiting_decision lifecycle cannot have a currentPrompt.')
        }
        $recordedCompletions = @(
            $state.history |
                Where-Object {
                    $null -eq $_.PSObject.Properties['action'] -and
                    $null -ne $_.PSObject.Properties['promptId'] -and
                    $_.result -eq 'completed'
                }
        )
        if ($recordedCompletions.Count -lt 1) {
            $issues.Add('waiting_decision lifecycle has no completed prompt transition.')
        }
        else {
            $lastCompletedId = Normalize-PromptId ([string]$recordedCompletions[-1].promptId)
            $expectedDecisionAction = Get-DecisionHint -State $state -CompletedId $lastCompletedId
            if ([string]$state.nextAction -ne $expectedDecisionAction) {
                $issues.Add("waiting_decision nextAction '$($state.nextAction)' does not match '$expectedDecisionAction'.")
            }
        }
        if (@($state.blockers).Count -gt 0) {
            $issues.Add('waiting_decision lifecycle cannot retain blockers.')
        }
    }
    if ($state.status -eq 'completed') {
        if ($hasCurrentPrompt -or [string]$state.nextAction -ne 'none') {
            $issues.Add("Completed lifecycle must have no currentPrompt and nextAction 'none'.")
        }
        if (@($state.blockers).Count -gt 0) {
            $issues.Add('Completed lifecycle cannot retain blockers.')
        }
        $g10CompletionState = Get-GateState -State $state -Id 'G10'
        if ($g10CompletionState.status -ne 'passed') {
            $issues.Add("Completed lifecycle requires G10 passed; found '$($g10CompletionState.status)'.")
        }
        if ((Get-PromptState -State $state -Id '73').status -ne 'completed') {
            $issues.Add('Completed lifecycle requires prompt 73 completed.')
        }
        $unfinishedRequired = @(
            $state.prompts.PSObject.Properties |
                Where-Object {
                    $_.Value.applicability -eq 'required' -and
                    $_.Value.status -ne 'completed'
                }
        )
        if ($unfinishedRequired.Count -gt 0) {
            $issues.Add("Completed lifecycle has unfinished required prompts: $($unfinishedRequired.Name -join ', ').")
        }
        $unresolvedSelected = @(
            $state.prompts.PSObject.Properties |
                Where-Object {
                    $_.Value.applicability -eq 'selected' -and
                    $_.Value.status -notin @('completed', 'not_applicable')
                }
        )
        if ($unresolvedSelected.Count -gt 0) {
            $issues.Add("Completed lifecycle has unresolved selected prompts: $($unresolvedSelected.Name -join ', ').")
        }
    }

    foreach ($gateProperty in $state.gates.PSObject.Properties) {
        $gateDefinition = @($manifest.gates | Where-Object { $_.id -eq $gateProperty.Name })[0]
        $gateState = $gateProperty.Value
        if ($gateState.status -notin @('pending', 'passed', 'failed')) {
            $issues.Add("Gate $($gateProperty.Name) has invalid status '$($gateState.status)'.")
        }
        if ($gateState.status -eq 'passed') {
            if ([string]::IsNullOrWhiteSpace([string]$gateState.evidence)) {
                $issues.Add("Passed gate $($gateProperty.Name) has no evidence.")
            }
            if ([bool]$gateDefinition.humanApproval -and [string]::IsNullOrWhiteSpace([string]$gateState.approvedBy)) {
                $issues.Add("Human gate $($gateProperty.Name) passed without an approver.")
            }
            try {
                Test-GatePrerequisites -State $state -GateDefinition $gateDefinition
                if (-not $SkipExternalGateValidators) {
                    Invoke-ManifestGateValidator -Root $Root -GateDefinition $gateDefinition `
                        -RecordedApprover ([string]$gateState.approvedBy)
                }
                Test-GateSnapshot -State $state -Root $Root -GateId $gateProperty.Name
                if ($gateProperty.Name -eq 'G09' -and -not $SkipExternalGateValidators) {
                    $releasePrompt = Get-PromptState -State $state -Id '64'
                    if ($releasePrompt.status -eq 'completed') {
                        $releaseValidator = Join-Path $Root 'scripts/Test-LifecycleGateEvidence.ps1'
                        $releaseValidatorOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $releaseValidator `
                            -GateId G09 -ProcessRoot $Root -Phase release_completed
                        $releaseValidatorExitCode = $LASTEXITCODE
                        $releaseValidatorOutput | Out-Host
                        if ($releaseValidatorExitCode -ne 0) {
                            throw 'G09 release-completion evidence failed revalidation.'
                        }
                    }
                }
            }
            catch {
                $issues.Add("Passed gate $($gateProperty.Name) failed revalidation: $($_.Exception.Message)")
            }
        }
    }
    if ($null -eq $state.PSObject.Properties['slices']) {
        $issues.Add('State does not contain durable slice history.')
    }
    else {
        $sliceIds = @()
        foreach ($slice in @($state.slices)) {
            $sliceIds += [string]$slice.id
            foreach ($field in @('id', 'kind', 'surface', 'requirements', 'acceptanceCriteria', 'outOfScope', 'evidence', 'status')) {
                if ($null -eq $slice.PSObject.Properties[$field] -or
                    [string]::IsNullOrWhiteSpace([string]$slice.$field)) {
                    $issues.Add("Slice '$($slice.id)' is missing $field.")
                }
            }
            if ($slice.kind -notin @('page', 'feature')) {
                $issues.Add("Slice '$($slice.id)' has invalid kind '$($slice.kind)'.")
            }
            if ($slice.surface -notin @('ssr', 'web', 'maui')) {
                $issues.Add("Slice '$($slice.id)' has invalid surface '$($slice.surface)'.")
            }
            if ($slice.status -notin @('in_progress', 'completed')) {
                $issues.Add("Slice '$($slice.id)' has invalid status '$($slice.status)'.")
            }
            if ($slice.status -eq 'completed') {
                $completedTime = $(if ($null -eq $slice.PSObject.Properties['completedAt']) {
                    $null
                } else {
                    Convert-ToTimestamp $slice.completedAt
                })
                if ($null -eq $slice.PSObject.Properties['completedAt'] -or
                    $null -eq $completedTime) {
                    $issues.Add("Completed slice '$($slice.id)' has no valid completedAt timestamp.")
                }
                if ($null -eq $slice.PSObject.Properties['completionEvidence'] -or
                    [string]::IsNullOrWhiteSpace([string]$slice.completionEvidence)) {
                    $issues.Add("Completed slice '$($slice.id)' has no completionEvidence.")
                }
            }
        }
        foreach ($duplicate in @($sliceIds | Group-Object | Where-Object { $_.Count -gt 1 })) {
            $issues.Add("Duplicate slice id in durable history: $($duplicate.Name).")
        }
        if (@($state.slices).Count -gt 0 -and $null -eq $state.activeSlice) {
            $issues.Add('Durable slice history exists without an activeSlice pointer.')
        }
        elseif ($null -ne $state.activeSlice) {
            $activeMatches = @($state.slices | Where-Object { $_.id -eq $state.activeSlice.id })
            if ($activeMatches.Count -ne 1) {
                $issues.Add("Active slice '$($state.activeSlice.id)' must match exactly one durable slice record.")
            }
            else {
                $activeRecord = $activeMatches[0]
                foreach ($field in @('id', 'kind', 'surface', 'requirements', 'acceptanceCriteria', 'outOfScope', 'evidence', 'status')) {
                    if ([string]$state.activeSlice.$field -ne [string]$activeRecord.$field) {
                        $issues.Add("Active slice '$($state.activeSlice.id)' differs from durable history field '$field'.")
                    }
                }
                if ($activeRecord.status -eq 'completed') {
                    foreach ($field in @('completedAt', 'completionEvidence')) {
                        if ([string]$state.activeSlice.$field -ne [string]$activeRecord.$field) {
                            $issues.Add("Completed active slice '$($state.activeSlice.id)' differs from durable history field '$field'.")
                        }
                    }
                }
            }
        }
    }

    if ($null -ne $state.currentPrompt -and -not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
        try {
            $currentId = Normalize-PromptId ([string]$state.currentPrompt)
            Get-PromptFile -Root $Root -Id $currentId | Out-Null
            $currentStage = Get-PromptStage -Manifest $manifest -Id $currentId
            if ($currentStage.id -ne $state.currentStage) {
                $issues.Add("Current stage $($state.currentStage) does not match prompt $currentId stage $($currentStage.id).")
            }
            $currentPromptState = Get-PromptState -State $state -Id $currentId
            $expectedPromptStatus = $(if ($state.status -in @('partial', 'blocked')) { $state.status } else { 'ready' })
            if ($currentPromptState.status -ne $expectedPromptStatus) {
                $issues.Add("Current prompt $currentId has status '$($currentPromptState.status)' instead of '$expectedPromptStatus'.")
            }
            Test-EntryGate -State $state -Manifest $manifest -NextId $currentId
        }
        catch {
            $issues.Add($_.Exception.Message)
        }
    }
    elseif ($state.status -notin @('waiting_decision', 'completed')) {
        $issues.Add("Lifecycle has no current prompt but status is '$($state.status)'.")
    }

    if ($issues.Count -gt 0) {
        if (-not $Quiet) {
            Write-Host "FAIL: lifecycle validation found $($issues.Count) issue(s)." -ForegroundColor Red
            $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
        }
        return $false
    }

    if (-not $Quiet) {
        Write-Host 'PASS: lifecycle instance is structurally valid.' -ForegroundColor Green
        Write-Host " - Prompts: $($promptFiles.Count)"
        Write-Host " - Current stage/prompt: $($state.currentStage)/$($state.currentPrompt)"
        Write-Host " - Status: $($state.status)"
    }
    return $true
}

function ConvertTo-InitiativeSlug {
    param([Parameter(Mandatory)][string]$Value)

    $normalized = $Value.Normalize([System.Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($character in $normalized.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($character) -ne
            [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($character)
        }
    }
    $slug = $builder.ToString().Normalize([System.Text.NormalizationForm]::FormC).ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        $slug = 'advance-project'
    }
    if ($slug.Length -lt 2) {
        $slug = "app-$slug"
    }
    if ($slug.Length -gt 63) {
        $slug = $slug.Substring(0, 63).TrimEnd('-')
    }
    return $slug
}

function Find-GitMetadataRoot {
    param([Parameter(Mandatory)][string]$Path)

    $current = Get-PhysicalPath $Path
    while (-not [string]::IsNullOrWhiteSpace($current)) {
        if (Test-Path -LiteralPath (Join-Path $current '.git')) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or
            $parent.Equals($current, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $current = $parent
    }
    return $null
}

function Get-RepositoryBaseline {
    param([Parameter(Mandatory)][string]$ApplicationRoot)

    $capturedAt = [DateTimeOffset]::Now.ToString('o')
    $metadataRoot = Find-GitMetadataRoot -Path $ApplicationRoot
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return [ordered]@{
            status = 'unavailable'
            root = $metadataRoot
            head = $null
            branch = $null
            dirty = $null
            changeCount = $null
            remoteCount = $null
            capturedAt = $capturedAt
        }
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $repositoryRootOutput = @(& $gitCommand.Source --no-optional-locks -C $ApplicationRoot rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -ne 0 -or $repositoryRootOutput.Count -ne 1) {
            return [ordered]@{
                status = $(if ($null -eq $metadataRoot) { 'not_detected' } else { 'unavailable' })
                root = $metadataRoot
                head = $null
                branch = $null
                dirty = $null
                changeCount = $null
                remoteCount = $null
                capturedAt = $capturedAt
            }
        }

        $repositoryRoot = Get-FullPath ([string]$repositoryRootOutput[0])
        $headOutput = @(& $gitCommand.Source --no-optional-locks -C $repositoryRoot rev-parse HEAD 2>$null)
        $head = $(if ($LASTEXITCODE -eq 0 -and $headOutput.Count -eq 1) { [string]$headOutput[0] } else { $null })
        $branchOutput = @(& $gitCommand.Source --no-optional-locks -C $repositoryRoot branch --show-current 2>$null)
        $branch = $(if ($LASTEXITCODE -eq 0 -and $branchOutput.Count -eq 1 -and
            -not [string]::IsNullOrWhiteSpace([string]$branchOutput[0])) {
            [string]$branchOutput[0]
        } else {
            $null
        })
        $statusOutput = @(& $gitCommand.Source --no-optional-locks -C $repositoryRoot status --porcelain=v1 --untracked-files=normal 2>$null)
        $changeCount = $(if ($LASTEXITCODE -eq 0) { $statusOutput.Count } else { $null })
        $remoteOutput = @(& $gitCommand.Source --no-optional-locks -C $repositoryRoot remote 2>$null)
        $remoteCount = $(if ($LASTEXITCODE -eq 0) { $remoteOutput.Count } else { $null })

        return [ordered]@{
            status = 'captured'
            root = $repositoryRoot
            head = $head
            branch = $branch
            dirty = $(if ($null -eq $changeCount) { $null } else { $changeCount -gt 0 })
            changeCount = $changeCount
            remoteCount = $remoteCount
            capturedAt = $capturedAt
        }
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Test-StateApplicationMatch {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$ApplicationRoot
    )

    if ($null -eq $State.PSObject.Properties['applicationRoot'] -or
        [string]::IsNullOrWhiteSpace([string]$State.applicationRoot)) {
        return $false
    }
    try {
        $recordedRoot = Get-PhysicalPath ([string]$State.applicationRoot)
        $requestedRoot = Get-PhysicalPath $ApplicationRoot
        return $recordedRoot.Equals($requestedRoot, [System.StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        return $false
    }
}

function New-LifecycleInstance {
    param(
        [Parameter(Mandatory)][string]$DestinationRoot,
        [Parameter(Mandatory)][string]$ProcessName,
        [AllowNull()][string]$ProductOwner,
        [Parameter(Mandatory)][string]$BoilerplateRoot,
        [Parameter(Mandatory)][ValidateSet('greenfield', 'brownfield')][string]$InitiativeMode,
        [AllowNull()][string]$ApplicationRoot,
        [AllowNull()]$RepositoryBaseline
    )

    $manifest = Get-Manifest $catalogRoot
    New-Item -ItemType Directory -Path $DestinationRoot | Out-Null
    if (Test-IsSameOrChild -Candidate $DestinationRoot -Parent $catalogRoot) {
        throw 'ProcessRoot resolved inside the prompt catalog after creation; refusing to copy.'
    }
    if (Test-IsSameOrChild -Candidate $DestinationRoot -Parent $BoilerplateRoot) {
        throw 'ProcessRoot resolved inside BoilerplatePath after creation; refusing to copy.'
    }
    if ($InitiativeMode -eq 'brownfield' -and
        ((Test-IsSameOrChild -Candidate $DestinationRoot -Parent $ApplicationRoot) -or
            (Test-IsSameOrChild -Candidate $ApplicationRoot -Parent $DestinationRoot))) {
        throw 'ProcessRoot and the existing application must remain in separate directory trees.'
    }

    foreach ($directory in @('prompts', 'pilot', 'scripts', '.agents')) {
        Copy-Item -LiteralPath (Join-Path $catalogRoot $directory) -Destination $DestinationRoot -Recurse
    }
    foreach ($file in @(
        'AGENTS.md',
        'APP_CONTEXT.md',
        'EXECUTION_CONTRACT.md',
        'IMPLEMENTATION_STATUS.md',
        'LIFECYCLE_GATE_EVIDENCE.json',
        'PILOT_APPROVAL.md',
        'PRODUCT_DEFINITION.md',
        'PRODUCT_EXCELLENCE.md',
        'PRODUCT_QUALITY_BASELINE.md',
        'PROMPT_EVALUATION.md',
        'QUALITY_GATES.md',
        'PROCESS_MANIFEST.json',
        'START_HERE.md',
        'README.md',
        'software-lifecycle.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $catalogRoot $file) -Destination $DestinationRoot
    }

    $instanceContextPath = Join-Path $DestinationRoot 'APP_CONTEXT.md'
    $context = Get-Content -Raw -Encoding UTF8 -LiteralPath $instanceContextPath
    $today = [DateTimeOffset]::Now.ToString('yyyy-MM-dd')
    if (-not [string]::IsNullOrWhiteSpace($ProductOwner)) {
        $context = [regex]::Replace(
            $context,
            '(?m)^\|\s*Respons.vel pelo contexto\s*\|.*$',
            "| Responsavel pelo contexto | $ProductOwner | confirmado | software-lifecycle.ps1 | $today |",
            1)
    }
    $context = [regex]::Replace(
        $context,
        '(?m)^\|\s*Modo da iniciativa\s*\|.*$',
        "| Modo da iniciativa | $InitiativeMode | confirmado | software-lifecycle.ps1 | $today |",
        1)
    $context = [regex]::Replace(
        $context,
        '(?m)^\|\s*Raiz do BoilerPlateAdvance\s*\|.*$',
        "| Raiz do BoilerPlateAdvance | $BoilerplateRoot | confirmado | Sistema de ficheiros |",
        1)
    if ($InitiativeMode -eq 'brownfield') {
        $context = [regex]::Replace(
            $context,
            '(?m)^\|\s*Raiz da aplica..o\s*\|.*$',
            "| Raiz da aplicacao | $ApplicationRoot | confirmado | software-lifecycle.ps1 |",
            1)
        if ($null -ne $RepositoryBaseline -and
            -not [string]::IsNullOrWhiteSpace([string]$RepositoryBaseline.head)) {
            $context = [regex]::Replace(
                $context,
                '(?m)^\|\s*Commit ou vers.o de refer.ncia\s*\|.*$',
                "| Commit ou versao de referencia | $($RepositoryBaseline.head) | confirmado | Git | $today |",
                1)
        }
    }
    [System.IO.File]::WriteAllText($instanceContextPath, $context, $utf8NoBom)

    $promptMap = [ordered]@{}
    $instancePromptFiles = @(Get-ChildItem -LiteralPath (Join-Path $DestinationRoot 'prompts') -Recurse -File -Filter '*.md' | Sort-Object Name)
    foreach ($file in $instancePromptFiles) {
        if ($file.Name -notmatch '^(\d{2})-') {
            continue
        }
        $id = $Matches[1]
        $stage = Get-PromptStage -Manifest $manifest -Id $id
        $isConditional = $file.FullName -match '[\\/]Optional[\\/]'
        if ($stage.PSObject.Properties.Name -contains 'conditionalPromptIds') {
            $isConditional = $isConditional -or (@($stage.conditionalPromptIds) -contains $id)
        }
        $title = (Get-Content -Encoding UTF8 -LiteralPath $file.FullName -TotalCount 1) -replace '^#\s*', ''
        $promptMap[$id] = [ordered]@{
            title = $title
            path = $file.FullName.Substring($DestinationRoot.Length + 1).Replace('\', '/')
            stage = $stage.id
            applicability = $(if ($isConditional) { 'conditional' } else { 'required' })
            status = $(if ($id -eq '01') { 'ready' } elseif ($isConditional) { 'not_selected' } else { 'pending' })
            evidence = $null
            attempts = @()
        }
    }

    $gateMap = [ordered]@{}
    foreach ($gate in $manifest.gates) {
        $gateMap[$gate.id] = [ordered]@{
            name = $gate.name
            status = 'pending'
            evidence = $null
            approvedBy = $null
            updatedAt = $null
            snapshot = $null
        }
    }

    $state = [ordered]@{
        schemaVersion = 1
        revision = 0
        catalogVersion = $manifest.catalogVersion
        processId = [Guid]::NewGuid().ToString()
        processName = $ProcessName
        productOwner = $(if ([string]::IsNullOrWhiteSpace($ProductOwner)) { $null } else { $ProductOwner })
        processRoot = $DestinationRoot
        boilerplatePath = $BoilerplateRoot
        initiativeMode = $InitiativeMode
        applicationRoot = $ApplicationRoot
        repositoryBaseline = $RepositoryBaseline
        createdAt = [DateTimeOffset]::Now.ToString('o')
        updatedAt = [DateTimeOffset]::Now.ToString('o')
        status = 'ready'
        currentStage = '01'
        currentPrompt = '01'
        nextAction = 'execute_prompt'
        activeSlice = $null
        slices = @()
        selectedSurfaces = @()
        selectedOptionalPromptIds = @()
        gates = $gateMap
        prompts = $promptMap
        blockers = @()
        history = @()
    }
    $json = $state | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText((Get-StatePath $DestinationRoot), $json + [Environment]::NewLine, $utf8NoBom)

    $loadedState = Get-State $DestinationRoot
    $packet = New-TaskPacket -Root $DestinationRoot -State $loadedState -Manifest $manifest
    if (-not (Test-Lifecycle -Root $DestinationRoot -Quiet)) {
        throw 'The new lifecycle instance failed structural validation.'
    }
    return [pscustomobject]@{
        Root = $DestinationRoot
        Packet = $packet
        State = $loadedState
        Manifest = $manifest
    }
}

$Command = $Command.ToLowerInvariant()

if ($Command -in @('start', 'adopt', 'continue')) {
    $isBrownfieldCommand = $Command -in @('adopt', 'continue')
    if ($isBrownfieldCommand) {
        Require-SafeText -Value $ProjectPath -Label 'ProjectPath'
        $ProjectPath = Get-FullPath $ProjectPath
        if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
            throw "ProjectPath does not exist: $ProjectPath"
        }
        if ((Test-IsSameOrChild -Candidate $ProjectPath -Parent $catalogRoot) -or
            (Test-IsSameOrChild -Candidate $catalogRoot -Parent $ProjectPath)) {
            throw 'ProjectPath must be outside and must not contain the prompt catalog.'
        }
        if ([string]::IsNullOrWhiteSpace($Name)) {
            $Name = ConvertTo-InitiativeSlug (Split-Path $ProjectPath -Leaf)
        }
    }

    Require-SafeText -Value $Name -Label 'Name'
    if ($Command -eq 'start') {
        Require-SafeText -Value $Owner -Label 'Owner'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($Owner)) {
        Require-SafeText -Value $Owner -Label 'Owner'
    }
    if ($Name -notmatch '^[a-z0-9][a-z0-9-]{1,62}$') {
        throw 'Name must use 2-63 lowercase letters, digits or hyphens.'
    }

    if ([string]::IsNullOrWhiteSpace($ProcessRoot)) {
        $ProcessRoot = Join-Path (Split-Path $catalogRoot -Parent) "SoftwareProcesses\$Name"
    }
    $ProcessRoot = Get-FullPath $ProcessRoot

    if ($Command -eq 'continue') {
        $projectPathIsProcessRoot = $false
        $directStatePath = Join-Path $ProjectPath 'LIFECYCLE_STATE.json'
        if (Test-Path -LiteralPath $directStatePath -PathType Leaf) {
            $ProcessRoot = $ProjectPath
            $projectPathIsProcessRoot = $true
        }
        elseif (-not (Test-Path -LiteralPath (Join-Path $ProcessRoot 'LIFECYCLE_STATE.json') -PathType Leaf) -and
            [string]::IsNullOrWhiteSpace($PSBoundParameters['ProcessRoot'])) {
            $processContainer = Split-Path $ProcessRoot -Parent
            if (Test-Path -LiteralPath $processContainer -PathType Container) {
                $matchingRoots = @(
                    Get-ChildItem -LiteralPath $processContainer -Directory |
                        ForEach-Object {
                            $candidateStatePath = Join-Path $_.FullName 'LIFECYCLE_STATE.json'
                            if (Test-Path -LiteralPath $candidateStatePath -PathType Leaf) {
                                try {
                                    $candidateState = Get-Content -Raw -Encoding UTF8 -LiteralPath $candidateStatePath | ConvertFrom-Json
                                    if (Test-StateApplicationMatch -State $candidateState -ApplicationRoot $ProjectPath) {
                                        $_.FullName
                                    }
                                }
                                catch {
                                    # Ignore unrelated or malformed lifecycle directories during discovery.
                                }
                            }
                        }
                )
                if ($matchingRoots.Count -gt 1) {
                    throw "Multiple lifecycle instances reference ProjectPath; specify -ProcessRoot explicitly: $($matchingRoots -join ', ')"
                }
                if ($matchingRoots.Count -eq 1) {
                    $ProcessRoot = Get-FullPath $matchingRoots[0]
                }
            }
        }

        if (Test-Path -LiteralPath $ProcessRoot) {
            $existingStatePath = Join-Path $ProcessRoot 'LIFECYCLE_STATE.json'
            if (-not (Test-Path -LiteralPath $existingStatePath -PathType Leaf)) {
                throw "ProcessRoot already exists without LIFECYCLE_STATE.json; no files were overwritten: $ProcessRoot"
            }
            $existingState = Get-State $ProcessRoot
            if ($null -ne $existingState.PSObject.Properties['initiativeMode'] -and
                [string]$existingState.initiativeMode -eq 'brownfield' -and
                -not $projectPathIsProcessRoot -and
                -not (Test-StateApplicationMatch -State $existingState -ApplicationRoot $ProjectPath)) {
                throw "ProcessRoot belongs to another application: $ProcessRoot"
            }
            $existingManifest = Get-Manifest $ProcessRoot
            if (-not (Test-Lifecycle -Root $ProcessRoot)) {
                exit 1
            }
            $existingPacket = New-TaskPacket -Root $ProcessRoot -State $existingState -Manifest $existingManifest
            Write-Host 'PASS: lifecycle resolved and validated.' -ForegroundColor Green
            Write-Host " - Mode: $($existingState.initiativeMode)"
            Write-Host " - Application: $(if ([string]::IsNullOrWhiteSpace([string]$existingState.applicationRoot)) { $ProjectPath } else { $existingState.applicationRoot })"
            Write-Host " - Process: $ProcessRoot"
            Write-Host " - Current stage/prompt: $($existingState.currentStage)/$($existingState.currentPrompt)"
            Write-Host " - Status: $($existingState.status)"
            Write-Host " - Next task: $existingPacket"
            Write-Host " - Prompt: Use `$build-professional-web-software and execute NEXT_TASK.md."
            exit 0
        }
    }

    if (Test-IsSameOrChild -Candidate $ProcessRoot -Parent $catalogRoot) {
        throw 'ProcessRoot must be outside the prompt catalog to avoid recursive copies and shared mutable state.'
    }
    if (Test-Path -LiteralPath $ProcessRoot) {
        throw "ProcessRoot already exists; no files were overwritten: $ProcessRoot"
    }

    if ([string]::IsNullOrWhiteSpace($BoilerplatePath)) {
        $BoilerplatePath = Join-Path (Split-Path $catalogRoot -Parent) 'BoilerPlateAdvance'
    }
    $BoilerplatePath = Get-FullPath $BoilerplatePath
    if (-not (Test-Path -LiteralPath $BoilerplatePath -PathType Container)) {
        throw "BoilerplatePath does not exist: $BoilerplatePath"
    }
    Require-SafeText -Value $BoilerplatePath -Label 'BoilerplatePath'
    if (Test-IsSameOrChild -Candidate $ProcessRoot -Parent $BoilerplatePath) {
        throw 'ProcessRoot must be outside BoilerplatePath to keep the source immutable and avoid recursive application state.'
    }
    if ($isBrownfieldCommand) {
        if ((Test-IsSameOrChild -Candidate $ProjectPath -Parent $BoilerplatePath) -or
            (Test-IsSameOrChild -Candidate $BoilerplatePath -Parent $ProjectPath)) {
            throw 'ProjectPath must be separate from BoilerplatePath; the immutable base cannot be adopted as an application.'
        }
        if ((Test-IsSameOrChild -Candidate $ProcessRoot -Parent $ProjectPath) -or
            (Test-IsSameOrChild -Candidate $ProjectPath -Parent $ProcessRoot)) {
            throw 'ProcessRoot and ProjectPath must be in separate directory trees.'
        }
    }

    $repositoryBaseline = $(if ($isBrownfieldCommand) {
        Get-RepositoryBaseline -ApplicationRoot $ProjectPath
    } else {
        [ordered]@{
            status = 'not_created'
            root = $null
            head = $null
            branch = $null
            dirty = $null
            changeCount = $null
            remoteCount = $null
            capturedAt = [DateTimeOffset]::Now.ToString('o')
        }
    })
    if ($isBrownfieldCommand -and
        -not [string]::IsNullOrWhiteSpace([string]$repositoryBaseline.root) -and
        ((Test-IsSameOrChild -Candidate $ProcessRoot -Parent $repositoryBaseline.root) -or
            (Test-IsSameOrChild -Candidate $repositoryBaseline.root -Parent $ProcessRoot))) {
        throw 'ProcessRoot must be outside the existing Git repository tree so adoption does not change its working tree.'
    }
    $instance = New-LifecycleInstance `
        -DestinationRoot $ProcessRoot `
        -ProcessName $Name `
        -ProductOwner $Owner `
        -BoilerplateRoot $BoilerplatePath `
        -InitiativeMode $(if ($isBrownfieldCommand) { 'brownfield' } else { 'greenfield' }) `
        -ApplicationRoot $(if ($isBrownfieldCommand) { $ProjectPath } else { $null }) `
        -RepositoryBaseline $repositoryBaseline

    Write-Host $(if ($isBrownfieldCommand) {
        'PASS: existing application adopted into an isolated lifecycle.'
    } else {
        'PASS: lifecycle instance created.'
    }) -ForegroundColor Green
    Write-Host " - Mode: $($instance.State.initiativeMode)"
    if ($isBrownfieldCommand) {
        Write-Host " - Application: $ProjectPath"
        Write-Host " - Repository baseline: $($repositoryBaseline.status)"
        if ($repositoryBaseline.status -eq 'captured') {
            Write-Host " - Baseline HEAD: $(if ([string]::IsNullOrWhiteSpace([string]$repositoryBaseline.head)) { 'unborn' } else { $repositoryBaseline.head })"
            Write-Host " - Working tree dirty: $($repositoryBaseline.dirty)"
        }
        Write-Host ' - Existing application files, Git history and remotes: unchanged'
    }
    Write-Host " - Process: $($instance.Root)"
    Write-Host " - Next task: $($instance.Packet)"
    Write-Host " - Prompt: Use `$build-professional-web-software and execute NEXT_TASK.md."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProcessRoot)) {
    throw 'ProcessRoot is required for this command.'
}
$ProcessRoot = Get-FullPath $ProcessRoot
if (-not (Test-Path -LiteralPath $ProcessRoot -PathType Container)) {
    throw "ProcessRoot does not exist: $ProcessRoot"
}

$manifest = Get-Manifest $ProcessRoot
$state = Get-State $ProcessRoot

if ($Command -eq 'validate') {
    if (-not (Test-Lifecycle -Root $ProcessRoot)) {
        exit 1
    }
    exit 0
}

if (-not (Test-Lifecycle -Root $ProcessRoot -Quiet -SkipExternalGateValidators)) {
    throw 'Lifecycle validation failed before command execution; run validate for details. No state was changed.'
}

if ($Command -eq 'status') {
    $allPrompts = @($state.prompts.PSObject.Properties)
    $required = @($allPrompts | Where-Object { $_.Value.applicability -eq 'required' })
    $requiredDone = @($required | Where-Object { $_.Value.status -eq 'completed' }).Count
    $selectedOptionalPrompts = @($allPrompts | Where-Object { $_.Value.applicability -eq 'selected' })
    $selectedOptionalDone = @(
        $selectedOptionalPrompts |
            Where-Object { $_.Value.status -in @('completed', 'not_applicable') }
    ).Count
    $optionalUndecided = @($allPrompts | Where-Object { $_.Value.status -eq 'not_selected' }).Count
    $blocked = @($allPrompts | Where-Object { $_.Value.status -eq 'blocked' }).Count
    $currentStageDefinition = @($manifest.stages | Where-Object { $_.id -eq $state.currentStage })[0]
    $stagePromptIds = @($currentStageDefinition.promptIds)
    $stageApplicable = @(
        $allPrompts |
            Where-Object {
                $_.Name -in $stagePromptIds -and
                $_.Value.status -ne 'not_selected'
            }
    )
    $stageDone = @(
        $stageApplicable |
            Where-Object { $_.Value.status -in @('completed', 'not_applicable') }
    ).Count
    Write-Host "Process: $($state.processName)"
    Write-Host "Root: $ProcessRoot"
    Write-Host "Initiative mode: $($state.initiativeMode)"
    if (-not [string]::IsNullOrWhiteSpace([string]$state.applicationRoot)) {
        Write-Host "Application root: $($state.applicationRoot)"
    }
    Write-Host "Status: $($state.status)"
    Write-Host "Current stage/prompt: $($state.currentStage)/$($state.currentPrompt)"
    Write-Host "Required progress: $requiredDone/$($required.Count) completed"
    Write-Host "Selected optional progress: $selectedOptionalDone/$($selectedOptionalPrompts.Count) decided"
    Write-Host "Optional decisions remaining: $optionalUndecided"
    Write-Host "Current-stage applicable progress: $stageDone/$($stageApplicable.Count)"
    Write-Host "Blocked prompts: $blocked"
    Write-Host "Vertical slices recorded: $(@($state.slices).Count)"
    if ($null -ne $state.activeSlice) {
        Write-Host "Active/latest slice: $($state.activeSlice.id) [$($state.activeSlice.kind)/$($state.activeSlice.surface)] $($state.activeSlice.status)"
        Write-Host " - Requirements: $($state.activeSlice.requirements)"
        Write-Host " - Acceptance: $($state.activeSlice.acceptanceCriteria)"
        Write-Host " - Out of scope: $($state.activeSlice.outOfScope)"
    }
    Write-Host "Next action: $($state.nextAction)"
    Write-Host 'Gates:'
    foreach ($gate in $state.gates.PSObject.Properties) {
        Write-Host " - $($gate.Name): $($gate.Value.status)"
    }
    if (@($state.blockers).Count -gt 0) {
        Write-Host 'Blockers:'
        @($state.blockers) | ForEach-Object { Write-Host " - $_" }
    }
    if ($state.status -eq 'ready') {
        Write-Host "Next command: .\software-lifecycle.ps1 next -ProcessRoot `"$ProcessRoot`""
    }
    elseif ($state.status -eq 'waiting_decision') {
        Write-Host "Decision required: $($state.nextAction)"
        $allowedSelections = @(Get-AllowedSelectionPromptIds -State $state)
        $allowedDecisions = @(Get-AllowedDecisionPromptIds -State $state)
        $routableSelections = @()
        $blockedSelections = @()
        $requiredGateIds = @()
        foreach ($selection in $allowedSelections) {
            try {
                Test-EntryGate -State $state -Manifest $manifest -NextId $selection
                $routableSelections += $selection
            }
            catch {
                $blockedSelections += "${selection}: $($_.Exception.Message)"
                $selectionStage = Get-PromptStage -Manifest $manifest -Id $selection
                if (-not [string]::IsNullOrWhiteSpace([string]$selectionStage.entryGate)) {
                    $entryGateState = Get-GateState -State $state -Id ([string]$selectionStage.entryGate)
                    if ($entryGateState.status -ne 'passed') {
                        $requiredGateIds += [string]$selectionStage.entryGate
                    }
                }
                if ($selection -eq '64') {
                    foreach ($releaseGateId in @('G08', 'G09')) {
                        if ((Get-GateState -State $state -Id $releaseGateId).status -ne 'passed') {
                            $requiredGateIds += $releaseGateId
                        }
                    }
                }
            }
        }
        if ($routableSelections.Count -gt 0) {
            Write-Host "Allowed selections: $($routableSelections -join ', ')"
            Write-Host "Select command: .\software-lifecycle.ps1 select -ProcessRoot `"$ProcessRoot`" -PromptId <ID> -Evidence `"<approved evidence>`""
        }
        if ($blockedSelections.Count -gt 0) {
            Write-Host 'Selections blocked by gates:'
            $blockedSelections | ForEach-Object { Write-Host " - $_" }
        }
        foreach ($requiredGateId in @($requiredGateIds | Sort-Object -Unique)) {
            Write-Host "Gate command first: .\software-lifecycle.ps1 gate -ProcessRoot `"$ProcessRoot`" -GateId $requiredGateId -GateDecision passed -GateEvidence `"LIFECYCLE_GATE_EVIDENCE.json#$requiredGateId`" -ApprovedBy `"<matching approver name>`""
        }
        if ($state.nextAction -match '^complete_G10_gate') {
            Write-Host "Gate command first: .\software-lifecycle.ps1 gate -ProcessRoot `"$ProcessRoot`" -GateId G10 -GateDecision passed -GateEvidence `"LIFECYCLE_GATE_EVIDENCE.json#G10`""
        }
        if ($allowedDecisions.Count -gt 0) {
            Write-Host "Optional applicability decisions: $($allowedDecisions -join ', ')"
            Write-Host "Not-applicable command: .\software-lifecycle.ps1 decide -ProcessRoot `"$ProcessRoot`" -PromptId <ID> -Result not_applicable -Evidence `"<approved decision>`""
        }
        if ($state.nextAction -match '^select_vertical_slice') {
            Write-Host 'Vertical-slice fields: -SliceId <ID> -SliceKind <page|feature> -Surface <ssr|web|maui> -Requirements "<IDs>" -AcceptanceCriteria "<observable criteria>" -OutOfScope "<explicit exclusions>"'
        }
    }
    exit 0
}

if ($Command -eq 'next') {
    $packet = New-TaskPacket -Root $ProcessRoot -State $state -Manifest $manifest
    Write-Host "PASS: task packet prepared: $packet" -ForegroundColor Green
    Write-Host "Prompt: Use `$build-professional-web-software and execute NEXT_TASK.md."
    exit 0
}

if ($Command -eq 'select') {
    $selectedId = Normalize-PromptId $PromptId
    if ($null -eq $selectedId) {
        throw 'PromptId is required for select.'
    }
    if ($null -ne $state.currentPrompt -and -not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
        throw "Cannot select prompt $selectedId while prompt $($state.currentPrompt) is active."
    }
    if ($state.status -ne 'waiting_decision') {
        throw "Prompt selection requires lifecycle status waiting_decision; found '$($state.status)'."
    }
    Require-SafeText -Value $Evidence -Label 'Evidence'
    $allowedSelections = @(Get-AllowedSelectionPromptIds -State $state)
    if ($selectedId -notin $allowedSelections) {
        $allowedText = $(if ($allowedSelections.Count -eq 0) { 'none' } else { $allowedSelections -join ', ' })
        throw "Prompt $selectedId is not valid for '$($state.nextAction)'. Allowed: $allowedText."
    }
    $selectedPromptState = Get-PromptState -State $state -Id $selectedId
    $repeatableIds = @(
        $manifest.stages |
            ForEach-Object {
                if ($_.PSObject.Properties.Name -contains 'repeatablePromptIds') {
                    @($_.repeatablePromptIds)
                }
            }
    )
    if ($selectedPromptState.status -eq 'completed' -and $selectedId -notin $repeatableIds) {
        throw "Prompt $selectedId is already completed and is not repeatable."
    }
    switch ($selectedId) {
        '23' {
            Assert-ApplicabilityDecisions -State $state `
                -PromptIds @('13', '14', '15', '16', '17', '18', '25', '26', '27', '28') `
                -BeforePrompt $selectedId
        }
        '39' {
            Assert-ApplicabilityDecisions -State $state `
                -PromptIds @(29..38 | ForEach-Object { '{0:D2}' -f $_ }) `
                -BeforePrompt $selectedId
        }
        '48' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('45', '46', '47') -BeforePrompt $selectedId
        }
        '51' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('50') -BeforePrompt $selectedId
        }
        '58' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('56', '57') -BeforePrompt $selectedId
        }
        '67' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('65', '66') -BeforePrompt $selectedId
        }
        '70' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('69') -BeforePrompt $selectedId
        }
        '72' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('69', '71') -BeforePrompt $selectedId
        }
    }

    if ($selectedId -in @('19', '25', '27')) {
        Require-SafeText -Value $SliceId -Label 'SliceId'
        if ([string]::IsNullOrWhiteSpace($SliceKind)) {
            throw 'SliceKind is required when selecting a vertical-slice prompt.'
        }
        if ([string]::IsNullOrWhiteSpace($Surface)) {
            throw 'Surface is required when selecting a vertical-slice prompt.'
        }
        Require-SafeText -Value $Requirements -Label 'Requirements'
        Require-SafeText -Value $AcceptanceCriteria -Label 'AcceptanceCriteria'
        Require-SafeText -Value $OutOfScope -Label 'OutOfScope'
        $continueActiveSlice = $false
        if ($null -ne $state.activeSlice) {
            if ($state.activeSlice.status -eq 'in_progress' -and
                $selectedId -eq '19') {
                throw "Cannot start slice $SliceId while slice $($state.activeSlice.id) is in progress."
            }
            if ($state.activeSlice.status -eq 'in_progress' -and
                $selectedId -in @('25', '27') -and
                [string]$state.activeSlice.id -ne $SliceId) {
                throw "Foundation belongs to active slice $($state.activeSlice.id); select the same SliceId before starting another slice."
            }
            if ($state.activeSlice.status -eq 'in_progress' -and
                $selectedId -in @('25', '27') -and
                [string]$state.activeSlice.id -eq $SliceId) {
                foreach ($field in @('kind', 'surface', 'requirements', 'acceptanceCriteria', 'outOfScope')) {
                    $incoming = switch ($field) {
                        'kind' { $SliceKind }
                        'surface' { $Surface }
                        'requirements' { $Requirements }
                        'acceptanceCriteria' { $AcceptanceCriteria }
                        'outOfScope' { $OutOfScope }
                    }
                    if ([string]$state.activeSlice.$field -ne [string]$incoming) {
                        throw "Active slice $SliceId metadata mismatch for $field."
                    }
                }
                $continueActiveSlice = $true
            }
            if ($state.activeSlice.status -eq 'completed') {
                $g04 = Get-GateState -State $state -Id 'G04'
                if ($g04.status -ne 'passed') {
                    throw "A new slice cannot start until first-slice quality gate G04 passes; found '$($g04.status)'."
                }
                if ([string]$state.activeSlice.id -eq $SliceId) {
                    throw "Completed slice id $SliceId cannot be reused; choose a new stable SliceId."
                }
            }
        }
        if (-not $continueActiveSlice) {
            $newSlice = [ordered]@{
                id = $SliceId
                kind = $SliceKind
                surface = $Surface
                requirements = $Requirements
                acceptanceCriteria = $AcceptanceCriteria
                outOfScope = $OutOfScope
                evidence = $Evidence
                selectedAt = [DateTimeOffset]::Now.ToString('o')
                status = 'in_progress'
            }
            $state.activeSlice = $newSlice
            $state.slices = @($state.slices) + @($newSlice)
        }
        if ($Surface -notin @($state.selectedSurfaces)) {
            $state.selectedSurfaces = @($state.selectedSurfaces) + @($Surface)
        }
    }

    Test-EntryGate -State $state -Manifest $manifest -NextId $selectedId
    Set-CurrentPrompt -State $state -Manifest $manifest -Id $selectedId
    $state.history = @($state.history) + @([ordered]@{
        at = [DateTimeOffset]::Now.ToString('o')
        action = 'select'
        promptId = $selectedId
        evidence = $Evidence
        slice = $(if ($selectedId -in @('19', '25', '27')) {
            [ordered]@{
                id = $state.activeSlice.id
                kind = $state.activeSlice.kind
                surface = $state.activeSlice.surface
                requirements = $state.activeSlice.requirements
                acceptanceCriteria = $state.activeSlice.acceptanceCriteria
                outOfScope = $state.activeSlice.outOfScope
                status = $state.activeSlice.status
            }
        } else {
            $null
        })
    })
    Save-State -State $state -Root $ProcessRoot
    $freshState = Get-State $ProcessRoot
    $packet = New-TaskPacket -Root $ProcessRoot -State $freshState -Manifest $manifest
    Write-Host "SELECTED: prompt $selectedId." -ForegroundColor Green
    Write-Host " - Task packet: $packet"
    exit 0
}

if ($Command -eq 'decide') {
    $decidedId = Normalize-PromptId $PromptId
    if ($null -eq $decidedId) {
        throw 'PromptId is required for decide.'
    }
    if ($Result -ne 'not_applicable') {
        throw 'The decide command currently accepts only Result not_applicable; use select to execute applicable work.'
    }
    if ($null -ne $state.currentPrompt -and -not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
        throw "Cannot decide prompt $decidedId while prompt $($state.currentPrompt) is active."
    }
    if ($state.status -ne 'waiting_decision') {
        throw "Applicability decisions require lifecycle status waiting_decision; found '$($state.status)'."
    }
    Require-SafeText -Value $Evidence -Label 'Evidence'
    $allowedDecisions = @(Get-AllowedDecisionPromptIds -State $state)
    if ($decidedId -notin $allowedDecisions) {
        $allowedText = $(if ($allowedDecisions.Count -eq 0) { 'none' } else { $allowedDecisions -join ', ' })
        throw "Prompt $decidedId cannot be decided for '$($state.nextAction)'. Allowed: $allowedText."
    }
    $decidedPrompt = Get-PromptState -State $state -Id $decidedId
    if ($decidedPrompt.applicability -eq 'required') {
        throw "Required prompt $decidedId cannot be marked not_applicable."
    }
    if ($decidedPrompt.status -eq 'completed') {
        throw "Completed prompt $decidedId cannot be changed to not_applicable."
    }
    $decidedPrompt.applicability = 'selected'
    $decidedPrompt.status = 'not_applicable'
    $decidedPrompt.evidence = $Evidence
    $decidedPrompt.attempts = @($decidedPrompt.attempts) + @([ordered]@{
        at = [DateTimeOffset]::Now.ToString('o')
        result = 'not_applicable'
        evidence = $Evidence
    })
    $state.history = @($state.history) + @([ordered]@{
        at = [DateTimeOffset]::Now.ToString('o')
        action = 'applicability_decision'
        promptId = $decidedId
        result = 'not_applicable'
        evidence = $Evidence
    })
    Save-State -State $state -Root $ProcessRoot
    Write-Host "DECIDED: optional prompt $decidedId is not applicable." -ForegroundColor Green
    Write-Host " - Evidence: $Evidence"
    Write-Host " - Next action remains: $($state.nextAction)"
    exit 0
}

if ($Command -eq 'gate') {
    if ($null -ne $state.currentPrompt -and -not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
        throw "Cannot decide a standalone gate while prompt $($state.currentPrompt) is active."
    }
    if ($state.status -ne 'waiting_decision') {
        throw "Standalone gate decisions require lifecycle status waiting_decision; found '$($state.status)'."
    }
    if ([string]::IsNullOrWhiteSpace($GateId) -or $GateId -notmatch '^G\d{2}$') {
        throw 'A valid GateId is required for gate.'
    }
    if ([string]::IsNullOrWhiteSpace($GateDecision)) {
        throw 'GateDecision is required for gate.'
    }
    Require-SafeText -Value $GateEvidence -Label 'GateEvidence'
    $gateMatches = @($manifest.gates | Where-Object { $_.id -eq $GateId })
    if ($gateMatches.Count -ne 1) {
        throw "Unknown gate: $GateId"
    }
    $standaloneGate = $gateMatches[0]
    if ($standaloneGate.PSObject.Properties.Name -contains 'afterPrompt' -and
        -not [string]::IsNullOrWhiteSpace([string]$standaloneGate.afterPrompt)) {
        $afterPromptState = Get-PromptState -State $state -Id ([string]$standaloneGate.afterPrompt)
        if ($afterPromptState.status -ne 'completed') {
            throw "Gate $GateId requires prompt $($standaloneGate.afterPrompt) completed; found '$($afterPromptState.status)'."
        }
    }
    if ($standaloneGate.PSObject.Properties.Name -contains 'allowedAfterPromptIds') {
        $completedAllowed = @(
            @($standaloneGate.allowedAfterPromptIds) |
                Where-Object { (Get-PromptState -State $state -Id ([string]$_)).status -eq 'completed' }
        )
        if ($completedAllowed.Count -eq 0) {
            throw "Gate $GateId requires at least one allowed gate prompt to be completed."
        }
    }
    if ($GateDecision -eq 'passed' -and [bool]$standaloneGate.humanApproval) {
        Require-SafeText -Value $ApprovedBy -Label 'ApprovedBy'
    }
    if ($GateDecision -eq 'passed') {
        Test-GatePrerequisites -State $state -GateDefinition $standaloneGate
        Invoke-ManifestGateValidator -Root $ProcessRoot -GateDefinition $standaloneGate -RecordedApprover $ApprovedBy
        if ($standaloneGate.PSObject.Properties.Name -contains 'validator' -and
            [string]$standaloneGate.validator -eq 'scripts/Test-LifecycleGateEvidence.ps1') {
            $GateEvidence = "LIFECYCLE_GATE_EVIDENCE.json#$GateId"
        }
    }
    $standaloneGateState = Get-GateState -State $state -Id $GateId
    $standaloneGateState.status = $GateDecision
    $standaloneGateState.evidence = $GateEvidence
    $standaloneGateState.approvedBy = $ApprovedBy
    $standaloneGateState.updatedAt = [DateTimeOffset]::Now.ToString('o')
    if ($GateDecision -eq 'passed') {
        Set-GateSnapshot -State $state -Root $ProcessRoot -GateId $GateId
    }
    else {
        $standaloneGateState.snapshot = $null
    }
    $state.history = @($state.history) + @([ordered]@{
        at = [DateTimeOffset]::Now.ToString('o')
        action = 'gate'
        gateId = $GateId
        decision = $GateDecision
        evidence = $GateEvidence
        approvedBy = $ApprovedBy
    })
    if ($GateId -eq 'G10' -and $GateDecision -eq 'passed') {
        $state.status = 'completed'
        $state.nextAction = 'none'
    }
    Save-State -State $state -Root $ProcessRoot
    Write-Host "GATE: $GateId -> $GateDecision." -ForegroundColor Green
    Write-Host " - Next action: $($state.nextAction)"
    exit 0
}

if ($Command -eq 'record') {
    $PromptId = Normalize-PromptId $PromptId
    if ($null -eq $PromptId) {
        throw 'PromptId is required for record.'
    }
    if ([string]::IsNullOrWhiteSpace($Result)) {
        throw 'Result is required for record.'
    }
    Require-SafeText -Value $Evidence -Label 'Evidence'
    if ($PromptId -ne [string]$state.currentPrompt) {
        throw "Out-of-order result: current prompt is $($state.currentPrompt), received $PromptId."
    }

    $promptState = Get-PromptState -State $state -Id $PromptId
    if ($Result -eq 'not_applicable' -and $promptState.applicability -eq 'required') {
        throw "Required prompt $PromptId cannot be marked not_applicable."
    }

    $attempt = [ordered]@{
        at = [DateTimeOffset]::Now.ToString('o')
        result = $Result
        evidence = $Evidence
    }
    $promptState.attempts = @($promptState.attempts) + @($attempt)
    $promptState.status = $Result
    $promptState.evidence = $Evidence
    if ($PromptId -in @('26', '28') -and $Result -eq 'completed' -and $null -ne $state.activeSlice) {
        $state.activeSlice.status = 'completed'
        $state.activeSlice | Add-Member -NotePropertyName 'completedAt' `
            -NotePropertyValue ([DateTimeOffset]::Now.ToString('o')) -Force
        $state.activeSlice | Add-Member -NotePropertyName 'completionEvidence' `
            -NotePropertyValue $Evidence -Force
        $matchingSlices = @($state.slices | Where-Object { $_.id -eq $state.activeSlice.id })
        if ($matchingSlices.Count -ne 1) {
            throw "Slice history integrity failure for $($state.activeSlice.id): expected one record, found $($matchingSlices.Count)."
        }
        $matchingSlices[0].status = 'completed'
        $matchingSlices[0] | Add-Member -NotePropertyName 'completedAt' `
            -NotePropertyValue $state.activeSlice.completedAt -Force
        $matchingSlices[0] | Add-Member -NotePropertyName 'completionEvidence' `
            -NotePropertyValue $Evidence -Force
    }

    $gateDefinition = $null
    if (-not [string]::IsNullOrWhiteSpace($GateId)) {
        if ($GateId -notmatch '^G\d{2}$') {
            throw "Invalid GateId: $GateId"
        }
        if ([string]::IsNullOrWhiteSpace($GateDecision)) {
            throw 'GateDecision is required when GateId is provided.'
        }
        Require-SafeText -Value $GateEvidence -Label 'GateEvidence'
        $gateMatches = @($manifest.gates | Where-Object { $_.id -eq $GateId })
        if ($gateMatches.Count -ne 1) {
            throw "Unknown gate: $GateId"
        }
        $gateDefinition = $gateMatches[0]
        if ($GateDecision -eq 'passed' -and $Result -ne 'completed') {
            throw "Gate $GateId cannot pass while prompt $PromptId result is '$Result'."
        }
        if ($gateDefinition.PSObject.Properties.Name -contains 'afterPrompt' -and
            -not [string]::IsNullOrWhiteSpace([string]$gateDefinition.afterPrompt) -and
            [string]$gateDefinition.afterPrompt -ne $PromptId) {
            throw "Gate $GateId can only be decided after prompt $($gateDefinition.afterPrompt), not $PromptId."
        }
        if ($gateDefinition.PSObject.Properties.Name -contains 'allowedAfterPromptIds' -and
            $PromptId -notin @($gateDefinition.allowedAfterPromptIds)) {
            throw "Gate $GateId cannot be decided after prompt $PromptId."
        }
        if ($GateDecision -eq 'passed' -and [bool]$gateDefinition.humanApproval) {
            Require-SafeText -Value $ApprovedBy -Label 'ApprovedBy'
        }
        if ($GateDecision -eq 'passed') {
            Test-GatePrerequisites -State $state -GateDefinition $gateDefinition
            Invoke-ManifestGateValidator -Root $ProcessRoot -GateDefinition $gateDefinition -RecordedApprover $ApprovedBy
            if ($gateDefinition.PSObject.Properties.Name -contains 'validator' -and
                [string]$gateDefinition.validator -eq 'scripts/Test-LifecycleGateEvidence.ps1') {
                $GateEvidence = "LIFECYCLE_GATE_EVIDENCE.json#$GateId"
            }
        }
    }

    if ($null -ne $gateDefinition) {
        $gateState = Get-GateState -State $state -Id $GateId
        $gateState.status = $GateDecision
        $gateState.evidence = $GateEvidence
        $gateState.approvedBy = $ApprovedBy
        $gateState.updatedAt = [DateTimeOffset]::Now.ToString('o')
        if ($GateDecision -eq 'passed') {
            Set-GateSnapshot -State $state -Root $ProcessRoot -GateId $GateId
        }
        else {
            $gateState.snapshot = $null
        }
    }

    if ($PromptId -eq '64' -and $Result -eq 'completed') {
        $g09 = Get-GateState -State $state -Id 'G09'
        if ($g09.status -ne 'passed') {
            throw "Prompt 64 cannot be completed because G09 is '$($g09.status)'."
        }
        $releaseValidator = Join-Path $ProcessRoot 'scripts/Test-LifecycleGateEvidence.ps1'
        $releaseValidatorOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $releaseValidator `
            -GateId G09 -ProcessRoot $ProcessRoot -Phase release_completed
        $releaseValidatorExitCode = $LASTEXITCODE
        $releaseValidatorOutput | Out-Host
        if ($releaseValidatorExitCode -ne 0) {
            throw 'Prompt 64 release-completion evidence failed validation.'
        }
        Set-G09DeploymentSnapshot -State $state -Root $ProcessRoot
    }

    if ($PromptId -eq '04' -and $Result -eq 'completed') {
        $g01Definition = @($manifest.gates | Where-Object { $_.id -eq 'G01' })[0]
        Test-GatePrerequisites -State $state -GateDefinition $g01Definition
        Invoke-ProductDefinitionGate -Root $ProcessRoot
        $g01 = Get-GateState -State $state -Id 'G01'
        $g01.status = 'passed'
        $g01.evidence = 'PRODUCT_DEFINITION.md and scripts/Test-ProductDefinitionGate.ps1'
        $g01.approvedBy = 'Recorded in PRODUCT_DEFINITION.md'
        $g01.updatedAt = [DateTimeOffset]::Now.ToString('o')
    }

    $historyItem = [ordered]@{
        at = [DateTimeOffset]::Now.ToString('o')
        promptId = $PromptId
        result = $Result
        evidence = $Evidence
        nextPrompt = $NextPrompt
    }
    $state.history = @($state.history) + @($historyItem)

    if ($Result -in @('blocked', 'partial')) {
        $state.status = $Result
        $state.nextAction = 'resolve_current_prompt'
        $state.blockers = @("Prompt $PromptId is $Result. Evidence: $Evidence")
        Save-State -State $state -Root $ProcessRoot
        Write-Host "RECORDED: prompt $PromptId is $Result; the process did not advance." -ForegroundColor Yellow
        exit 0
    }

    $requestedNextId = Normalize-PromptId $NextPrompt
    $automaticNextId = $(if ($Result -eq 'completed') {
        Get-AutomaticNextPrompt -State $state -CompletedId $PromptId
    } else {
        $null
    })
    if ($null -ne $requestedNextId -and $null -eq $automaticNextId) {
        throw "Prompt $PromptId requires an explicit workflow decision; use the select command after recording it without NextPrompt."
    }
    if ($null -ne $requestedNextId -and $requestedNextId -ne $automaticNextId) {
        throw "Invalid NextPrompt override: prompt $PromptId routes to $automaticNextId, not $requestedNextId."
    }
    $nextId = $automaticNextId
    if ($null -eq $nextId) {
        $state.currentPrompt = $null
        $g10 = Get-GateState -State $state -Id 'G10'
        if ($PromptId -eq '73' -and $g10.status -eq 'passed') {
            $state.status = 'completed'
            $state.nextAction = 'none'
        }
        else {
            $state.status = 'waiting_decision'
            $state.nextAction = Get-DecisionHint -State $state -CompletedId $PromptId
        }
    }
    else {
        Test-EntryGate -State $state -Manifest $manifest -NextId $nextId
        Set-CurrentPrompt -State $state -Manifest $manifest -Id $nextId
    }
    $state.blockers = @()
    Save-State -State $state -Root $ProcessRoot

    Write-Host "RECORDED: prompt $PromptId -> $Result." -ForegroundColor Green
    if ($null -ne $nextId) {
        $freshState = Get-State $ProcessRoot
        $packet = New-TaskPacket -Root $ProcessRoot -State $freshState -Manifest $manifest
        Write-Host " - Next prompt: $nextId"
        Write-Host " - Task packet: $packet"
    }
    else {
        Write-Host " - Next action: $($state.nextAction)"
    }
    exit 0
}

throw "Unsupported command: $Command"
