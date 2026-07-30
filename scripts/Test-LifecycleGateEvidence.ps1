[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('G06', 'G07', 'G08', 'G09', 'G10')]
    [string]$GateId,
    [string]$EvidencePath,
    [string]$ProcessRoot,
    [string]$ApprovedBy,
    [ValidateSet('gate', 'release_completed')]
    [string]$Phase = 'gate'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

if ([string]::IsNullOrWhiteSpace($ProcessRoot)) {
    $ProcessRoot = Split-Path $PSScriptRoot -Parent
}
$ProcessRoot = [System.IO.Path]::GetFullPath($ProcessRoot).TrimEnd('\', '/')
if ([string]::IsNullOrWhiteSpace($EvidencePath)) {
    $EvidencePath = Join-Path $ProcessRoot 'LIFECYCLE_GATE_EVIDENCE.json'
}
$EvidencePath = [System.IO.Path]::GetFullPath($EvidencePath)
$manifestPath = Join-Path $ProcessRoot 'PROCESS_MANIFEST.json'
foreach ($path in @($EvidencePath, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Lifecycle gate evidence input is missing: $path"
    }
}

$evidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $EvidencePath | ConvertFrom-Json
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$issues = [System.Collections.Generic.List[string]]::new()

function Add-Issue {
    param([Parameter(Mandatory)][string]$Message)
    $issues.Add($Message)
}

function Test-Material {
    param([AllowNull()][string]$Value)
    return -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -notmatch '(?i)^(pending|a preencher|-)$' -and
        $Value -ne [string][char]0x2014
}

function Require-Material {
    param([AllowNull()][string]$Value, [Parameter(Mandatory)][string]$Label)
    if (-not (Test-Material $Value)) {
        Add-Issue "$Label is missing or pending."
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

function Require-ExactTrueChecks {
    param(
        [AllowNull()]$Checks,
        [Parameter(Mandatory)][string[]]$RequiredNames
    )
    if ($null -eq $Checks) {
        Add-Issue "$GateId checks object is missing."
        return
    }
    $actualNames = @($Checks.PSObject.Properties | ForEach-Object { $_.Name })
    foreach ($requiredName in $RequiredNames) {
        if ($requiredName -notin $actualNames) {
            Add-Issue "$GateId required check '$requiredName' is missing."
        }
        elseif ($Checks.$requiredName -isnot [bool] -or $Checks.$requiredName -ne $true) {
            Add-Issue "$GateId check '$requiredName' is not true."
        }
    }
    foreach ($actualName in $actualNames) {
        if ($actualName -notin $RequiredNames) {
            Add-Issue "$GateId contains unknown check '$actualName'."
        }
    }
}

if (($evidence.schemaVersion -isnot [int] -and $evidence.schemaVersion -isnot [long]) -or
    $evidence.schemaVersion -ne 2) {
    Add-Issue "Unsupported evidence schemaVersion '$($evidence.schemaVersion)'."
}
if ([string]$evidence.catalogVersion -ne [string]$manifest.catalogVersion) {
    Add-Issue "Evidence catalogVersion '$($evidence.catalogVersion)' does not match '$($manifest.catalogVersion)'."
}
if ($null -eq $evidence.gates.PSObject.Properties[$GateId]) {
    Add-Issue "Evidence does not contain gate $GateId."
}

if ($issues.Count -eq 0) {
    $gate = $evidence.gates.$GateId
    if ($gate.status -ne 'approved') {
        Add-Issue "$GateId evidence status must be approved."
    }
    Require-Material -Value ([string]$gate.approvedBy.name) -Label "$GateId approver name"
    Require-Material -Value ([string]$gate.approvedBy.identity) -Label "$GateId approver identity"
    Require-Material -Value ([string]$gate.approvedBy.role) -Label "$GateId approver role"
    if ([string]$gate.approvedBy.identity -notmatch '(^[^@\s]+@[^@\s]+\.[^@\s]+$)|(^urn:)|(^https://)') {
        Add-Issue "$GateId approver identity must be an email, urn or https identity."
    }
    if (-not [string]::IsNullOrWhiteSpace($ApprovedBy) -and [string]$gate.approvedBy.name -ne $ApprovedBy) {
        Add-Issue "$GateId recorder approver '$ApprovedBy' does not match evidence approver '$($gate.approvedBy.name)'."
    }
    $approvalDate = Convert-ToTimestamp $gate.approvedAt
    if ($null -eq $approvalDate) {
        Add-Issue "$GateId approvedAt is not a valid timestamp."
    }

    $artifacts = @($gate.artifacts)
    if ($artifacts.Count -lt 1) {
        Add-Issue "$GateId requires at least one hashed evidence artifact."
    }
    foreach ($artifact in $artifacts) {
        Require-Material -Value ([string]$artifact.path) -Label "$GateId artifact path"
        Require-Material -Value ([string]$artifact.kind) -Label "$GateId artifact kind"
        if ([string]$artifact.sha256 -notmatch '^[a-fA-F0-9]{64}$') {
            Add-Issue "$GateId artifact '$($artifact.path)' has an invalid SHA-256."
            continue
        }
        if ([System.IO.Path]::IsPathRooted([string]$artifact.path)) {
            Add-Issue "$GateId artifact path must be relative to the process root: $($artifact.path)"
            continue
        }
        $artifactPath = [System.IO.Path]::GetFullPath((Join-Path $ProcessRoot ([string]$artifact.path)))
        $rootPrefix = $ProcessRoot + [System.IO.Path]::DirectorySeparatorChar
        if (-not $artifactPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            Add-Issue "$GateId artifact escapes the process root: $($artifact.path)"
            continue
        }
        if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
            Add-Issue "$GateId artifact is missing: $($artifact.path)"
            continue
        }
        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash
        if (-not $actualHash.Equals([string]$artifact.sha256, [System.StringComparison]::OrdinalIgnoreCase)) {
            Add-Issue "$GateId artifact hash does not match: $($artifact.path)"
        }
    }

    $checksObject = $null
    if ($gate.PSObject.Properties.Name -contains 'checks') {
        $checksObject = $gate.checks
    }
    if ($GateId -eq 'G06') {
        Require-ExactTrueChecks -Checks $checksObject -RequiredNames @(
            'securityTestsPassed',
            'authorizationNegativeTestsPassed',
            'dependencyAndSecretScansPassed',
            'accessibilityScopePassed',
            'performanceBudgetsPassed',
            'cacheAndOfflineBehaviorPassed',
            'noUnresolvedCriticalHighFindings'
        )
    }
    if ($GateId -eq 'G07') {
        Require-ExactTrueChecks -Checks $checksObject -RequiredNames @(
            'ciRequiredChecksPassed',
            'sameArtifactPromotionConfigured',
            'signedBuildProvenanceConfigured',
            'sloAlertsValidated',
            'backupRestoreAndDrTested',
            'migrationAndRollbackTested',
            'runbooksAndOwnersApproved'
        )
    }
    if ($GateId -eq 'G10') {
        Require-ExactTrueChecks -Checks $checksObject -RequiredNames @(
            'postReleaseChecksScheduled',
            'sloAndErrorBudgetOwned',
            'bugsAndIncidentsTriaged',
            'vulnerabilitiesMonitored',
            'rumAndCostsReviewed',
            'roiAndProductMetricsReviewed',
            'doraAndImprovementCadenceOwned'
        )
    }

    if ($GateId -eq 'G08') {
        foreach ($shaField in @('baseSha', 'candidateSha')) {
            if ([string]$gate.candidate.$shaField -notmatch '^[a-fA-F0-9]{40}([a-fA-F0-9]{24})?$') {
                Add-Issue "G08 candidate $shaField is not a Git SHA."
            }
        }
        if ([string]$gate.candidate.artifactDigest -notmatch '^sha256:[a-fA-F0-9]{64}$') {
            Add-Issue 'G08 artifactDigest is not a SHA-256 digest.'
        }
        else {
            $candidateArtifactHash = ([string]$gate.candidate.artifactDigest).Substring(7)
            $matchingArtifact = @(
                $artifacts |
                    Where-Object {
                        [string]$_.kind -eq 'candidate-artifact' -and
                        [string]$_.sha256 -eq $candidateArtifactHash
                    }
            )
            if ($matchingArtifact.Count -ne 1) {
                Add-Issue 'G08 artifactDigest does not match exactly one hashed candidate-artifact.'
            }
        }
        $provenance = $gate.candidate.provenance
        $candidateAttestationDigest = ''
        if ($null -eq $provenance) {
            Add-Issue 'G08 candidate provenance is missing.'
        }
        else {
            $candidateAttestationDigest = [string]$provenance.attestationDigest
            if ([string]$provenance.attestationDigest -notmatch '^sha256:[a-fA-F0-9]{64}$') {
                Add-Issue 'G08 provenance attestationDigest is not a SHA-256 digest.'
            }
            else {
                $attestationHash = ([string]$provenance.attestationDigest).Substring(7)
                $matchingAttestation = @(
                    $artifacts |
                        Where-Object {
                            [string]$_.kind -eq 'build-provenance-attestation' -and
                            [string]$_.sha256 -eq $attestationHash
                        }
                )
                if ($matchingAttestation.Count -ne 1) {
                    Add-Issue 'G08 attestationDigest does not match exactly one hashed build-provenance-attestation.'
                }
            }
            foreach ($field in @('issuer', 'builderIdentity', 'sourceRepository', 'workflowRef', 'predicateType')) {
                Require-Material -Value ([string]$provenance.$field) -Label "G08 provenance $field"
            }
            if ([string]$provenance.sourceSha -ne [string]$gate.candidate.candidateSha) {
                Add-Issue 'G08 provenance sourceSha does not match candidateSha.'
            }
            if ($provenance.verificationPassed -isnot [bool] -or $provenance.verificationPassed -ne $true) {
                Add-Issue 'G08 provenance verification did not pass.'
            }
        }
        if ([string]$gate.candidate.baseSha -eq [string]$gate.candidate.candidateSha) {
            Add-Issue 'G08 baseSha and candidateSha must differ.'
        }
        if ($gate.acceptance.decision -ne 'GO') {
            Add-Issue 'G08 acceptance decision is not GO.'
        }
        if ($gate.independentReview.decision -ne 'GO' -or
            $gate.independentReview.readOnly -isnot [bool] -or
            $gate.independentReview.readOnly -ne $true) {
            Add-Issue 'G08 independent review must be GO and read-only.'
        }
        Require-Material -Value ([string]$gate.independentReview.taskId) -Label 'G08 independent task id'
        Require-Material -Value ([string]$gate.independentReview.implementerIdentity) -Label 'G08 implementer identity'
        Require-Material -Value ([string]$gate.independentReview.reviewerIdentity) -Label 'G08 reviewer identity'
        if ([string]$gate.independentReview.implementerIdentity -eq [string]$gate.independentReview.reviewerIdentity) {
            Add-Issue 'G08 implementer and reviewer identities must differ.'
        }
        if (($gate.independentReview.criticalFindings -isnot [int] -and
            $gate.independentReview.criticalFindings -isnot [long]) -or
            $gate.independentReview.criticalFindings -ne 0) {
            Add-Issue 'G08 independent review has critical findings.'
        }
        foreach ($candidateCopy in @($gate.acceptance, $gate.independentReview)) {
            if ([string]$candidateCopy.candidateSha -ne [string]$gate.candidate.candidateSha -or
                [string]$candidateCopy.artifactDigest -ne [string]$gate.candidate.artifactDigest -or
                [string]$candidateCopy.attestationDigest -ne $candidateAttestationDigest) {
                Add-Issue 'G08 acceptance/review identifiers do not match the immutable candidate and attestation.'
            }
        }
        if ([string]$gate.approvedBy.identity -ne [string]$gate.independentReview.reviewerIdentity) {
            Add-Issue 'G08 evidence approver is not the independent reviewer identity.'
        }
    }

    if ($GateId -eq 'G09') {
        $g08 = $evidence.gates.G08
        if ($g08.status -ne 'approved') {
            Add-Issue 'G09 requires approved G08 evidence.'
        }
        if ($gate.authorization.scope -ne 'AUTORIZAR_RELEASE') {
            Add-Issue 'G09 authorization scope must be AUTORIZAR_RELEASE.'
        }
        foreach ($field in @('environment', 'releaseWindow', 'authorizedByIdentity', 'authorizedAt')) {
            Require-Material -Value ([string]$gate.authorization.$field) -Label "G09 authorization $field"
        }
        $authorizedDate = Convert-ToTimestamp $gate.authorization.authorizedAt
        $authorizedDateIsValid = $null -ne $authorizedDate
        if (-not $authorizedDateIsValid) {
            Add-Issue 'G09 authorizedAt is not a valid timestamp.'
        }
        $releaseWindowParts = @(([string]$gate.authorization.releaseWindow) -split '/', 2)
        if ($releaseWindowParts.Count -ne 2) {
            Add-Issue 'G09 releaseWindow must be an ISO 8601 start/end interval.'
        }
        else {
            $releaseWindowStart = Convert-ToTimestamp $releaseWindowParts[0]
            $releaseWindowEnd = Convert-ToTimestamp $releaseWindowParts[1]
            $startIsValid = $null -ne $releaseWindowStart
            $endIsValid = $null -ne $releaseWindowEnd
            if (-not $startIsValid -or -not $endIsValid) {
                Add-Issue 'G09 releaseWindow contains an invalid timestamp.'
            }
            elseif ($releaseWindowStart -ge $releaseWindowEnd) {
                Add-Issue 'G09 releaseWindow start must be earlier than its end.'
            }
            elseif ($authorizedDateIsValid -and $authorizedDate -gt $releaseWindowStart) {
                Add-Issue 'G09 authorization must be recorded before or at the release window start.'
            }
        }
        if ([string]$gate.authorization.authorizedByIdentity -ne [string]$gate.approvedBy.identity) {
            Add-Issue 'G09 authorization identity does not match the evidence approver.'
        }
        if ([string]$gate.authorization.candidateSha -ne [string]$g08.candidate.candidateSha -or
            [string]$gate.authorization.artifactDigest -ne [string]$g08.candidate.artifactDigest -or
            [string]$gate.authorization.attestationDigest -ne [string]$g08.candidate.provenance.attestationDigest) {
            Add-Issue 'G09 authorization does not target the G08 candidate.'
        }
        if ($Phase -eq 'release_completed') {
            if ($gate.deployment.status -ne 'passed' -or
                $gate.deployment.smokeTestsPassed -isnot [bool] -or
                $gate.deployment.smokeTestsPassed -ne $true -or
                $gate.deployment.attestationVerified -isnot [bool] -or
                $gate.deployment.attestationVerified -ne $true -or
                $gate.deployment.rollbackReady -isnot [bool] -or
                $gate.deployment.rollbackReady -ne $true) {
                Add-Issue 'G09 deployment, smoke tests and rollback readiness must pass.'
            }
            Require-Material -Value ([string]$gate.deployment.abortCriteria) -Label 'G09 abort criteria'
            if ([string]$gate.deployment.environment -ne [string]$gate.authorization.environment -or
                [string]$gate.deployment.candidateSha -ne [string]$gate.authorization.candidateSha -or
                [string]$gate.deployment.artifactDigest -ne [string]$gate.authorization.artifactDigest -or
                [string]$gate.deployment.attestationDigest -ne [string]$gate.authorization.attestationDigest) {
                Add-Issue 'G09 deployed target does not match the authorized environment/candidate.'
            }
        }
    }
}

if ($issues.Count -gt 0) {
    Write-Host "FAIL: $GateId structured evidence found $($issues.Count) issue(s)." -ForegroundColor Red
    $issues | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "PASS: $GateId structured evidence is valid for phase $Phase." -ForegroundColor Green
Write-Host " - Evidence: $EvidencePath"
Write-Host " - Approver: $($gate.approvedBy.name) <$($gate.approvedBy.identity)>"
Write-Host " - Hashed artifacts: $(@($gate.artifacts).Count)"
exit 0
