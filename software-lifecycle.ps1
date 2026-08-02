[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet(
        'start', 'adopt', 'continue', 'status', 'next', 'advance', 'request', 'repeat', 'select', 'decide',
        'gate', 'record', 'validate', 'work-start', 'checkpoint', 'verify',
        'finding-add', 'finding-resolve', 'finding-gate', 'closeout',
        'cycle-start', 'upgrade')]
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
    [string]$Summary,
    [string[]]$RemainingWork,
    [string]$Objective,
    [switch]$ConfirmRepeat,
    [switch]$AcceptIncomplete,
    [switch]$ConfirmMigration,
    [switch]$AcceptCandidateCatalog,

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
    [string]$OutOfScope,

    [string[]]$Goal,
    [string]$GoalId,
    [ValidateSet('completed', 'blocked')]
    [string]$CheckpointStatus,

    [ValidateSet('command', 'inspection', 'render', 'connector', 'review')]
    [string]$VerificationKind,
    [string]$VerifyCommand,
    [Nullable[int]]$VerifyExitCode,
    [string]$VerifyEvidence,
    [string]$ReviewEvidence,

    [string]$FindingId,
    [string]$Title,
    [ValidateSet('critical', 'high', 'medium', 'low')]
    [string]$Severity,
    [string]$Source,
    [string]$Location,
    [string]$ResolutionEvidence,

    [string]$ChangeId
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

function Compare-CatalogVersion {
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )

    $pattern = '^(\d{4})-(\d{2})-(\d{2})\.(\d+)$'
    $leftMatch = [regex]::Match($Left, $pattern)
    $rightMatch = [regex]::Match($Right, $pattern)
    if (-not $leftMatch.Success -or -not $rightMatch.Success) {
        throw "Catalog versions must use YYYY-MM-DD.N for automatic upgrade: '$Left', '$Right'."
    }
    $leftDate = [DateTime]::new(
        [int]$leftMatch.Groups[1].Value,
        [int]$leftMatch.Groups[2].Value,
        [int]$leftMatch.Groups[3].Value)
    $rightDate = [DateTime]::new(
        [int]$rightMatch.Groups[1].Value,
        [int]$rightMatch.Groups[2].Value,
        [int]$rightMatch.Groups[3].Value)
    $dateComparison = [DateTime]::Compare($leftDate, $rightDate)
    if ($dateComparison -ne 0) {
        return $dateComparison
    }
    return ([int]$leftMatch.Groups[4].Value).CompareTo([int]$rightMatch.Groups[4].Value)
}

function Get-Manifest {
    param([Parameter(Mandatory)][string]$Root)
    $path = Join-Path $Root 'PROCESS_MANIFEST.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "PROCESS_MANIFEST.json is missing: $path"
    }
    return Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json
}

function Get-TwoColumnMarkdownValues {
    param([Parameter(Mandatory)][string]$Path)

    $values = @{}
    foreach ($line in (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path) -split "\r?\n") {
        if ($line -notmatch '^\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$') {
            continue
        }
        $key = $Matches[1].Trim()
        if ($key -notin @('Campo', '---')) {
            $values[$key] = $Matches[2].Trim()
        }
    }
    return $values
}

function Assert-CatalogEligibleForAutomaticUpgrade {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)]$Manifest
    )

    $channel = if ($Manifest.PSObject.Properties.Name -contains 'releaseChannel') {
        [string]$Manifest.releaseChannel
    }
    else {
        'candidate'
    }
    if ($channel -ne 'stable') {
        throw "upgrade only accepts a stable catalog; source $($Manifest.catalogVersion) is '$channel'."
    }

    $approvalPath = Join-Path $Root 'PILOT_APPROVAL.md'
    if (-not (Test-Path -LiteralPath $approvalPath -PathType Leaf)) {
        throw 'upgrade requires PILOT_APPROVAL.md for the source catalog.'
    }
    $approval = Get-TwoColumnMarkdownValues -Path $approvalPath
    $required = [ordered]@{
        'Catalog version' = [string]$Manifest.catalogVersion
        'Status' = 'approved'
        'Suite cases' = '15/15'
        'Critical failures' = '0'
    }
    foreach ($entry in $required.GetEnumerator()) {
        if (-not $approval.ContainsKey($entry.Key) -or [string]$approval[$entry.Key] -ne $entry.Value) {
            throw "upgrade requires approved current-version pilot evidence: $($entry.Key) must be '$($entry.Value)'."
        }
    }
    foreach ($key in @('Human evaluator', 'Independent reviewer', 'Evidence', 'Approved at')) {
        if (-not $approval.ContainsKey($key) -or
            [string]::IsNullOrWhiteSpace([string]$approval[$key]) -or
            [string]$approval[$key] -match '(?i)^(pending|a preencher|-)$') {
            throw "upgrade requires durable pilot evidence in '$key'."
        }
    }
    if ([string]$approval['Human evaluator'] -eq [string]$approval['Independent reviewer']) {
        throw 'upgrade requires different human evaluator and independent reviewer identities.'
    }
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
    if ($number -lt 1 -or $number -gt 76) {
        throw "Prompt id is outside 01-76: $Value"
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

function Get-OrderedPromptIds {
    param([Parameter(Mandatory)]$Manifest)

    return @(
        $Manifest.stages |
            ForEach-Object { @($_.promptIds) } |
            ForEach-Object { [string]$_ }
    )
}

function Get-PromptIdentityMap {
    param([Parameter(Mandatory)][string]$Root)

    $promptRoot = Join-Path $Root 'prompts'
    $identities = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $promptRoot -Recurse -File -Filter '*.md')) {
        if ($file.Name -notmatch '^(\d{2})-(.+)\.md$') {
            continue
        }
        $id = [string]$Matches[1]
        $identity = [string]$Matches[2]
        if ($identities.ContainsKey($id)) {
            throw "Prompt identity map contains duplicate id $id under $promptRoot."
        }
        $identities[$id] = $identity
    }
    return $identities
}

function Get-PromptIdentityMigrationMap {
    param(
        [Parameter(Mandatory)][hashtable]$SourceIdentities,
        [Parameter(Mandatory)][hashtable]$TargetIdentities,
        [Parameter(Mandatory)][string[]]$TargetPromptIds,
        [switch]$ConfirmMigration
    )

    $migration = @{}
    foreach ($targetPromptId in $TargetPromptIds) {
        if (-not $TargetIdentities.ContainsKey($targetPromptId)) {
            throw "upgrade requires an explicit migration because prompt $targetPromptId identity mapping changed."
        }
        $targetIdentity = [string]$TargetIdentities[$targetPromptId]
        $sourceMatches = @(
            $SourceIdentities.GetEnumerator() |
                Where-Object { [string]$_.Value -eq $targetIdentity } |
                ForEach-Object { [string]$_.Key }
        )
        if ($sourceMatches.Count -ne 1) {
            throw "upgrade requires an explicit migration because prompt $targetPromptId identity mapping changed; stable identity '$targetIdentity' has $($sourceMatches.Count) matches in the source catalog."
        }
        $sourcePromptId = Normalize-PromptId $sourceMatches[0]
        if ($sourcePromptId -ne $targetPromptId -and -not $ConfirmMigration) {
            throw "upgrade requires -ConfirmMigration and an Objective because prompt identity '$targetIdentity' moved from $targetPromptId to $sourcePromptId."
        }
        $migration[$targetPromptId] = $sourcePromptId
    }
    $destinationIds = @($migration.Values | Sort-Object -Unique)
    if ($destinationIds.Count -ne $migration.Count) {
        throw 'upgrade refuses an ambiguous prompt identity migration with duplicate destination IDs.'
    }
    return $migration
}

function Convert-StatePromptIdentities {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][hashtable]$Migration
    )

    function Convert-PromptReference {
        param([AllowNull()]$Value)
        if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
            return $Value
        }
        $normalized = Normalize-PromptId ([string]$Value)
        if (-not $Migration.ContainsKey($normalized)) {
            throw "Lifecycle state references prompt $normalized, which has no stable identity migration."
        }
        return [string]$Migration[$normalized]
    }

    $changes = [System.Collections.Generic.List[string]]::new()
    $remappedPrompts = [pscustomobject][ordered]@{}
    foreach ($property in @($State.prompts.PSObject.Properties)) {
        $oldId = Normalize-PromptId ([string]$property.Name)
        $newId = Convert-PromptReference $oldId
        if ($null -ne $remappedPrompts.PSObject.Properties[$newId]) {
            throw "Lifecycle state prompt migration collides at destination $newId."
        }
        $remappedPrompts | Add-Member -MemberType NoteProperty -Name $newId -Value $property.Value
        if ($oldId -ne $newId) {
            $changes.Add("$oldId->$newId")
        }
        foreach ($attempt in @($property.Value.attempts)) {
            if ($null -ne $attempt.PSObject.Properties['promptId']) {
                $attempt.promptId = Convert-PromptReference $attempt.promptId
            }
        }
    }
    $State.prompts = $remappedPrompts

    foreach ($propertyName in @('currentPrompt', 'lastPrompt')) {
        if ($null -ne $State.PSObject.Properties[$propertyName] -and
            -not [string]::IsNullOrWhiteSpace([string]$State.$propertyName)) {
            $State.$propertyName = Convert-PromptReference $State.$propertyName
        }
    }
    if ($null -ne $State.PSObject.Properties['selectedOptionalPromptIds']) {
        $State.selectedOptionalPromptIds = @(
            @($State.selectedOptionalPromptIds) |
                ForEach-Object { Convert-PromptReference $_ }
        )
    }
    foreach ($historyItem in @($State.history)) {
        foreach ($propertyName in @('promptId', 'nextPrompt')) {
            if ($null -ne $historyItem.PSObject.Properties[$propertyName] -and
                -not [string]::IsNullOrWhiteSpace([string]$historyItem.$propertyName)) {
                $historyItem.$propertyName = Convert-PromptReference $historyItem.$propertyName
            }
        }
    }
    return @($changes)
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

function Test-TaskLedgerRequired {
    param([Parameter(Mandatory)]$Manifest)

    if ([string]$env:ADVANCE_LIFECYCLE_MODE -eq 'governed') {
        return $true
    }
    $policy = $Manifest.executionPolicy
    return $null -ne $policy -and
        $null -ne $policy.PSObject.Properties['taskLedgerRequired'] -and
        [bool]$policy.taskLedgerRequired
}

function Test-ProgrammerControlledWorkflow {
    param([Parameter(Mandatory)]$Manifest)

    if (-not [string]::IsNullOrWhiteSpace([string]$env:ADVANCE_LIFECYCLE_MODE)) {
        return [string]$env:ADVANCE_LIFECYCLE_MODE -eq 'programmer_controlled'
    }
    $policy = $Manifest.executionPolicy
    return $null -ne $policy -and
        $null -ne $policy.PSObject.Properties['workflowMode'] -and
        [string]$policy.workflowMode -eq 'programmer_controlled'
}

function Get-CatalogPromptMetadata {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$Id
    )

    $file = Get-PromptFile -Root $Root -Id $Id
    $stage = Get-PromptStage -Manifest $Manifest -Id $Id
    $isConditional = $file.FullName -match '[\\/]Optional[\\/]'
    if ($stage.PSObject.Properties.Name -contains 'conditionalPromptIds') {
        $isConditional = $isConditional -or (@($stage.conditionalPromptIds) -contains $Id)
    }
    $title = (Get-Content -Encoding UTF8 -LiteralPath $file.FullName -TotalCount 1) -replace '^#\s*', ''
    return [pscustomobject][ordered]@{
        title = $title
        path = $file.FullName.Substring($Root.Length + 1).Replace('\', '/')
        stage = [string]$stage.id
        applicability = $(if ($isConditional) { 'conditional' } else { 'required' })
        initialStatus = $(if ($isConditional) { 'not_selected' } else { 'pending' })
    }
}

function Merge-CatalogPromptsIntoState {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$SourceManifest,
        [Parameter(Mandatory)][string]$SourceRoot
    )

    $added = [System.Collections.Generic.List[string]]::new()
    foreach ($id in @(Get-OrderedPromptIds -Manifest $SourceManifest)) {
        $metadata = Get-CatalogPromptMetadata -Root $SourceRoot -Manifest $SourceManifest -Id $id
        $existing = $State.prompts.PSObject.Properties[$id]
        if ($null -eq $existing) {
            $State.prompts | Add-Member -MemberType NoteProperty -Name $id -Value ([pscustomobject][ordered]@{
                title = $metadata.title
                path = $metadata.path
                stage = $metadata.stage
                applicability = $metadata.applicability
                status = $metadata.initialStatus
                evidence = $null
                attempts = @()
            })
            $added.Add($id)
            continue
        }

        $prompt = $existing.Value
        $prompt | Add-Member -NotePropertyName 'title' -NotePropertyValue $metadata.title -Force
        $prompt | Add-Member -NotePropertyName 'path' -NotePropertyValue $metadata.path -Force
        $prompt | Add-Member -NotePropertyName 'stage' -NotePropertyValue $metadata.stage -Force
        $hasHistory = @(Get-PromptResultHistory -State $State -Id $id).Count -gt 0
        $hasEvidence = -not [string]::IsNullOrWhiteSpace([string]$prompt.evidence)
        $hasAttempts = @($prompt.attempts).Count -gt 0
        if (-not $hasHistory -and -not $hasEvidence -and -not $hasAttempts -and
            [string]$prompt.status -in @('pending', 'not_selected')) {
            $prompt.applicability = $metadata.applicability
            $prompt.status = $metadata.initialStatus
        }
    }
    return @($added)
}

function Remove-StaleCatalogPromptFiles {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][string[]]$SourcePromptIds
    )

    $sourcePromptRoot = Join-Path $SourceRoot 'prompts'
    $targetPromptRoot = Join-Path $TargetRoot 'prompts'
    $sourceRelativePaths = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($file in @(Get-ChildItem -LiteralPath $sourcePromptRoot -Recurse -File -Filter '*.md')) {
        [void]$sourceRelativePaths.Add(
            $file.FullName.Substring($sourcePromptRoot.Length + 1).Replace('\', '/'))
    }

    $removed = [System.Collections.Generic.List[string]]::new()
    foreach ($file in @(Get-ChildItem -LiteralPath $targetPromptRoot -Recurse -File -Filter '*.md')) {
        $relativePath = $file.FullName.Substring($targetPromptRoot.Length + 1).Replace('\', '/')
        if ($sourceRelativePaths.Contains($relativePath)) {
            continue
        }
        if ($file.Name -notmatch '^(\d{2})-') {
            throw "Migration refuses to delete unrecognized target prompt file: $relativePath"
        }
        $promptId = [string]$Matches[1]
        if ($promptId -notin $SourcePromptIds) {
            throw "Migration refuses to delete unrecognized target prompt file: $relativePath"
        }
        $replacementCount = @(Get-ChildItem -LiteralPath $sourcePromptRoot -Recurse -File -Filter "$promptId-*.md").Count
        if ($replacementCount -ne 1) {
            throw "Migration cannot prove one source replacement for stale prompt $relativePath."
        }
        Remove-Item -LiteralPath $file.FullName -Force
        $removed.Add($relativePath)
    }
    return @($removed)
}

function Convert-LegacyStateToProgrammerControlled {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$TargetManifest,
        [Parameter(Mandatory)]$SourceManifest
    )

    if ((Test-ProgrammerControlledWorkflow -Manifest $TargetManifest) -or
        -not (Test-ProgrammerControlledWorkflow -Manifest $SourceManifest)) {
        return $false
    }

    if ([string]$State.status -in @('partial', 'blocked', 'waiting_decision')) {
        $lastId = Get-LastRecordedPromptId -State $State
        if ($null -eq $lastId) {
            throw 'Legacy incomplete-state migration requires a recorded prompt result.'
        }
        $lastResult = @(Get-PromptResultHistory -State $State -Id $lastId)[-1]
        $prompt = Get-PromptState -State $State -Id $lastId
        $summary = $(if ($prompt.PSObject.Properties.Name -contains 'summary' -and
            -not [string]::IsNullOrWhiteSpace([string]$prompt.summary)) {
            [string]$prompt.summary
        } elseif (-not [string]::IsNullOrWhiteSpace([string]$prompt.evidence)) {
            [string]$prompt.evidence
        } else {
            "Prompt $lastId recorded as $($lastResult.result)."
        })
        $remaining = @($State.blockers | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        if ($remaining.Count -eq 0 -and [string]$lastResult.result -in @('partial', 'blocked')) {
            $remaining = @("Resolve the recorded $($lastResult.result) work for prompt $lastId.")
        }
        $prompt | Add-Member -NotePropertyName 'summary' -NotePropertyValue $summary -Force
        $prompt | Add-Member -NotePropertyName 'remainingWork' -NotePropertyValue @($remaining) -Force
        $prompt | Add-Member -NotePropertyName 'finishedAt' -NotePropertyValue ([string]$lastResult.at) -Force
        $State | Add-Member -NotePropertyName 'lastPrompt' -NotePropertyValue $lastId -Force
        $State.currentPrompt = $null
        $State.status = 'awaiting_programmer'
        $State.nextAction = 'next | repeat | correct | skip_and_advance'
        $State.blockers = @()
        return $true
    }

    return $false
}

function Get-LastRecordedPromptId {
    param([Parameter(Mandatory)]$State)

    if ($null -ne $State.PSObject.Properties['lastPrompt'] -and
        -not [string]::IsNullOrWhiteSpace([string]$State.lastPrompt)) {
        return Normalize-PromptId ([string]$State.lastPrompt)
    }
    $results = @(
        @($State.history) |
            Where-Object { $null -ne $_.PSObject.Properties['promptId'] }
    )
    if ($results.Count -eq 0) {
        return $null
    }
    return Normalize-PromptId ([string]$results[-1].promptId)
}

function Get-PromptResultHistory {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Id
    )

    return @(
        @($State.history) |
            Where-Object {
                $null -ne $_.PSObject.Properties['promptId'] -and
                (Normalize-PromptId ([string]$_.promptId)) -eq $Id
            }
    )
}

function Write-PromptHistoryNotice {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)]$PromptState,
        [switch]$BrownfieldOverlap
    )

    $history = @(Get-PromptResultHistory -State $State -Id $Id)
    Write-Host "CONFIRMATION REQUIRED: prompt $Id will not run yet." -ForegroundColor Yellow
    if ($history.Count -gt 0) {
        $last = $history[-1]
        Write-Host " - Previous result: $($last.result)"
        if ($null -ne $last.PSObject.Properties['summary'] -and
            -not [string]::IsNullOrWhiteSpace([string]$last.summary)) {
            Write-Host " - Previous summary: $($last.summary)"
        }
        if ($null -ne $last.PSObject.Properties['remainingWork'] -and
            @($last.remainingWork).Count -gt 0) {
            Write-Host ' - Work that remained:'
            @($last.remainingWork) | ForEach-Object { Write-Host "   - $_" }
        }
        Write-Host " - Previous evidence: $($last.evidence)"
    }
    elseif ($BrownfieldOverlap) {
        Write-Host ' - This is an existing application; the lifecycle has no evidence proving whether this scope was already performed.'
        Write-Host ' - Inspect the implemented application and use the rerun only to validate or change a defined objective.'
    }
    else {
        Write-Host " - Current recorded status: $($PromptState.status)"
    }
    Write-Host ' - Confirm only after stating the objective: fix pending work, revalidate after changes, or replace a previous decision.'
    Write-Host " - Command: .\software-lifecycle.ps1 repeat -ProcessRoot `"$ProcessRoot`" -PromptId $Id -Objective `"<objective>`" -ConfirmRepeat"
}

function Add-LifecycleHistoryAction {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Evidence
    )

    $State.history = @($State.history) + @([ordered]@{
        at = [DateTimeOffset]::Now.ToString('o')
        action = $Action
        evidence = $Evidence
    })
}

function Get-ActiveWorkAttempt {
    param(
        [Parameter(Mandatory)]$State,
        [switch]$AllowMissing
    )

    $pointer = $State.PSObject.Properties['activeWorkAttemptId']
    if ($null -eq $pointer -or
        [string]::IsNullOrWhiteSpace([string]$State.activeWorkAttemptId)) {
        if ($AllowMissing) {
            return $null
        }
        throw 'No active work attempt exists. Run work-start before recording progress.'
    }
    if ([string]::IsNullOrWhiteSpace([string]$State.currentPrompt)) {
        throw 'An active work attempt cannot exist without a current prompt.'
    }

    $promptState = Get-PromptState -State $State -Id ([string]$State.currentPrompt)
    $matches = @(
        @($promptState.attempts) |
            Where-Object {
                $null -ne $_.PSObject.Properties['id'] -and
                [string]$_.id -eq [string]$State.activeWorkAttemptId
            }
    )
    if ($matches.Count -ne 1) {
        throw "Active work attempt '$($State.activeWorkAttemptId)' must match exactly one attempt in prompt $($State.currentPrompt)."
    }
    if ([string]$matches[0].result -ne 'in_progress') {
        throw "Active work attempt '$($State.activeWorkAttemptId)' is not in progress."
    }
    return $matches[0]
}

function New-WorkAttempt {
    param(
        [Parameter(Mandatory)][string]$PromptId,
        [AllowNull()][string[]]$GoalDefinitions
    )

    $definitions = @(
        $GoalDefinitions |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
    )
    if (@($definitions).Count -eq 0) {
        $definitions = @(
            'inspect::Inspect the applicable instructions, workspace and baseline evidence',
            'change::Execute the smallest coherent task scope',
            'verify::Run proportionate verification and preserve its evidence',
            'review::Perform adversarial self-review and close every finding'
        )
    }

    $goals = @()
    $index = 0
    foreach ($definition in $definitions) {
        $goalMatch = [regex]::Match(
            [string]$definition,
            '^(inspect|plan|change|verify|review|other)::(.+)$')
        if ([string]::IsNullOrWhiteSpace([string]$definition) -or -not $goalMatch.Success) {
            throw "Goal must use kind::description with kind inspect, plan, change, verify, review or other: $definition"
        }
        $description = $goalMatch.Groups[2].Value.Trim()
        $kind = $goalMatch.Groups[1].Value
        Require-SafeText -Value $description -Label 'Goal description'
        $index++
        $goals += [ordered]@{
            id = 'GOAL-{0:D3}' -f $index
            kind = $kind
            description = $description
            status = 'pending'
            evidence = $null
            updatedAt = $null
        }
    }

    foreach ($requiredKind in @('inspect', 'verify', 'review')) {
        if (@($goals | Where-Object { $_.kind -eq $requiredKind }).Count -lt 1) {
            throw "Work attempts require at least one '$requiredKind' goal."
        }
    }

    return [ordered]@{
        id = 'ATT-' + [Guid]::NewGuid().ToString('N')
        promptId = $PromptId
        startedAt = [DateTimeOffset]::Now.ToString('o')
        finishedAt = $null
        result = 'in_progress'
        evidence = $null
        goals = $goals
        findings = @()
        verification = @()
        adversarialReview = [ordered]@{
            type = 'self_adversarial'
            status = 'pending'
            evidence = $null
            completedAt = $null
        }
    }
}

function Add-WorkVerification {
    param(
        [Parameter(Mandatory)]$Attempt,
        [Parameter(Mandatory)][string]$Kind,
        [AllowNull()][string]$CommandText,
        [AllowNull()][Nullable[int]]$ExitCode,
        [Parameter(Mandatory)][string]$Evidence
    )

    Require-SafeText -Value $Evidence -Label 'VerifyEvidence'
    if ($Kind -eq 'command') {
        Require-SafeText -Value $CommandText -Label 'VerifyCommand'
        if ($null -eq $ExitCode) {
            throw 'VerifyExitCode is required for command verification.'
        }
        if ([int]$ExitCode -ne 0) {
            throw "A passing command verification requires exit code 0; found $ExitCode."
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$CommandText)) {
        Require-SafeText -Value $CommandText -Label 'VerifyCommand'
    }

    $Attempt.verification = @($Attempt.verification) + @([ordered]@{
        id = 'VERIFY-{0:D3}' -f (@($Attempt.verification).Count + 1)
        kind = $Kind
        command = $CommandText
        exitCode = $(if ($null -eq $ExitCode) { $null } else { [int]$ExitCode })
        status = 'passed'
        evidence = $Evidence
        at = [DateTimeOffset]::Now.ToString('o')
    })
}

function Assert-WorkAttemptCanComplete {
    param([Parameter(Mandatory)]$Attempt)

    $incompleteGoals = @(
        @($Attempt.goals) |
            Where-Object {
                [string]$_.status -ne 'completed' -or
                [string]::IsNullOrWhiteSpace([string]$_.evidence)
            }
    )
    if ($incompleteGoals.Count -gt 0) {
        throw "Work attempt $($Attempt.id) has incomplete goals: $($incompleteGoals.id -join ', ')."
    }

    $passingVerification = @(
        @($Attempt.verification) |
            Where-Object {
                [string]$_.status -eq 'passed' -and
                -not [string]::IsNullOrWhiteSpace([string]$_.evidence)
            }
    )
    if ($passingVerification.Count -lt 1) {
        throw "Work attempt $($Attempt.id) has no passing verification evidence."
    }

    if ($null -eq $Attempt.adversarialReview -or
        [string]$Attempt.adversarialReview.type -ne 'self_adversarial' -or
        [string]$Attempt.adversarialReview.status -ne 'completed' -or
        [string]::IsNullOrWhiteSpace([string]$Attempt.adversarialReview.evidence)) {
        throw "Work attempt $($Attempt.id) has no completed adversarial self-review."
    }

    $blockingFindings = @(
        @($Attempt.findings) |
            Where-Object { [string]$_.status -in @('open', 'blocked') }
    )
    if ($blockingFindings.Count -gt 0) {
        throw "Work attempt $($Attempt.id) has open or blocked findings: $($blockingFindings.id -join ', ')."
    }
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

    if ((Test-ProgrammerControlledWorkflow -Manifest $Manifest) -and $NextId -ne '67') {
        return
    }

    $stage = Get-PromptStage -Manifest $Manifest -Id $NextId
    $entryGate = $stage.entryGate
    if ($null -eq $entryGate -or [string]::IsNullOrWhiteSpace([string]$entryGate)) {
        return
    }

    $gate = Get-GateState -State $State -Id ([string]$entryGate)
    if ($gate.status -ne 'passed') {
        throw "Prompt $NextId cannot start because entry gate $entryGate is '$($gate.status)'."
    }

    if (([int]$NextId -ge 14 -and [int]$NextId -le 19) -or $NextId -eq '20') {
        $g03 = Get-GateState -State $State -Id 'G03'
        if ($g03.status -ne 'passed') {
            throw "Prompt $NextId cannot start because implementation gate G03 is '$($g03.status)'."
        }
    }

    if ($NextId -eq '67') {
        $g08 = Get-GateState -State $State -Id 'G08'
        if ($g08.status -ne 'passed') {
            throw "Prompt 67 cannot start because candidate/review gate G08 is '$($g08.status)'."
        }
        $g09 = Get-GateState -State $State -Id 'G09'
        if ($g09.status -ne 'passed') {
            throw "Prompt 67 cannot start because exact release authorization gate G09 is '$($g09.status)'."
        }
        foreach ($requiredPrompt in @('64', '65', '66')) {
            $requiredState = Get-PromptState -State $State -Id $requiredPrompt
            if ($requiredState.status -ne 'completed') {
                throw "Prompt 67 cannot start because prompt $requiredPrompt is '$($requiredState.status)'."
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
            attestationDigest = [string]$gateEvidence.authorization.attestationDigest
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
        $snapshot['attestationDigest'] = [string]$gateEvidence.candidate.provenance.attestationDigest
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
        foreach ($field in @('candidateSha', 'artifactDigest', 'attestationDigest', 'environment', 'releaseWindow', 'authorizedByIdentity', 'authorizedAt')) {
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
    if ($numericId -ge 1 -and $numericId -le 7) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -eq '08') {
        return '09'
    }
    if ($CompletedId -eq '09') {
        return '10'
    }
    if ($numericId -ge 10 -and $numericId -le 12) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($numericId -ge 21 -and $numericId -le 23) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -eq '25') {
        return '26'
    }
    if ($CompletedId -in @('27', '29')) {
        if ($null -eq $State.activeSlice -or [string]::IsNullOrWhiteSpace([string]$State.activeSlice.surface)) {
            throw "Prompt $CompletedId cannot route without an active slice surface."
        }
        $surfaceMap = @{
            ssr = '14'
            web = '16'
            maui = '18'
        }
        return $surfaceMap[[string]$State.activeSlice.surface]
    }
    if ($CompletedId -in @('14', '16', '18')) {
        return '20'
    }
    if ($CompletedId -eq '20') {
        if ($null -eq $State.activeSlice -or [string]::IsNullOrWhiteSpace([string]$State.activeSlice.kind)) {
            throw 'Requirements reconciliation prompt 20 cannot route without an active slice kind.'
        }
        return $(if ($State.activeSlice.kind -eq 'page') { '28' } else { '30' })
    }
    if ($CompletedId -in @('42', '43', '44', '45', '46')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -eq '51') {
        return '52'
    }
    if ($CompletedId -in @('54', '55', '56')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -in @('61', '62')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -in @('64', '65')) {
        return '{0:D2}' -f ($numericId + 1)
    }
    if ($CompletedId -eq '70') {
        return '71'
    }
    if ($CompletedId -eq '75') {
        return '76'
    }
    return $null
}

function Get-DecisionHint {
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$CompletedId
    )

    if ($CompletedId -eq '13') {
        return 'select_vertical_slice: choose 21 for required foundation, otherwise 27 for a page or 29 for a feature'
    }
    if ($CompletedId -eq '24') {
        return 'select_vertical_slice: choose 27 for a page or 29 for a feature'
    }
    if ($CompletedId -in @('28', '30')) {
        return 'select_next_slice_or_global_completion: choose 27/29 for another Must slice or 25 when Must slices are ready for global completion'
    }
    if ($CompletedId -in @('15', '17', '19')) {
        return 'select_next_slice_or_global_completion: close another active surface, choose 27/29 for another Must slice, or choose 25 for global completion'
    }
    if ([int]$CompletedId -ge 26 -and [int]$CompletedId -le 41) {
        return 'select_applicable_capability_or_security: complete 32, decide 31 and 33-41 applicability, then continue with 42'
    }
    if ([int]$CompletedId -ge 47 -and [int]$CompletedId -le 50) {
        return 'select_growth_or_hardening: decide 48-50 applicability, then continue with 51'
    }
    if ($CompletedId -in @('52', '53')) {
        return 'select_pwa_or_continue: decide prompt 53 applicability, then continue with 54'
    }
    if ($CompletedId -eq '57') {
        return 'select_delivery: continue with 58 after G06 passes'
    }
    if ($CompletedId -in @('58', '59', '60')) {
        return 'select_distribution_or_operations: decide 59-60 applicability, then continue with 61'
    }
    if ($CompletedId -eq '63') {
        return 'select_acceptance: continue with 64 after G07 passes'
    }
    if ($CompletedId -eq '66') {
        return 'authorize_release: validate G09 for the exact environment, candidate, digest and window, then select 67'
    }
    if ($CompletedId -in @('67', '68', '69')) {
        return 'select_continuous_operations: decide 68-69 applicability, then continue with 70'
    }
    if ($CompletedId -in @('71', '72', '73', '74')) {
        return 'select_observability_and_improvement: decide 72, continue with 73, decide 74, then continue with 75'
    }
    if ($CompletedId -eq '76') {
        return 'complete_G10_gate: validate continuous-operation owners, cadences and evidence'
    }
    return 'select_next_prompt_from_workflow'
}

function Get-AllowedSelectionPromptIds {
    param([Parameter(Mandatory)]$State)

    $action = [string]$State.nextAction
    if ($action -match '^select_vertical_slice') {
        $lastPrompt = @($State.history | Where-Object { $_.PSObject.Properties.Name -contains 'promptId' })[-1].promptId
        return $(if ($lastPrompt -eq '24') { @('27', '29') } else { @('21', '27', '29') })
    }
    if ($action -match '^select_next_slice_or_global_completion') {
        return @('15', '17', '19', '25', '27', '29')
    }
    if ($action -match '^select_applicable_capability_or_security') {
        return @(31..42 | ForEach-Object { '{0:D2}' -f $_ })
    }
    if ($action -match '^select_growth_or_hardening') {
        return @('48', '49', '50', '51')
    }
    if ($action -match '^select_pwa_or_continue') {
        return @('53', '54')
    }
    if ($action -match '^select_delivery') {
        return @('58')
    }
    if ($action -match '^select_distribution_or_operations') {
        return @('59', '60', '61')
    }
    if ($action -match '^select_acceptance') {
        return @('64')
    }
    if ($action -match '^authorize_release') {
        return @('67')
    }
    if ($action -match '^select_continuous_operations') {
        return @('68', '69', '70')
    }
    if ($action -match '^select_observability_and_improvement') {
        return @('72', '73', '74', '75')
    }
    return @()
}

function Get-AllowedDecisionPromptIds {
    param([Parameter(Mandatory)]$State)

    $action = [string]$State.nextAction
    if ($action -match '^select_vertical_slice') {
        return @('21', '22', '23', '24')
    }
    if ($action -match '^select_next_slice_or_global_completion') {
        return @('14', '15', '16', '17', '18', '19', '27', '28', '29', '30', '31')
    }
    if ($action -match '^select_applicable_capability_or_security') {
        return @('31') + @(33..41 | ForEach-Object { '{0:D2}' -f $_ })
    }
    if ($action -match '^select_growth_or_hardening') {
        return @('48', '49', '50')
    }
    if ($action -match '^select_pwa_or_continue') {
        return @('53')
    }
    if ($action -match '^select_distribution_or_operations') {
        return @('59', '60')
    }
    if ($action -match '^select_continuous_operations') {
        return @('68', '69')
    }
    if ($action -match '^select_observability_and_improvement') {
        return @('72', '74')
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

function Get-PromptExecutionProfile {
    param(
        [Parameter(Mandatory)][string]$PromptId,
        [Parameter(Mandatory)]$Manifest
    )

    if ($Manifest.PSObject.Properties.Name -notcontains 'promptExecutionProfiles') {
        return 'standard'
    }
    if (@($Manifest.promptExecutionProfiles.deep) -contains $PromptId) {
        return 'deep'
    }
    if (@($Manifest.promptExecutionProfiles.fast) -contains $PromptId) {
        return 'fast'
    }
    return 'standard'
}

function Get-TaskContextDocuments {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$PromptId,
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)]$Manifest
    )

    $documents = [System.Collections.Generic.List[string]]::new()
    if ($Manifest.PSObject.Properties.Name -contains 'contextRouting') {
        foreach ($document in @($Manifest.contextRouting.always)) {
            if (-not $documents.Contains([string]$document)) {
                $documents.Add([string]$document)
            }
        }
        foreach ($group in @($Manifest.contextRouting.groups)) {
            if (@($group.promptIds) -notcontains $PromptId) {
                continue
            }
            foreach ($document in @($group.documents)) {
                if (-not $documents.Contains([string]$document)) {
                    $documents.Add([string]$document)
                }
            }
        }
    }
    else {
        foreach ($document in @('AGENTS.md', 'EXECUTION_CONTRACT.md', 'APP_CONTEXT.md', 'IMPLEMENTATION_STATUS.md')) {
            $documents.Add($document)
        }
    }
    if ($null -ne $State.activeChange -and -not $documents.Contains('CHANGE_CONTROL.md')) {
        $documents.Add('CHANGE_CONTROL.md')
    }

    return @(
        foreach ($document in $documents) {
            $path = Join-Path $Root $document
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                throw "Context routing requires a missing document: $document"
            }
            [ordered]@{
                path = $document
                sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
            }
        }
    )
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
    $executionProfile = Get-PromptExecutionProfile -PromptId $id -Manifest $Manifest
    $profileDefinition = $Manifest.executionProfiles.$executionProfile
    $contextDocuments = @(Get-TaskContextDocuments -Root $Root -PromptId $id -State $State -Manifest $Manifest)
    $contextLines = @($contextDocuments | ForEach-Object { "- ``$($_.path)`` — SHA-256 ``$($_.sha256)``" }) -join [Environment]::NewLine

    $executionInstructions = if (Test-ProgrammerControlledWorkflow -Manifest $Manifest) {
@"
Use `$advance-app-continue` and execute only this prompt. Do not start another
prompt in the same task. The programmer controls every transition.

Inspect the existing application before changing it. Existing code is evidence,
not proof that the prompt has already been completed. Preserve working behavior
and implement only the missing or explicitly requested scope.

Use a short plan for non-trivial work and proportionate validation. The task
ledger and routine quality gates are available as aids, but do not block normal
local development. Exact authorization remains mandatory for external,
destructive, financial, Git, store and production actions.

Finish by recording an honest result and a decision-ready report:

```powershell
.\software-lifecycle.ps1 record -ProcessRoot "$Root" -PromptId $id -Result completed -Evidence "path or durable evidence" -Summary "what was achieved"
```

Use `partial` or `blocked` when the objective was not fully achieved, and add
one or more `-RemainingWork "specific missing implementation"` values. A
completed result must have no remaining work.

After recording, stop. Report:

- result: completed, partial, blocked or not applicable;
- what was implemented or validated;
- what still needs to be implemented to satisfy this prompt;
- evidence and checks;
- choices: `next`, `repeat`, `correct`, or `skip and advance`.

Do not advance until the programmer explicitly asks. If this prompt has already
run, or a brownfield application may already contain its scope, show the prior
result/evidence or the detected overlap first. Ask whether it should run again
and require a concrete rerun objective before changing files.
"@
    }
    else {
@"
Use `$advance-app-continue`.
Execute this prompt first. Do not skip or merge its result with another prompt.
Use the required-context list above instead of recursively loading every linked
document in the catalog; the prompt may add a specific document when needed.
Resolve material inputs from APP_CONTEXT.md, approved decisions and repository evidence.
For a brownfield initiative, treat the existing application as read-only evidence until the current prompt authorizes a scoped change. Never copy BoilerPlateAdvance over it, replace its Git history/remotes, or mark existing behavior complete without verification.
For non-trivial work, create and maintain a short staged plan before implementation.
Before task actions, start the durable work ledger:

```powershell
.\software-lifecycle.ps1 work-start -ProcessRoot "$Root" -Goal "inspect::Inspect current evidence","change::Execute the scoped work","verify::Run proportionate validation","review::Perform adversarial self-review"
```

Checkpoint each goal with durable evidence. Record every accepted review issue
with `finding-add`, resolve it only with correction and verification evidence,
and run `finding-gate` before completion. A `completed` result is rejected until
all goals, verification, adversarial review and findings pass the closeout gate.
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

After recording this prompt, the same Codex task may continue through at most
one immediately related prompt only when `status` returns a deterministic next
prompt, no gate/decision/authorization is pending, both prompts use compatible
profiles and all work remains local and reversible. Regenerate and read the new
`NEXT_TASK.md`, then start a new ledger attempt. Stop at every gate, decision,
external action, material scope change or ambiguous transition.
"@
    }

    $packet = @"
# Next lifecycle task

Process: $($State.processName)
Process ID: $($State.processId)
Initiative mode: $($State.initiativeMode)
Application root: $(if ([string]::IsNullOrWhiteSpace([string]$State.applicationRoot)) { 'pending until prompt 07' } else { $State.applicationRoot })
Stage: $($stage.id) - $($stage.name)
Prompt: $id
Source: $relativePrompt
Execution profile: $executionProfile

## Required context

Read these files completely for this prompt. Their hashes make the generated
context packet auditable; follow a linked document beyond this list only when
the prompt, a missing decision or a changed surface makes it material.

$contextLines

Profile rule: $($profileDefinition.useWhen)
Minimum evidence: $($profileDefinition.minimumEvidence)
Separated review expected by profile: $($profileDefinition.separateReview)

## Execution contract

$executionInstructions

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

    $releaseChannel = if ($manifest.PSObject.Properties.Name -contains 'releaseChannel') {
        [string]$manifest.releaseChannel
    }
    else {
        'candidate'
    }
    if ($releaseChannel -notin @('candidate', 'stable')) {
        $issues.Add("Manifest releaseChannel must be 'candidate' or 'stable'; found '$releaseChannel'.")
    }
    elseif ($releaseChannel -eq 'stable') {
        try {
            Assert-CatalogEligibleForAutomaticUpgrade -Root $Root -Manifest $manifest
        }
        catch {
            $issues.Add("Stable catalog evidence is invalid: $($_.Exception.Message)")
        }
    }

    if ((Test-TaskLedgerRequired -Manifest $manifest) -and
        [string]$env:ADVANCE_LIFECYCLE_MODE -ne 'governed' -and
        ($null -eq $manifest.executionPolicy.PSObject.Properties['findingsGateRequired'] -or
            -not [bool]$manifest.executionPolicy.findingsGateRequired)) {
        $issues.Add('taskLedgerRequired requires findingsGateRequired in the manifest.')
    }
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
    $programmerControlled = Test-ProgrammerControlledWorkflow -Manifest $manifest
    if ($state.status -notin @('ready', 'partial', 'blocked', 'waiting_decision', 'awaiting_programmer', 'completed')) {
        $issues.Add("Invalid lifecycle status: $($state.status).")
    }
    if ($null -eq $state.PSObject.Properties['cycleNumber'] -or [int]$state.cycleNumber -lt 1) {
        $issues.Add('State cycleNumber is missing or invalid.')
    }
    if ($null -ne $state.PSObject.Properties['activeChange'] -and $null -ne $state.activeChange) {
        if ([string]$state.activeChange.id -notmatch '^CHG-\d{4,}$' -or
            [string]::IsNullOrWhiteSpace([string]$state.activeChange.proposal) -or
            [string]$state.activeChange.status -notin @('in_progress', 'completed')) {
            $issues.Add('State activeChange is malformed.')
        }
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
    foreach ($number in 1..76) {
        if ($number -notin $numbers) {
            $issues.Add("Missing prompt id: $('{0:D2}' -f $number)")
        }
    }

    foreach ($id in 1..76 | ForEach-Object { '{0:D2}' -f $_ }) {
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

        $structuredAttempts = @(
            @($promptState.attempts) |
                Where-Object { $null -ne $_.PSObject.Properties['id'] }
        )
        $attemptIds = @($structuredAttempts | ForEach-Object { [string]$_.id })
        $duplicateAttemptIds = @(
            $attemptIds |
                Group-Object |
                Where-Object { $_.Count -gt 1 }
        )
        if ($duplicateAttemptIds.Count -gt 0) {
            $issues.Add("Prompt $($property.Name) has duplicate work attempt ids: $($duplicateAttemptIds.Name -join ', ').")
        }
        foreach ($attempt in $structuredAttempts) {
            if ([string]$attempt.promptId -ne [string]$property.Name) {
                $issues.Add("Work attempt $($attempt.id) belongs to prompt '$($attempt.promptId)', not '$($property.Name)'.")
            }
            if ([string]$attempt.result -notin @('in_progress', 'completed', 'partial', 'blocked', 'not_applicable')) {
                $issues.Add("Work attempt $($attempt.id) has invalid result '$($attempt.result)'.")
            }
            $goalIds = @(@($attempt.goals) | ForEach-Object { [string]$_.id })
            if ($goalIds.Count -lt 1) {
                $issues.Add("Work attempt $($attempt.id) has no goals.")
            }
            if (@($goalIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
                $issues.Add("Work attempt $($attempt.id) has duplicate goal ids.")
            }
            foreach ($goalItem in @($attempt.goals)) {
                if ([string]$goalItem.kind -notin @('inspect', 'plan', 'change', 'verify', 'review', 'other')) {
                    $issues.Add("Work attempt $($attempt.id) goal $($goalItem.id) has invalid kind '$($goalItem.kind)'.")
                }
                if ([string]$goalItem.status -notin @('pending', 'completed', 'blocked')) {
                    $issues.Add("Work attempt $($attempt.id) goal $($goalItem.id) has invalid status '$($goalItem.status)'.")
                }
                if ([string]$goalItem.status -eq 'completed' -and
                    [string]::IsNullOrWhiteSpace([string]$goalItem.evidence)) {
                    $issues.Add("Work attempt $($attempt.id) goal $($goalItem.id) completed without evidence.")
                }
            }
            $findingIds = @(@($attempt.findings) | ForEach-Object { [string]$_.id })
            if (@($findingIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
                $issues.Add("Work attempt $($attempt.id) has duplicate finding ids.")
            }
            foreach ($finding in @($attempt.findings)) {
                if ([string]$finding.severity -notin @('critical', 'high', 'medium', 'low')) {
                    $issues.Add("Work attempt $($attempt.id) finding $($finding.id) has invalid severity '$($finding.severity)'.")
                }
                if ([string]$finding.status -notin @('open', 'blocked', 'resolved')) {
                    $issues.Add("Work attempt $($attempt.id) finding $($finding.id) has invalid status '$($finding.status)'.")
                }
                if ([string]$finding.status -eq 'resolved' -and
                    ([string]::IsNullOrWhiteSpace([string]$finding.resolutionEvidence) -or
                        $null -eq $finding.resolutionVerification -or
                        [string]$finding.resolutionVerification.status -ne 'passed')) {
                    $issues.Add("Work attempt $($attempt.id) finding $($finding.id) resolved without passing resolution evidence.")
                }
            }
            if ([string]$attempt.result -eq 'completed') {
                try {
                    Assert-WorkAttemptCanComplete -Attempt $attempt
                }
                catch {
                    $issues.Add($_.Exception.Message)
                }
            }
        }
        if ((Test-TaskLedgerRequired -Manifest $manifest) -and
            $promptState.status -eq 'completed' -and
            @($structuredAttempts | Where-Object { [string]$_.result -eq 'completed' }).Count -lt 1) {
            $issues.Add("Completed prompt $($property.Name) has no completed structured work attempt.")
        }
    }

    if (Test-TaskLedgerRequired -Manifest $manifest) {
        if ($null -eq $state.PSObject.Properties['activeWorkAttemptId']) {
            $issues.Add('State is missing activeWorkAttemptId while the task ledger is required.')
        }
        else {
            $inProgressAttempts = @(
                foreach ($promptProperty in $state.prompts.PSObject.Properties) {
                    @($promptProperty.Value.attempts) |
                        Where-Object {
                            $null -ne $_.PSObject.Properties['id'] -and
                            [string]$_.result -eq 'in_progress'
                        }
                }
            )
            if ([string]::IsNullOrWhiteSpace([string]$state.activeWorkAttemptId)) {
                if ($inProgressAttempts.Count -gt 0) {
                    $issues.Add('In-progress work attempts exist without activeWorkAttemptId.')
                }
            }
            else {
                $activeMatches = @(
                    $inProgressAttempts |
                        Where-Object { [string]$_.id -eq [string]$state.activeWorkAttemptId }
                )
                if ($activeMatches.Count -ne 1) {
                    $issues.Add("activeWorkAttemptId '$($state.activeWorkAttemptId)' must match exactly one in-progress attempt.")
                }
                elseif ([string]$activeMatches[0].promptId -ne [string]$state.currentPrompt) {
                    $issues.Add("Active work attempt '$($state.activeWorkAttemptId)' does not belong to currentPrompt '$($state.currentPrompt)'.")
                }
            }
        }
    }

    $activeStatuses = $(if ($programmerControlled) { @('ready') } else { @('ready', 'partial', 'blocked') })
    $activePromptProperties = @(
        $state.prompts.PSObject.Properties |
            Where-Object { $_.Value.status -in $activeStatuses }
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
    if ($state.status -eq 'awaiting_programmer') {
        if (-not $programmerControlled) {
            $issues.Add('awaiting_programmer requires the programmer-controlled workflow.')
        }
        if ($hasCurrentPrompt) {
            $issues.Add('awaiting_programmer lifecycle cannot have a currentPrompt.')
        }
        if ([string]$state.nextAction -ne 'next | repeat | correct | skip_and_advance') {
            $issues.Add("awaiting_programmer nextAction is invalid: '$($state.nextAction)'.")
        }
        if ($null -eq (Get-LastRecordedPromptId -State $state)) {
            $issues.Add('awaiting_programmer lifecycle has no recorded prompt result.')
        }
        if (@($state.blockers).Count -gt 0) {
            $issues.Add('awaiting_programmer lifecycle cannot retain lifecycle blockers.')
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
        if (-not $programmerControlled) {
            $g10CompletionState = Get-GateState -State $state -Id 'G10'
            if ($g10CompletionState.status -ne 'passed') {
                $issues.Add("Completed lifecycle requires G10 passed; found '$($g10CompletionState.status)'.")
            }
            if ((Get-PromptState -State $state -Id '76').status -ne 'completed') {
                $issues.Add('Completed lifecycle requires prompt 76 completed.')
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
                    $releasePrompt = Get-PromptState -State $state -Id '67'
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
    elseif ($state.status -notin @('waiting_decision', 'awaiting_programmer', 'completed')) {
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
        'CHANGE_CONTROL.md',
        'CLAUDE.md',
        'EXECUTION_CONTRACT.md',
        'EVALUATION_IMPACT_MAP.json',
        'HELP_AND_ACADEMY.md',
        'IMPLEMENTATION_STATUS.md',
        'LIFECYCLE_GATE_EVIDENCE.json',
        'PILOT_APPROVAL.md',
        'PRODUCT_DEFINITION.md',
        'PRODUCT_EXCELLENCE.md',
        'PRODUCT_QUALITY_BASELINE.md',
        'REQUIREMENTS_ENGINEERING_CONTRACT.md',
        'PROMPT_EVALUATION.md',
        'QUALITY_GATES.md',
        'TEST_STRATEGY_CONTRACT.md',
        'VISUAL_SLICE_CONTRACT.md',
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
        cycleNumber = 1
        activeChange = $null
        currentStage = '01'
        currentPrompt = '01'
        lastPrompt = $null
        nextAction = 'execute_prompt'
        activeWorkAttemptId = $null
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
            Write-Host " - Prompt: Use `$advance-app-continue and execute NEXT_TASK.md."
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
    Write-Host " - Prompt: Use `$advance-app-continue and execute NEXT_TASK.md."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ProcessRoot)) {
    throw 'ProcessRoot is required for this command.'
}
$ProcessRoot = Get-FullPath $ProcessRoot
if (-not (Test-Path -LiteralPath $ProcessRoot -PathType Container)) {
    throw "ProcessRoot does not exist: $ProcessRoot"
}

if ($Command -eq 'upgrade') {
    if ((Get-PhysicalPath $ProcessRoot).Equals(
        (Get-PhysicalPath $catalogRoot),
        [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'upgrade requires an external lifecycle instance, not the catalog itself.'
    }

    $sourceManifest = Get-Manifest $catalogRoot
    $targetManifest = Get-Manifest $ProcessRoot
    $targetState = Get-State $ProcessRoot
    if ($targetState.status -eq 'completed') {
        throw 'upgrade does not mutate a completed lifecycle baseline.'
    }
    if ($null -ne (Get-ActiveWorkAttempt -State $targetState -AllowMissing)) {
        throw "upgrade requires an idle lifecycle; active attempt '$($targetState.activeWorkAttemptId)' must finish first."
    }
    if ([string]$targetState.catalogVersion -ne [string]$targetManifest.catalogVersion) {
        throw 'upgrade requires the existing state and manifest to match before migration.'
    }
    $sameCatalogVersion = [string]$targetManifest.catalogVersion -eq [string]$sourceManifest.catalogVersion
    if ($sameCatalogVersion -and -not $ConfirmMigration) {
        $unchangedPacket = $(if (-not [string]::IsNullOrWhiteSpace([string]$targetState.currentPrompt)) {
            New-TaskPacket -Root $ProcessRoot -State $targetState -Manifest $targetManifest
        } else { $null })
        Write-Host "PASS: lifecycle already uses catalog $($sourceManifest.catalogVersion)." -ForegroundColor Green
        if ($null -ne $unchangedPacket) {
            Write-Host " - Task packet: $unchangedPacket"
        }
        else {
            Write-Host " - Waiting for programmer: $($targetState.nextAction)"
        }
        exit 0
    }
    if ((Compare-CatalogVersion `
            -Left ([string]$sourceManifest.catalogVersion) `
            -Right ([string]$targetManifest.catalogVersion)) -lt 0) {
        throw "upgrade refuses to downgrade catalog $($targetManifest.catalogVersion) to $($sourceManifest.catalogVersion)."
    }

    $sourceChannel = $(if ($sourceManifest.PSObject.Properties.Name -contains 'releaseChannel') {
        [string]$sourceManifest.releaseChannel
    } else { 'candidate' })
    $explicitMigration = $ConfirmMigration -and $AcceptCandidateCatalog
    if ($sourceChannel -eq 'stable') {
        Assert-CatalogEligibleForAutomaticUpgrade -Root $catalogRoot -Manifest $sourceManifest
    }
    elseif (-not $explicitMigration) {
        throw "upgrade only accepts a stable catalog automatically; source $($sourceManifest.catalogVersion) is '$sourceChannel'. Use -ConfirmMigration -AcceptCandidateCatalog -Objective only after the programmer explicitly accepts a controlled candidate migration."
    }
    if ($ConfirmMigration) {
        Require-SafeText -Value $Objective -Label 'Objective'
    }

    if ([int]$targetManifest.schemaVersion -ne [int]$sourceManifest.schemaVersion) {
        throw 'upgrade does not support a schema-version change; provide a dedicated schema migrator.'
    }
    $sourcePromptIds = @($sourceManifest.stages | ForEach-Object { @($_.promptIds) } | Sort-Object -Unique)
    $targetPromptIds = @($targetState.prompts.PSObject.Properties.Name | Sort-Object -Unique)
    $sourcePromptIdentities = Get-PromptIdentityMap -Root $catalogRoot
    $targetPromptIdentities = Get-PromptIdentityMap -Root $ProcessRoot
    $promptIdentityMigration = Get-PromptIdentityMigrationMap `
        -SourceIdentities $sourcePromptIdentities `
        -TargetIdentities $targetPromptIdentities `
        -TargetPromptIds $targetPromptIds `
        -ConfirmMigration:$ConfirmMigration
    $identityRemaps = @(Convert-StatePromptIdentities `
        -State $targetState -Migration $promptIdentityMigration)
    $migratedTargetPromptIds = @($targetState.prompts.PSObject.Properties.Name | Sort-Object -Unique)
    $addedPromptIds = @($sourcePromptIds | Where-Object { $_ -notin $migratedTargetPromptIds })
    if (($addedPromptIds.Count -gt 0 -or
        [int]$targetManifest.promptCount -ne [int]$sourceManifest.promptCount) -and
        -not $ConfirmMigration) {
        throw 'upgrade requires -ConfirmMigration and an Objective because the prompt catalog expands.'
    }
    if ((Test-ProgrammerControlledWorkflow -Manifest $sourceManifest) -and
        -not (Test-ProgrammerControlledWorkflow -Manifest $targetManifest) -and
        -not $ConfirmMigration) {
        throw 'upgrade requires -ConfirmMigration and an Objective because the workflow mode changes.'
    }

    $mergedPromptIds = @(Merge-CatalogPromptsIntoState `
        -State $targetState -SourceManifest $sourceManifest -SourceRoot $catalogRoot)
    $convertedWorkflow = Convert-LegacyStateToProgrammerControlled `
        -State $targetState -TargetManifest $targetManifest -SourceManifest $sourceManifest

    $removedStalePromptPaths = @(Remove-StaleCatalogPromptFiles `
        -SourceRoot $catalogRoot -TargetRoot $ProcessRoot -SourcePromptIds $sourcePromptIds)

    foreach ($directory in @('prompts', 'scripts', '.agents')) {
        Copy-Item -LiteralPath (Join-Path $catalogRoot $directory) `
            -Destination $ProcessRoot -Recurse -Force
    }
    foreach ($file in @(
        'AGENTS.md',
        'CHANGE_CONTROL.md',
        'CLAUDE.md',
        'EXECUTION_CONTRACT.md',
        'EVALUATION_IMPACT_MAP.json',
        'HELP_AND_ACADEMY.md',
        'PILOT_APPROVAL.md',
        'PRODUCT_EXCELLENCE.md',
        'REQUIREMENTS_ENGINEERING_CONTRACT.md',
        'PROMPT_EVALUATION.md',
        'QUALITY_GATES.md',
        'TEST_STRATEGY_CONTRACT.md',
        'VISUAL_SLICE_CONTRACT.md',
        'PROCESS_MANIFEST.json',
        'README.md',
        'START_HERE.md',
        'software-lifecycle.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $catalogRoot $file) `
            -Destination (Join-Path $ProcessRoot $file) -Force
    }

    $definitionPath = Join-Path $ProcessRoot 'PRODUCT_DEFINITION.md'
    $definition = Get-Content -Raw -Encoding UTF8 -LiteralPath $definitionPath
    $legacyDecision = '- `REWORK` — existem lacunas concretas que devem regressar aos prompts 01, 02 ou 03.'
    $currentDecision = @'
- `REWORK` — existem lacunas concretas; o prompt 04 permanece ativo quando
  faltam evidência, viabilidade ou aprovação e só reabre 01, 02 ou 03 se a fonte
  canónica desse prompt tiver de mudar.
'@
    if ($definition.Contains($legacyDecision)) {
        $definition = $definition.Replace($legacyDecision, $currentDecision.TrimEnd())
    }
    $legacyRouting = @'
1. mantém a decisão `REWORK` ou usa `NO-GO` quando a oportunidade tiver sido rejeitada;
2. identifica exatamente o prompt 01, 02 ou 03 que deve ser repetido;
3. regista o bloqueio em `IMPLEMENTATION_STATUS.md`;
4. não inicia arquitetura, seleção de módulos, threat model técnico ou criação do projeto.
'@
    $currentRouting = @'
1. mantém a decisão `REWORK` ou usa `NO-GO` quando a oportunidade tiver sido rejeitada;
2. mantém o prompt 04 quando falta autorização, investigação/teste a executar
   ou incorporar, orçamento, prazo, competências ou aprovação da versão;
3. reabre exatamente o prompt 01, 02 ou 03 apenas quando for necessário alterar,
   respetivamente, oportunidade/público, identidade ou requisitos;
4. regista em `IMPLEMENTATION_STATUS.md` a ação mínima, owner, evidência esperada
   e eventual prompt proprietário, sem tratar DOR-11/DOR-12 como causas para
   repetir a descoberta;
5. não inicia arquitetura, seleção de módulos, threat model técnico ou criação do projeto.
'@
    if ($definition.Contains($legacyRouting.TrimEnd())) {
        $definition = $definition.Replace($legacyRouting.TrimEnd(), $currentRouting.TrimEnd())
    }
    [System.IO.File]::WriteAllText($definitionPath, $definition, $utf8NoBom)

    $gateEvidencePath = Join-Path $ProcessRoot 'LIFECYCLE_GATE_EVIDENCE.json'
    $gateEvidenceObject = Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath | ConvertFrom-Json
    $gateEvidenceObject.catalogVersion = [string]$sourceManifest.catalogVersion
    [System.IO.File]::WriteAllText(
        $gateEvidencePath,
        (($gateEvidenceObject | ConvertTo-Json -Depth 30) + [Environment]::NewLine),
        $utf8NoBom)

    $oldCatalogVersion = [string]$targetState.catalogVersion
    $targetState.catalogVersion = [string]$sourceManifest.catalogVersion
    Add-LifecycleHistoryAction -State $targetState `
        -Action $(if ($sameCatalogVersion) {
            "catalog-migration-repair:$($sourceManifest.catalogVersion)"
        } else {
            "catalog-migration:$oldCatalogVersion->$($sourceManifest.catalogVersion)"
        }) `
        -Evidence $(if ($ConfirmMigration) {
            "controlled migration; identity remaps=$($identityRemaps -join ','); added prompts=$($mergedPromptIds -join ','); removed stale prompt paths=$($removedStalePromptPaths -join ','); programmer-controlled=$convertedWorkflow; objective=$Objective; product content, results, gates, attempts and evidence preserved"
        } else {
            'canonical prompt catalog; product content and lifecycle results preserved'
        })
    Save-State -State $targetState -Root $ProcessRoot

    $upgradedManifest = Get-Manifest $ProcessRoot
    $upgradedState = Get-State $ProcessRoot
    if (-not (Test-Lifecycle -Root $ProcessRoot)) {
        throw 'Lifecycle upgrade copied the catalog but final validation failed.'
    }
    $upgradedPacket = $(if (-not [string]::IsNullOrWhiteSpace([string]$upgradedState.currentPrompt)) {
        New-TaskPacket -Root $ProcessRoot -State $upgradedState -Manifest $upgradedManifest
    } else { $null })
    Write-Host $(if ($sameCatalogVersion) {
        "PASS: lifecycle migration repaired at $($sourceManifest.catalogVersion)."
    } else {
        "PASS: lifecycle migrated from $oldCatalogVersion to $($sourceManifest.catalogVersion)."
    }) -ForegroundColor Green
    Write-Host ' - Product content, prompt results, gates and attempts: preserved'
    Write-Host " - Prompt identity remaps: $(if ($identityRemaps.Count -eq 0) { 'none' } else { $identityRemaps -join ', ' })"
    Write-Host " - Added prompt states: $(if ($mergedPromptIds.Count -eq 0) { 'none' } else { $mergedPromptIds -join ', ' })"
    Write-Host " - Removed stale prompt paths: $(if ($removedStalePromptPaths.Count -eq 0) { 'none' } else { $removedStalePromptPaths -join ', ' })"
    Write-Host " - Programmer-controlled waiting state: $convertedWorkflow"
    Write-Host ' - Embedded lifecycle routing rules: migrated when recognized'
    if ($null -ne $upgradedPacket) {
        Write-Host " - Task packet: $upgradedPacket"
    }
    else {
        Write-Host " - Waiting for programmer: $($upgradedState.nextAction)"
    }
    exit 0
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

if ($Command -eq 'cycle-start') {
    Require-SafeText -Value $ChangeId -Label 'ChangeId'
    Require-SafeText -Value $Evidence -Label 'Evidence'
    if ($ChangeId -notmatch '^CHG-\d{4,}$') {
        throw 'ChangeId must use CHG- followed by at least four digits.'
    }
    if ($state.status -ne 'completed' -or
        -not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt) -or
        $null -ne (Get-ActiveWorkAttempt -State $state -AllowMissing)) {
        throw "cycle-start requires a completed idle lifecycle; found status '$($state.status)'."
    }
    $g10 = Get-GateState -State $state -Id 'G10'
    if ($g10.status -ne 'passed') {
        throw "cycle-start requires G10 passed; found '$($g10.status)'."
    }
    if ([System.IO.Path]::IsPathRooted($Evidence)) {
        throw 'Evidence must be a path relative to ProcessRoot.'
    }
    $proposalPath = [System.IO.Path]::GetFullPath((Join-Path $ProcessRoot $Evidence))
    $rootPrefix = $ProcessRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $proposalPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Change proposal evidence escapes ProcessRoot.'
    }
    if (-not (Test-Path -LiteralPath $proposalPath -PathType Leaf)) {
        throw "Approved change proposal is missing: $Evidence"
    }
    $proposal = Get-Content -Raw -Encoding UTF8 -LiteralPath $proposalPath
    $proposalMarkers = @{}
    foreach ($markerName in @(
        'CHANGE_ID', 'CHANGE_STATUS', 'CHANGE_OWNER', 'CHANGE_APPROVER',
        'CHANGE_BASELINE', 'CHANGE_CREATED_AT', 'CHANGE_APPROVED_AT'
    )) {
        $markerMatch = [regex]::Match(
            $proposal,
            "(?m)^$([regex]::Escape($markerName)):\s*(\S.*?)\s*$"
        )
        if (-not $markerMatch.Success) {
            throw "Change proposal marker is missing: $markerName"
        }
        $proposalMarkers[$markerName] = $markerMatch.Groups[1].Value.Trim()
    }
    if ($proposalMarkers.CHANGE_ID -ne $ChangeId) {
        throw "Change proposal id '$($proposalMarkers.CHANGE_ID)' does not match '$ChangeId'."
    }
    if ($proposalMarkers.CHANGE_STATUS -ne 'approved') {
        throw "Change proposal must be approved; found '$($proposalMarkers.CHANGE_STATUS)'."
    }
    foreach ($markerName in @('CHANGE_OWNER', 'CHANGE_APPROVER', 'CHANGE_BASELINE')) {
        if ($proposalMarkers[$markerName] -match '(?i)^(pending|a preencher|-)$') {
            throw "Change proposal marker has no material value: $markerName"
        }
    }
    foreach ($markerName in @('CHANGE_CREATED_AT', 'CHANGE_APPROVED_AT')) {
        if ($null -eq (Convert-ToTimestamp $proposalMarkers[$markerName])) {
            throw "Change proposal marker is not an ISO timestamp: $markerName"
        }
    }

    $changeDirectory = Split-Path $proposalPath -Parent
    $stateArchivePath = Join-Path $changeDirectory 'BASELINE_LIFECYCLE_STATE.json'
    $gateArchivePath = Join-Path $changeDirectory 'BASELINE_LIFECYCLE_GATE_EVIDENCE.json'
    foreach ($archivePath in @($stateArchivePath, $gateArchivePath)) {
        if (Test-Path -LiteralPath $archivePath) {
            throw "Change baseline archive already exists; refusing to overwrite: $archivePath"
        }
    }
    $gateEvidencePath = Join-Path $ProcessRoot 'LIFECYCLE_GATE_EVIDENCE.json'

    # Do not reuse the typed -GateEvidence parameter name: PowerShell variable
    # names are case-insensitive and would coerce this object back to a string.
    $structuredGateEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $gateEvidencePath | ConvertFrom-Json
    function Reset-GateEvidenceObject {
        param([Parameter(Mandatory)]$Value)
        foreach ($property in @($Value.PSObject.Properties)) {
            if ($property.Value -is [pscustomobject]) {
                Reset-GateEvidenceObject -Value $property.Value
            }
            elseif ($property.Value -is [bool]) {
                $property.Value = $false
            }
            elseif ($property.Value -is [string]) {
                $property.Value = 'pending'
            }
            elseif ($property.Value -is [System.Array]) {
                $property.Value = @()
            }
            elseif ($property.Name -eq 'criticalFindings') {
                $property.Value = -1
            }
        }
    }
    foreach ($gateProperty in @($structuredGateEvidence.gates.PSObject.Properties)) {
        Reset-GateEvidenceObject -Value $gateProperty.Value
    }

    # Prepare every transformation in memory before creating durable archives.
    # This keeps validation/type failures from leaving a half-started cycle.
    [System.IO.File]::WriteAllText(
        $stateArchivePath,
        (($state | ConvertTo-Json -Depth 30) + [Environment]::NewLine),
        $utf8NoBom
    )
    Copy-Item -LiteralPath $gateEvidencePath -Destination $gateArchivePath
    [System.IO.File]::WriteAllText(
        $gateEvidencePath,
        (($structuredGateEvidence | ConvertTo-Json -Depth 30) + [Environment]::NewLine),
        $utf8NoBom
    )

    $conditionalIds = @(
        $manifest.stages |
            ForEach-Object {
                if ($_.PSObject.Properties.Name -contains 'conditionalPromptIds') {
                    @($_.conditionalPromptIds)
                }
            }
    )
    foreach ($promptProperty in @($state.prompts.PSObject.Properties)) {
        $promptId = [string]$promptProperty.Name
        $promptState = $promptProperty.Value
        $promptState.applicability = $(if ($promptId -in $conditionalIds) { 'conditional' } else { 'required' })
        $promptState.status = $(if ($promptId -eq '01') {
            'ready'
        } elseif ($promptId -in $conditionalIds) {
            'not_selected'
        } else {
            'pending'
        })
        $promptState.evidence = $null
    }
    foreach ($gateProperty in @($state.gates.PSObject.Properties)) {
        $gateProperty.Value.status = 'pending'
        $gateProperty.Value.evidence = $null
        $gateProperty.Value.approvedBy = $null
        $gateProperty.Value.updatedAt = $null
        $gateProperty.Value.snapshot = $null
    }
    $state.cycleNumber = $(if ($null -eq $state.PSObject.Properties['cycleNumber']) {
        2
    } else {
        [int]$state.cycleNumber + 1
    })
    $state.activeChange = [ordered]@{
        id = $ChangeId
        proposal = $Evidence.Replace('\', '/')
        baseline = $proposalMarkers.CHANGE_BASELINE
        owner = $proposalMarkers.CHANGE_OWNER
        approver = $proposalMarkers.CHANGE_APPROVER
        approvedAt = $proposalMarkers.CHANGE_APPROVED_AT
        startedAt = [DateTimeOffset]::Now.ToString('o')
        status = 'in_progress'
    }
    $state.activeWorkAttemptId = $null
    $state.activeSlice = $null
    $state.slices = @()
    $state.selectedSurfaces = @()
    $state.selectedOptionalPromptIds = @()
    $state.currentStage = '01'
    $state.currentPrompt = '01'
    $state | Add-Member -NotePropertyName 'lastPrompt' -NotePropertyValue $null -Force
    $state.status = 'ready'
    $state.nextAction = 'execute_prompt'
    $state.blockers = @()
    Add-LifecycleHistoryAction -State $state -Action "cycle-start:$ChangeId" -Evidence $Evidence
    Save-State -State $state -Root $ProcessRoot
    $freshState = Get-State $ProcessRoot
    $packet = New-TaskPacket -Root $ProcessRoot -State $freshState -Manifest $manifest
    Write-Host "CYCLE STARTED: $ChangeId -> prompt 01." -ForegroundColor Green
    Write-Host " - Cycle: $($freshState.cycleNumber)"
    Write-Host " - Archived state: $stateArchivePath"
    Write-Host " - Archived gate evidence: $gateArchivePath"
    Write-Host " - Task packet: $packet"
    exit 0
}

if ($Command -eq 'work-start') {
    if ([string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
        throw 'work-start requires a current prompt.'
    }
    if ($null -ne (Get-ActiveWorkAttempt -State $state -AllowMissing)) {
        throw "Work attempt '$($state.activeWorkAttemptId)' is already active."
    }

    $attempt = New-WorkAttempt -PromptId ([string]$state.currentPrompt) -GoalDefinitions $Goal
    $promptState = Get-PromptState -State $state -Id ([string]$state.currentPrompt)
    $promptState.attempts = @($promptState.attempts) + @($attempt)
    $state.activeWorkAttemptId = $attempt.id
    $promptState.status = 'ready'
    $state.status = 'ready'
    $state.nextAction = 'execute_prompt'
    $state.blockers = @()
    Add-LifecycleHistoryAction -State $state -Action "work-start:$($attempt.id):prompt-$($state.currentPrompt)" `
        -Evidence "goals=$(@($attempt.goals).Count)"
    Save-State -State $state -Root $ProcessRoot
    Write-Host "WORK STARTED: $($attempt.id) for prompt $($state.currentPrompt)." -ForegroundColor Green
    foreach ($goalItem in @($attempt.goals)) {
        Write-Host " - $($goalItem.id) [$($goalItem.kind)]: $($goalItem.description)"
    }
    exit 0
}

if ($Command -eq 'checkpoint') {
    Require-SafeText -Value $GoalId -Label 'GoalId'
    if ([string]::IsNullOrWhiteSpace([string]$CheckpointStatus)) {
        throw 'CheckpointStatus is required.'
    }
    Require-SafeText -Value $Evidence -Label 'Evidence'
    $attempt = Get-ActiveWorkAttempt -State $state
    $matches = @(@($attempt.goals) | Where-Object { [string]$_.id -eq $GoalId })
    if ($matches.Count -ne 1) {
        throw "Goal '$GoalId' must match exactly one goal in work attempt $($attempt.id)."
    }
    $goalItem = $matches[0]
    $goalItem.status = $CheckpointStatus
    $goalItem.evidence = $Evidence
    $goalItem.updatedAt = [DateTimeOffset]::Now.ToString('o')
    if ([string]$goalItem.kind -eq 'review') {
        $attempt.adversarialReview.status = $(if ($CheckpointStatus -eq 'completed') { 'completed' } else { 'pending' })
        $attempt.adversarialReview.evidence = $Evidence
        $attempt.adversarialReview.completedAt = $(if ($CheckpointStatus -eq 'completed') {
            [DateTimeOffset]::Now.ToString('o')
        } else {
            $null
        })
    }
    Add-LifecycleHistoryAction -State $state -Action "checkpoint:$($attempt.id):$($GoalId):$($CheckpointStatus)" `
        -Evidence $Evidence
    Save-State -State $state -Root $ProcessRoot
    Write-Host "CHECKPOINT: $GoalId -> $CheckpointStatus." -ForegroundColor Green
    exit 0
}

if ($Command -eq 'verify') {
    if ([string]::IsNullOrWhiteSpace([string]$VerificationKind)) {
        throw 'VerificationKind is required.'
    }
    $attempt = Get-ActiveWorkAttempt -State $state
    Add-WorkVerification -Attempt $attempt -Kind $VerificationKind -CommandText $VerifyCommand `
        -ExitCode $VerifyExitCode -Evidence $VerifyEvidence
    Add-LifecycleHistoryAction -State $state -Action "verify:$($attempt.id):$VerificationKind" `
        -Evidence $VerifyEvidence
    Save-State -State $state -Root $ProcessRoot
    Write-Host "VERIFIED: $VerificationKind evidence recorded for $($attempt.id)." -ForegroundColor Green
    exit 0
}

if ($Command -eq 'finding-add') {
    foreach ($requiredText in @(
        @{ Value = $Title; Label = 'Title' },
        @{ Value = $Source; Label = 'Source' },
        @{ Value = $Location; Label = 'Location' },
        @{ Value = $Evidence; Label = 'Evidence' }
    )) {
        Require-SafeText -Value $requiredText.Value -Label $requiredText.Label
    }
    if ([string]::IsNullOrWhiteSpace([string]$Severity)) {
        throw 'Severity is required.'
    }
    $attempt = Get-ActiveWorkAttempt -State $state
    $finding = [ordered]@{
        id = 'FIND-{0:D3}' -f (@($attempt.findings).Count + 1)
        title = $Title
        severity = $Severity
        status = 'open'
        source = $Source
        location = $Location
        evidence = $Evidence
        openedAt = [DateTimeOffset]::Now.ToString('o')
        resolvedAt = $null
        resolutionEvidence = $null
        resolutionVerification = $null
    }
    $attempt.findings = @($attempt.findings) + @($finding)
    $attempt.adversarialReview.status = 'pending'
    $attempt.adversarialReview.evidence = $null
    $attempt.adversarialReview.completedAt = $null
    Add-LifecycleHistoryAction -State $state -Action "finding-add:$($attempt.id):$($finding.id):$Severity" `
        -Evidence $Evidence
    Save-State -State $state -Root $ProcessRoot
    Write-Host "FINDING ADDED: $($finding.id) [$Severity] $Title" -ForegroundColor Yellow
    exit 0
}

if ($Command -eq 'finding-resolve') {
    Require-SafeText -Value $FindingId -Label 'FindingId'
    Require-SafeText -Value $ResolutionEvidence -Label 'ResolutionEvidence'
    Require-SafeText -Value $VerifyCommand -Label 'VerifyCommand'
    Require-SafeText -Value $VerifyEvidence -Label 'VerifyEvidence'
    if ($null -eq $VerifyExitCode -or [int]$VerifyExitCode -ne 0) {
        throw 'Resolving a finding requires VerifyExitCode 0.'
    }
    $attempt = Get-ActiveWorkAttempt -State $state
    $matches = @(@($attempt.findings) | Where-Object { [string]$_.id -eq $FindingId })
    if ($matches.Count -ne 1) {
        throw "Finding '$FindingId' must match exactly one finding in work attempt $($attempt.id)."
    }
    $finding = $matches[0]
    if ([string]$finding.status -eq 'resolved') {
        throw "Finding '$FindingId' is already resolved."
    }
    $finding.status = 'resolved'
    $finding.resolvedAt = [DateTimeOffset]::Now.ToString('o')
    $finding.resolutionEvidence = $ResolutionEvidence
    $finding.resolutionVerification = [ordered]@{
        kind = 'command'
        command = $VerifyCommand
        exitCode = [int]$VerifyExitCode
        status = 'passed'
        evidence = $VerifyEvidence
        at = [DateTimeOffset]::Now.ToString('o')
    }
    Add-LifecycleHistoryAction -State $state -Action "finding-resolve:$($attempt.id):$FindingId" `
        -Evidence $ResolutionEvidence
    Save-State -State $state -Root $ProcessRoot
    Write-Host "FINDING RESOLVED: $FindingId." -ForegroundColor Green
    exit 0
}

if ($Command -eq 'finding-gate') {
    $attempt = Get-ActiveWorkAttempt -State $state
    $blockingFindings = @(
        @($attempt.findings) |
            Where-Object { [string]$_.status -in @('open', 'blocked') }
    )
    if ($blockingFindings.Count -gt 0) {
        Write-Host "FAIL: $($blockingFindings.Count) open or blocked finding(s)." -ForegroundColor Red
        foreach ($finding in $blockingFindings) {
            Write-Host " - $($finding.id) [$($finding.severity)] $($finding.title)"
        }
        exit 1
    }
    Write-Host "PASS: no open or blocked findings in $($attempt.id)." -ForegroundColor Green
    exit 0
}

if ($Command -eq 'closeout') {
    Require-SafeText -Value $Evidence -Label 'Evidence'
    Require-SafeText -Value $ReviewEvidence -Label 'ReviewEvidence'
    if ([string]::IsNullOrWhiteSpace([string]$VerificationKind)) {
        throw 'VerificationKind is required.'
    }
    $attempt = Get-ActiveWorkAttempt -State $state
    $blockedGoals = @(@($attempt.goals) | Where-Object { [string]$_.status -eq 'blocked' })
    if ($blockedGoals.Count -gt 0) {
        throw "closeout cannot overwrite blocked goals: $($blockedGoals.id -join ', '). Resolve and checkpoint them explicitly."
    }
    foreach ($goalItem in @($attempt.goals)) {
        if ([string]$goalItem.status -ne 'completed') {
            $goalItem.status = 'completed'
            $goalItem.evidence = $Evidence
            $goalItem.updatedAt = [DateTimeOffset]::Now.ToString('o')
        }
    }
    $alreadyVerified = @(
        @($attempt.verification) |
            Where-Object {
                [string]$_.status -eq 'passed' -and
                [string]$_.kind -eq $VerificationKind -and
                [string]$_.evidence -eq [string]$VerifyEvidence
            }
    ).Count -gt 0
    if (-not $alreadyVerified) {
        Add-WorkVerification -Attempt $attempt -Kind $VerificationKind -CommandText $VerifyCommand `
            -ExitCode $VerifyExitCode -Evidence $VerifyEvidence
    }
    $attempt.adversarialReview.type = 'self_adversarial'
    $attempt.adversarialReview.status = 'completed'
    $attempt.adversarialReview.evidence = $ReviewEvidence
    $attempt.adversarialReview.completedAt = [DateTimeOffset]::Now.ToString('o')
    Assert-WorkAttemptCanComplete -Attempt $attempt
    Add-LifecycleHistoryAction -State $state -Action "closeout:$($attempt.id)" -Evidence $Evidence
    Save-State -State $state -Root $ProcessRoot
    Write-Host "CLOSEOUT PASS: $($attempt.id) is ready to record." -ForegroundColor Green
    exit 0
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
    $activeAttempt = Get-ActiveWorkAttempt -State $state -AllowMissing
    if ($null -ne $activeAttempt) {
        $completedGoals = @(@($activeAttempt.goals) | Where-Object { $_.status -eq 'completed' }).Count
        $openFindings = @(@($activeAttempt.findings) | Where-Object { $_.status -in @('open', 'blocked') }).Count
        $passingVerification = @(@($activeAttempt.verification) | Where-Object { $_.status -eq 'passed' }).Count
        Write-Host "Active work attempt: $($activeAttempt.id)"
        Write-Host " - Goals: $completedGoals/$(@($activeAttempt.goals).Count) completed"
        Write-Host " - Passing verification records: $passingVerification"
        Write-Host " - Open/blocked findings: $openFindings"
        Write-Host " - Adversarial review: $($activeAttempt.adversarialReview.status)"
    }
    if ($null -ne $state.activeSlice) {
        Write-Host "Active/latest slice: $($state.activeSlice.id) [$($state.activeSlice.kind)/$($state.activeSlice.surface)] $($state.activeSlice.status)"
        Write-Host " - Requirements: $($state.activeSlice.requirements)"
        Write-Host " - Acceptance: $($state.activeSlice.acceptanceCriteria)"
        Write-Host " - Out of scope: $($state.activeSlice.outOfScope)"
    }
    Write-Host "Next action: $($state.nextAction)"
    if ($state.status -eq 'awaiting_programmer') {
        $lastId = Get-LastRecordedPromptId -State $state
        if ($null -ne $lastId) {
            $lastPromptState = Get-PromptState -State $state -Id $lastId
            Write-Host "Last prompt result: $lastId -> $($lastPromptState.status)"
            if ($null -ne $lastPromptState.PSObject.Properties['summary']) {
                Write-Host " - Summary: $($lastPromptState.summary)"
            }
            if ($null -ne $lastPromptState.PSObject.Properties['remainingWork'] -and
                @($lastPromptState.remainingWork).Count -gt 0) {
                Write-Host ' - Remaining implementation:'
                @($lastPromptState.remainingWork) | ForEach-Object { Write-Host "   - $_" }
            }
        }
    }
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
    elseif ($state.status -eq 'awaiting_programmer') {
        Write-Host "Programmer choices: next | repeat | correct | skip and advance"
        Write-Host "Next command: .\software-lifecycle.ps1 advance -ProcessRoot `"$ProcessRoot`""
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
                if ($selection -eq '67') {
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

if ($Command -eq 'next' -and (Test-ProgrammerControlledWorkflow -Manifest $manifest) -and
    [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
    $Command = 'advance'
}

if ($Command -eq 'advance') {
    if (-not (Test-ProgrammerControlledWorkflow -Manifest $manifest)) {
        throw 'advance is available only in the programmer-controlled workflow.'
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
        throw "Prompt $($state.currentPrompt) is still active. Finish and record it before advancing."
    }
    if ($state.status -ne 'awaiting_programmer') {
        throw "advance requires lifecycle status awaiting_programmer; found '$($state.status)'."
    }
    $lastId = Get-LastRecordedPromptId -State $state
    if ($null -eq $lastId) {
        throw 'No recorded prompt exists to advance from.'
    }
    $lastState = Get-PromptState -State $state -Id $lastId
    $skippedIncomplete = $false
    if ($lastState.status -in @('partial', 'blocked')) {
        if (-not $AcceptIncomplete) {
            Write-Host "CONFIRMATION REQUIRED: prompt $lastId is $($lastState.status)." -ForegroundColor Yellow
            Write-Host ' - Missing implementation:'
            @($lastState.remainingWork) | ForEach-Object { Write-Host "   - $_" }
            Write-Host ' - Use skip and advance only after stating why the incomplete work is being accepted.'
            Write-Host " - Command: .\software-lifecycle.ps1 advance -ProcessRoot `"$ProcessRoot`" -AcceptIncomplete -Objective `"<reason>`""
            exit 0
        }
        Require-SafeText -Value $Objective -Label 'Objective'
        $skippedIncomplete = $true
    }

    $orderedPromptIds = @(Get-OrderedPromptIds -Manifest $manifest)
    $lastIndex = [Array]::IndexOf([string[]]$orderedPromptIds, [string]$lastId)
    if ($lastIndex -lt 0) {
        throw "Last prompt $lastId is absent from the manifest order."
    }
    $nextId = $null
    for ($index = $lastIndex + 1; $index -lt $orderedPromptIds.Count; $index++) {
        $candidateId = [string]$orderedPromptIds[$index]
        $candidateState = Get-PromptState -State $state -Id $candidateId
        if ($candidateState.status -ne 'not_selected') {
            $nextId = $candidateId
            break
        }
    }
    if ($null -eq $nextId) {
        $state.status = 'completed'
        $state.nextAction = 'none'
        $state.blockers = @()
        $incomplete = @(
            $state.prompts.PSObject.Properties |
                Where-Object { $_.Value.status -in @('partial', 'blocked', 'pending', 'ready') }
        )
        $state | Add-Member -NotePropertyName 'completion' `
            -NotePropertyValue $(if ($incomplete.Count -eq 0) { 'complete' } else { 'with_gaps' }) -Force
        Save-State -State $state -Root $ProcessRoot
        Write-Host 'PROCESS FINISHED.' -ForegroundColor Green
        Write-Host " - Completion: $($state.completion)"
        Write-Host " - Prompts with pending or incomplete work: $($incomplete.Count)"
        exit 0
    }

    $nextState = Get-PromptState -State $state -Id $nextId
    $previousRuns = @(Get-PromptResultHistory -State $state -Id $nextId)
    if ($previousRuns.Count -gt 0) {
        if (-not $ConfirmRepeat) {
            Write-PromptHistoryNotice -State $state -Id $nextId -PromptState $nextState
            exit 0
        }
        Require-SafeText -Value $Objective -Label 'Objective'
        $nextState | Add-Member -NotePropertyName 'rerunObjective' -NotePropertyValue $Objective -Force
    }
    Test-EntryGate -State $state -Manifest $manifest -NextId $nextId
    Set-CurrentPrompt -State $state -Manifest $manifest -Id $nextId
    $advanceAction = $(if ($skippedIncomplete) { "skip-incomplete-and-advance:$lastId->$nextId" } else { "advance:$lastId->$nextId" })
    Add-LifecycleHistoryAction -State $state -Action $advanceAction `
        -Evidence $(if ([string]::IsNullOrWhiteSpace($Objective)) { 'programmer requested next' } else { $Objective })
    Save-State -State $state -Root $ProcessRoot
    $freshState = Get-State $ProcessRoot
    $packet = New-TaskPacket -Root $ProcessRoot -State $freshState -Manifest $manifest
    Write-Host "READY: prompt $nextId prepared only after the programmer requested next." -ForegroundColor Green
    Write-Host " - Task packet: $packet"
    exit 0
}

if ($Command -in @('request', 'repeat')) {
    if (-not (Test-ProgrammerControlledWorkflow -Manifest $manifest)) {
        throw "$Command is available only in the programmer-controlled workflow."
    }
    $requestedId = Normalize-PromptId $PromptId
    if ($null -eq $requestedId) {
        if ($Command -eq 'repeat') {
            $requestedId = Get-LastRecordedPromptId -State $state
        }
        if ($null -eq $requestedId) {
            throw 'PromptId is required because no previous prompt result exists.'
        }
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$state.currentPrompt)) {
        if ([string]$state.currentPrompt -eq $requestedId -and
            @(Get-PromptResultHistory -State $state -Id $requestedId).Count -eq 0) {
            if ([string]$state.initiativeMode -eq 'brownfield') {
                $currentState = Get-PromptState -State $state -Id $requestedId
                if (-not $ConfirmRepeat) {
                    Write-PromptHistoryNotice -State $state -Id $requestedId -PromptState $currentState -BrownfieldOverlap
                    exit 0
                }
                Require-SafeText -Value $Objective -Label 'Objective'
                $currentState | Add-Member -NotePropertyName 'rerunObjective' -NotePropertyValue $Objective -Force
                Add-LifecycleHistoryAction -State $state -Action "confirm-brownfield-prompt:$requestedId" -Evidence $Objective
                Save-State -State $state -Root $ProcessRoot
                $state = Get-State $ProcessRoot
            }
            $packet = New-TaskPacket -Root $ProcessRoot -State $state -Manifest $manifest
            Write-Host "READY: prompt $requestedId is already prepared: $packet" -ForegroundColor Green
            if ([string]$state.initiativeMode -eq 'brownfield') {
                Write-Host " - Objective: $Objective"
            }
            exit 0
        }
        throw "Prompt $($state.currentPrompt) is active. Finish it before requesting prompt $requestedId."
    }

    $requestedState = Get-PromptState -State $state -Id $requestedId
    $history = @(Get-PromptResultHistory -State $state -Id $requestedId)
    $brownfieldOverlap = [string]$state.initiativeMode -eq 'brownfield'
    $confirmationRequired = $history.Count -gt 0 -or $brownfieldOverlap -or $Command -eq 'repeat'
    if ($confirmationRequired -and -not $ConfirmRepeat) {
        Write-PromptHistoryNotice -State $state -Id $requestedId -PromptState $requestedState `
            -BrownfieldOverlap:$brownfieldOverlap
        exit 0
    }
    if ($confirmationRequired) {
        Require-SafeText -Value $Objective -Label 'Objective'
        $requestedState | Add-Member -NotePropertyName 'rerunObjective' -NotePropertyValue $Objective -Force
    }
    Test-EntryGate -State $state -Manifest $manifest -NextId $requestedId
    Set-CurrentPrompt -State $state -Manifest $manifest -Id $requestedId
    Add-LifecycleHistoryAction -State $state -Action "request:$requestedId" `
        -Evidence $(if ([string]::IsNullOrWhiteSpace($Objective)) { 'programmer requested prompt' } else { $Objective })
    Save-State -State $state -Root $ProcessRoot
    $freshState = Get-State $ProcessRoot
    $packet = New-TaskPacket -Root $ProcessRoot -State $freshState -Manifest $manifest
    Write-Host "READY: prompt $requestedId prepared." -ForegroundColor Green
    if ($confirmationRequired) {
        Write-Host " - Rerun objective: $Objective"
    }
    Write-Host " - Task packet: $packet"
    exit 0
}

if ($Command -eq 'next') {
    $packet = New-TaskPacket -Root $ProcessRoot -State $state -Manifest $manifest
    Write-Host "PASS: task packet prepared: $packet" -ForegroundColor Green
    Write-Host "Prompt: Use `$advance-app-continue and execute NEXT_TASK.md."
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
        '25' {
            Assert-ApplicabilityDecisions -State $state `
                -PromptIds @('14', '15', '16', '17', '18', '19', '27', '28', '29', '30') `
                -BeforePrompt $selectedId
        }
        '42' {
            Assert-ApplicabilityDecisions -State $state `
                -PromptIds (@('31') + @(33..41 | ForEach-Object { '{0:D2}' -f $_ })) `
                -BeforePrompt $selectedId
        }
        '51' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('48', '49', '50') -BeforePrompt $selectedId
        }
        '54' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('53') -BeforePrompt $selectedId
        }
        '61' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('59', '60') -BeforePrompt $selectedId
        }
        '70' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('68', '69') -BeforePrompt $selectedId
        }
        '73' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('72') -BeforePrompt $selectedId
        }
        '75' {
            Assert-ApplicabilityDecisions -State $state -PromptIds @('72', '74') -BeforePrompt $selectedId
        }
    }

    if ($selectedId -in @('21', '27', '29')) {
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
                $selectedId -eq '21') {
                throw "Cannot start slice $SliceId while slice $($state.activeSlice.id) is in progress."
            }
            if ($state.activeSlice.status -eq 'in_progress' -and
                $selectedId -in @('27', '29') -and
                [string]$state.activeSlice.id -ne $SliceId) {
                throw "Foundation belongs to active slice $($state.activeSlice.id); select the same SliceId before starting another slice."
            }
            if ($state.activeSlice.status -eq 'in_progress' -and
                $selectedId -in @('27', '29') -and
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
        slice = $(if ($selectedId -in @('21', '27', '29')) {
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
        if ($null -ne $state.PSObject.Properties['activeChange'] -and $null -ne $state.activeChange) {
            $state.activeChange.status = 'completed'
            $state.activeChange | Add-Member -NotePropertyName 'completedAt' `
                -NotePropertyValue ([DateTimeOffset]::Now.ToString('o')) -Force
        }
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
    $programmerControlled = Test-ProgrammerControlledWorkflow -Manifest $manifest
    $normalizedRemainingWork = @()
    if ($programmerControlled) {
        Require-SafeText -Value $Summary -Label 'Summary'
        $normalizedRemainingWork = @(
            @($RemainingWork) |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
                ForEach-Object {
                    Require-SafeText -Value ([string]$_) -Label 'RemainingWork'
                    ([string]$_).Trim()
                }
        )
        if ($Result -in @('partial', 'blocked') -and $normalizedRemainingWork.Count -eq 0) {
            throw "Result '$Result' requires at least one specific RemainingWork item."
        }
        if ($Result -in @('completed', 'not_applicable') -and $normalizedRemainingWork.Count -gt 0) {
            throw "Result '$Result' cannot contain RemainingWork; use partial or blocked."
        }
    }
    if ($PromptId -ne [string]$state.currentPrompt) {
        throw "Out-of-order result: current prompt is $($state.currentPrompt), received $PromptId."
    }

    $promptState = Get-PromptState -State $state -Id $PromptId
    if ($Result -eq 'not_applicable' -and $promptState.applicability -eq 'required') {
        throw "Required prompt $PromptId cannot be marked not_applicable."
    }

    if (Test-TaskLedgerRequired -Manifest $manifest) {
        $attempt = Get-ActiveWorkAttempt -State $state
        if ([string]$attempt.promptId -ne $PromptId) {
            throw "Active work attempt $($attempt.id) belongs to prompt $($attempt.promptId), not $PromptId."
        }
        if ($Result -eq 'completed') {
            Assert-WorkAttemptCanComplete -Attempt $attempt
        }
        $attempt.result = $Result
        $attempt.evidence = $Evidence
        $attempt.finishedAt = [DateTimeOffset]::Now.ToString('o')
        $state.activeWorkAttemptId = $null
    }
    else {
        # A lifecycle converted to the non-ledger workflow may retain a legacy
        # active-attempt pointer. It has no authority in this mode and would
        # leave the state structurally invalid after currentPrompt is cleared.
        $state.activeWorkAttemptId = $null
        $attempt = [ordered]@{
            at = [DateTimeOffset]::Now.ToString('o')
            result = $Result
            evidence = $Evidence
            summary = $Summary
            remainingWork = @($normalizedRemainingWork)
        }
        $promptState.attempts = @($promptState.attempts) + @($attempt)
    }
    $promptState.status = $Result
    $promptState.evidence = $Evidence
    if ($programmerControlled) {
        $promptState | Add-Member -NotePropertyName 'summary' -NotePropertyValue $Summary -Force
        $promptState | Add-Member -NotePropertyName 'remainingWork' -NotePropertyValue @($normalizedRemainingWork) -Force
        $promptState | Add-Member -NotePropertyName 'finishedAt' `
            -NotePropertyValue ([DateTimeOffset]::Now.ToString('o')) -Force
    }
    if ($PromptId -in @('28', '30') -and $Result -eq 'completed' -and $null -ne $state.activeSlice) {
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

    if ($PromptId -eq '67' -and $Result -eq 'completed') {
        $g09 = Get-GateState -State $state -Id 'G09'
        if ($g09.status -ne 'passed') {
            throw "Prompt 67 cannot be completed because G09 is '$($g09.status)'."
        }
        $releaseValidator = Join-Path $ProcessRoot 'scripts/Test-LifecycleGateEvidence.ps1'
        $releaseValidatorOutput = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $releaseValidator `
            -GateId G09 -ProcessRoot $ProcessRoot -Phase release_completed
        $releaseValidatorExitCode = $LASTEXITCODE
        $releaseValidatorOutput | Out-Host
        if ($releaseValidatorExitCode -ne 0) {
            throw 'Prompt 67 release-completion evidence failed validation.'
        }
        Set-G09DeploymentSnapshot -State $state -Root $ProcessRoot
    }

    if (-not $programmerControlled -and $PromptId -eq '04' -and $Result -eq 'completed') {
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
        summary = $Summary
        remainingWork = @($normalizedRemainingWork)
    }
    $state.history = @($state.history) + @($historyItem)

    if ($programmerControlled) {
        $state | Add-Member -NotePropertyName 'lastPrompt' -NotePropertyValue $PromptId -Force
        $state.currentPrompt = $null
        $state.status = 'awaiting_programmer'
        $state.nextAction = 'next | repeat | correct | skip_and_advance'
        $state.blockers = @()
        Save-State -State $state -Root $ProcessRoot

        $colour = $(if ($Result -eq 'completed') { 'Green' } else { 'Yellow' })
        Write-Host "PROMPT $PromptId RESULT: $Result" -ForegroundColor $colour
        Write-Host " - Summary: $Summary"
        Write-Host " - Evidence: $Evidence"
        if ($normalizedRemainingWork.Count -eq 0) {
            Write-Host ' - Remaining implementation: none.'
        }
        else {
            Write-Host ' - Remaining implementation:'
            $normalizedRemainingWork | ForEach-Object { Write-Host "   - $_" }
        }
        Write-Host ' - Waiting for programmer: next | repeat | correct | skip and advance'
        exit 0
    }

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
        if ($PromptId -eq '76' -and $g10.status -eq 'passed') {
            $state.status = 'completed'
            $state.nextAction = 'none'
            if ($null -ne $state.PSObject.Properties['activeChange'] -and $null -ne $state.activeChange) {
                $state.activeChange.status = 'completed'
                $state.activeChange | Add-Member -NotePropertyName 'completedAt' `
                    -NotePropertyValue ([DateTimeOffset]::Now.ToString('o')) -Force
            }
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
