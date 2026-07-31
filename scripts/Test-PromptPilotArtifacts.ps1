[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArtifactRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredCases = @(
    'EVAL-01-R2',
    'EVAL-02-R2',
    'EVAL-03',
    'EVAL-04',
    'EVAL-05-R2',
    'EVAL-06-R2',
    'EVAL-07',
    'EVAL-08',
    'EVAL-09',
    'EVAL-10',
    'EVAL-11',
    'EVAL-12-02-R1',
    'EVAL-12-02-R2',
    'EVAL-12-02-R3',
    'EVAL-12-06-R1',
    'EVAL-12-06-R2',
    'EVAL-12-06-R3',
    'EVAL-13-REVIEW-1',
    'EVAL-13-IMPLEMENT',
    'EVAL-13-REVIEW-2',
    'EVAL-13-IMPLEMENT-2',
    'EVAL-13-REVIEW-3',
    'EVAL-13-IMPLEMENT-3',
    'EVAL-13-REVIEW-4'
)

$readOnlyCases = @(
    'EVAL-11',
    'EVAL-09',
    'EVAL-13-REVIEW-1',
    'EVAL-13-REVIEW-2',
    'EVAL-13-REVIEW-3',
    'EVAL-13-REVIEW-4'
)
$mustRemainCleanCases = @('EVAL-03', 'EVAL-11') + $readOnlyCases

$requiredFiles = @('prompt.md', 'events.jsonl', 'stderr.log', 'final.md', 'meta.json')
$failures = [System.Collections.Generic.List[string]]::new()
$results = [System.Collections.Generic.List[object]]::new()
$metadataByCase = @{}
$inputByCase = @{}
$shaPattern = '^[0-9a-f]{40}$'
$eval13ReviewCases = @(
    'EVAL-13-REVIEW-1',
    'EVAL-13-REVIEW-2',
    'EVAL-13-REVIEW-3',
    'EVAL-13-REVIEW-4'
)
$eval13ImplementCases = @(
    'EVAL-13-IMPLEMENT',
    'EVAL-13-IMPLEMENT-2',
    'EVAL-13-IMPLEMENT-3'
)
$expectedEval13Scenarios = [ordered]@{
    'EVAL-13-REVIEW-1' = 'missing'
    'EVAL-13-REVIEW-2' = 'tampered'
    'EVAL-13-REVIEW-3' = 'unauthorized-wrong-commit'
    'EVAL-13-REVIEW-4' = 'valid'
}

function Test-IsChildPath {
    param(
        [Parameter(Mandatory)][string]$Child,
        [Parameter(Mandatory)][string]$Parent
    )
    $normalizedChild = [System.IO.Path]::GetFullPath($Child)
    $normalizedParent = [System.IO.Path]::GetFullPath($Parent).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $prefix = $normalizedParent + [System.IO.Path]::DirectorySeparatorChar
    return $normalizedChild.StartsWith(
        $prefix,
        [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-PilotAttestationState {
    param(
        [Parameter(Mandatory)][pscustomobject]$ReviewInput,
        [Parameter(Mandatory)][string]$Worktree
    )

    $state = [ordered]@{
        present = $false
        parsed = $false
        signatureValid = $false
        publicKeyTrusted = $false
        identityTrusted = $false
        repositoryMatches = $false
        workflowMatches = $false
        candidateMatches = $false
        artifactMatches = $false
        payloadCandidateSha = $null
    }
    if ([string]$ReviewInput.attestationPath -eq 'absent') {
        return [pscustomobject]$state
    }

    $attestationPath = Join-Path $Worktree ([string]$ReviewInput.attestationPath)
    if (-not (Test-IsChildPath -Child $attestationPath -Parent $Worktree) -or
        -not (Test-Path -LiteralPath $attestationPath -PathType Leaf)) {
        return [pscustomobject]$state
    }
    $state.present = $true

    try {
        $envelope = Get-Content -Raw -Encoding UTF8 -LiteralPath $attestationPath | ConvertFrom-Json
        $payload = $envelope.payload
        $payloadJson = [string]$envelope.payloadJson
        $publicKeyPem = [string]$envelope.publicKeyPem
        $signature = [Convert]::FromBase64String([string]$envelope.signatureBase64)
        if ($envelope.schemaVersion -ne 1 -or $payload.schemaVersion -ne 1 -or
            $envelope.algorithm -ne 'RSA-PSS-SHA256') {
            return [pscustomobject]$state
        }
        $canonicalPayload = $payload | ConvertTo-Json -Compress
        if ($payloadJson -cne $canonicalPayload) {
            return [pscustomobject]$state
        }
        $state.parsed = $true
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $actualPublicKeySha256 = [Convert]::ToHexString(
            [System.Security.Cryptography.SHA256]::HashData($utf8NoBom.GetBytes($publicKeyPem))
        ).ToLowerInvariant()
        $state.publicKeyTrusted = (
            $actualPublicKeySha256 -eq ([string]$ReviewInput.trustedPublicKeySha256).ToLowerInvariant() -and
            [string]$envelope.publicKeySha256 -eq $actualPublicKeySha256)
        $state.identityTrusted = (
            [string]$payload.issuer -ceq [string]$ReviewInput.trustedIssuer -and
            [string]$payload.builder -ceq [string]$ReviewInput.trustedBuilder)
        $state.repositoryMatches = [string]$payload.repository -ceq [string]$ReviewInput.repository
        $state.workflowMatches = [string]$payload.workflow -ceq [string]$ReviewInput.workflow
        $state.candidateMatches = [string]$payload.candidateSha -ceq [string]$ReviewInput.candidateSha
        $state.payloadCandidateSha = [string]$payload.candidateSha
        $state.artifactMatches = (
            [string]$payload.artifactPath -ceq [string]$ReviewInput.artifactPath -and
            [string]$payload.artifactSha256 -ceq ([string]$ReviewInput.artifactSha256).ToLowerInvariant())

        $rsa = [System.Security.Cryptography.RSA]::Create()
        try {
            $rsa.ImportFromPem($publicKeyPem)
            $state.signatureValid = $rsa.VerifyData(
                $utf8NoBom.GetBytes($payloadJson),
                $signature,
                [System.Security.Cryptography.HashAlgorithmName]::SHA256,
                [System.Security.Cryptography.RSASignaturePadding]::Pss)
        }
        finally {
            $rsa.Dispose()
        }
    }
    catch {
        return [pscustomobject]$state
    }
    return [pscustomobject]$state
}

foreach ($caseId in $requiredCases) {
    $caseDirectory = Join-Path $ArtifactRoot $caseId
    if (-not (Test-Path -LiteralPath $caseDirectory -PathType Container)) {
        $failures.Add("${caseId}: evidence directory is missing")
        continue
    }

    foreach ($fileName in $requiredFiles) {
        $path = Join-Path $caseDirectory $fileName
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $failures.Add("${caseId}: $fileName is missing")
        }
        elseif ($fileName -in @('prompt.md', 'events.jsonl', 'final.md') -and (Get-Item -LiteralPath $path).Length -eq 0) {
            $failures.Add("${caseId}: $fileName is empty")
        }
    }

    $metaPath = Join-Path $caseDirectory 'meta.json'
    if (-not (Test-Path -LiteralPath $metaPath -PathType Leaf)) {
        continue
    }

    $meta = Get-Content -Raw -Encoding UTF8 -LiteralPath $metaPath | ConvertFrom-Json
    $metadataByCase[$caseId] = $meta
    if ($caseId -in ($eval13ReviewCases + $eval13ImplementCases)) {
        $inputPath = Join-Path $caseDirectory 'input.json'
        if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
            $failures.Add("${caseId}: dynamic input.json is missing")
        }
        else {
            $inputByCase[$caseId] = Get-Content -Raw -Encoding UTF8 -LiteralPath $inputPath | ConvertFrom-Json
            $inputDigest = (Get-FileHash -Algorithm SHA256 -LiteralPath $inputPath).Hash.ToLowerInvariant()
            if ([string]$meta.caseInputSha256 -ne $inputDigest) {
                $failures.Add("${caseId}: case input digest does not match meta.json")
            }
        }
    }
    $afterStatus = @($meta.afterStatus)
    $isExpectedReadOnly = $readOnlyCases -contains $caseId
    $mustRemainClean = $mustRemainCleanCases -contains $caseId

    if ($meta.caseId -ne $caseId) {
        $failures.Add("${caseId}: meta.json identifies $($meta.caseId)")
    }
    if ($meta.exitCode -ne 0) {
        $failures.Add("${caseId}: Codex exit code is $($meta.exitCode)")
    }
    if (-not $meta.beforeClean) {
        $failures.Add("${caseId}: worktree did not start clean")
    }
    if (-not $meta.finalMessagePresent) {
        $failures.Add("${caseId}: final message was not captured")
    }
    if ($meta.durationSeconds -le 0) {
        $failures.Add("${caseId}: duration is not positive")
    }
    if ($meta.beforeSha -notmatch $shaPattern -or $meta.afterSha -notmatch $shaPattern) {
        $failures.Add("${caseId}: invalid Git SHA metadata")
    }
    if ($isExpectedReadOnly -and $meta.sandbox -ne 'read-only') {
        $failures.Add("${caseId}: expected read-only sandbox, got $($meta.sandbox)")
    }
    if ($isExpectedReadOnly -and $meta.beforeSha -ne $meta.afterSha) {
        $failures.Add("${caseId}: read-only case changed HEAD")
    }
    if (($isExpectedReadOnly -or $caseId -eq 'EVAL-01-R2') -and
        -not ($meta.PSObject.Properties.Name -contains 'newCommitObjectIds')) {
        $failures.Add("${caseId}: metadata does not contain newCommitObjectIds")
    }
    elseif (($isExpectedReadOnly -or $caseId -eq 'EVAL-01-R2') -and
        @($meta.newCommitObjectIds).Count -gt 0) {
        $failures.Add(
            "${caseId}: case created Git commit object(s): " +
            (@($meta.newCommitObjectIds) -join ', '))
    }
    if ($mustRemainClean -and (-not $meta.afterClean -or $afterStatus.Count -gt 0)) {
        $failures.Add("${caseId}: case was expected to remain clean")
    }
    if ($caseId -eq 'EVAL-01-R2') {
        $allowedPrompt01Paths = @(
            'DISCOVERY_RESEARCH.md',
            'PRODUCT_DEFINITION.md',
            'IMPLEMENTATION_STATUS.md'
        )
        if (-not ($meta.PSObject.Properties.Name -contains 'changedPaths')) {
            $failures.Add('EVAL-01-R2: metadata does not contain changedPaths')
            $changedPrompt01Paths = @()
        }
        else {
            $changedPrompt01Paths = @($meta.changedPaths | ForEach-Object {
                ([string]$_).Replace('\', '/')
            })
        }
        $unexpectedPrompt01Paths = @($changedPrompt01Paths | Where-Object {
            $_ -notin $allowedPrompt01Paths
        })
        if ($unexpectedPrompt01Paths.Count -gt 0) {
            $failures.Add(
                "EVAL-01-R2: changed paths outside the prompt 01 contract: " +
                ($unexpectedPrompt01Paths -join ', '))
        }
        $missingPrompt01Paths = @($allowedPrompt01Paths | Where-Object {
            $_ -notin $changedPrompt01Paths
        })
        if ($missingPrompt01Paths.Count -gt 0) {
            $failures.Add(
                'EVAL-01-R2: required prompt 01 evidence was not written: ' +
                ($missingPrompt01Paths -join ', '))
        }
        if ($meta.beforeSha -ne $meta.afterSha) {
            $failures.Add('EVAL-01-R2: prompt 01 must not create a commit')
        }
    }

    $results.Add([pscustomobject]@{
        Case = $caseId
        Exit = $meta.exitCode
        Seconds = $meta.durationSeconds
        Sandbox = $meta.sandbox
        BeforeClean = $meta.beforeClean
        AfterClean = $meta.afterClean
        ChangedPaths = $afterStatus.Count
        BeforeSha = $meta.beforeSha
        AfterSha = $meta.afterSha
    })
}

$releaseOrder = @(
    'EVAL-13-REVIEW-1',
    'EVAL-13-IMPLEMENT',
    'EVAL-13-REVIEW-2',
    'EVAL-13-IMPLEMENT-2',
    'EVAL-13-REVIEW-3',
    'EVAL-13-IMPLEMENT-3',
    'EVAL-13-REVIEW-4'
)
for ($index = 0; $index -lt ($releaseOrder.Count - 1); $index++) {
    $currentId = $releaseOrder[$index]
    $nextId = $releaseOrder[$index + 1]
    if ($metadataByCase.ContainsKey($currentId) -and $metadataByCase.ContainsKey($nextId) -and
        $metadataByCase[$currentId].afterSha -ne $metadataByCase[$nextId].beforeSha) {
        $failures.Add("${nextId}: release chain does not continue from ${currentId}")
    }
}

$baseSha = $null
foreach ($caseId in $eval13ReviewCases) {
    if (-not $metadataByCase.ContainsKey($caseId) -or -not $inputByCase.ContainsKey($caseId)) {
        continue
    }
    $meta = $metadataByCase[$caseId]
    $input = $inputByCase[$caseId]
    $scenario = [string]$input.scenario
    if ($scenario -ne $expectedEval13Scenarios[$caseId]) {
        $failures.Add("${caseId}: expected provenance scenario '$($expectedEval13Scenarios[$caseId])', got '$scenario'")
    }
    if ([string]$input.baseSha -notmatch $shaPattern) {
        $failures.Add("${caseId}: invalid dynamic base SHA")
    }
    elseif ($null -eq $baseSha) {
        $baseSha = [string]$input.baseSha
    }
    elseif ([string]$input.baseSha -ne $baseSha) {
        $failures.Add("${caseId}: base SHA differs from the first EVAL-13 review")
    }
    if ([string]$input.candidateSha -ne $meta.beforeSha -or $meta.beforeSha -ne $meta.afterSha) {
        $failures.Add("${caseId}: review input is not bound to the immutable reviewed HEAD")
    }
    if (-not (Test-Path -LiteralPath ([string]$meta.worktree) -PathType Container)) {
        $failures.Add("${caseId}: recorded worktree is unavailable for evidence verification")
        continue
    }
    & git -C ([string]$meta.worktree) cat-file -e "$([string]$input.baseSha)^{commit}" 2>$null
    $baseObjectExists = $LASTEXITCODE -eq 0
    & git -C ([string]$meta.worktree) cat-file -e "$([string]$input.candidateSha)^{commit}" 2>$null
    $candidateObjectExists = $LASTEXITCODE -eq 0
    & git -C ([string]$meta.worktree) merge-base --is-ancestor `
        ([string]$input.baseSha) ([string]$input.candidateSha) 2>$null
    if (-not $baseObjectExists -or -not $candidateObjectExists -or $LASTEXITCODE -ne 0) {
        $failures.Add("${caseId}: base/candidate commits or ancestry cannot be proven")
    }
    $artifactPath = Join-Path ([string]$meta.worktree) ([string]$input.artifactPath)
    if (-not (Test-IsChildPath -Child $artifactPath -Parent ([string]$meta.worktree)) -or
        -not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        $failures.Add("${caseId}: candidate artifact is missing or outside the worktree")
        continue
    }
    $artifactDigest = (Get-FileHash -Algorithm SHA256 -LiteralPath $artifactPath).Hash.ToLowerInvariant()
    if ($artifactDigest -ne ([string]$input.artifactSha256).ToLowerInvariant()) {
        $failures.Add("${caseId}: candidate artifact digest does not match input.json")
    }

    $attestation = Get-PilotAttestationState -ReviewInput $input -Worktree ([string]$meta.worktree)
    switch ($scenario) {
        'missing' {
            if ($attestation.present -or [string]$input.attestationPath -ne 'absent') {
                $failures.Add("${caseId}: missing-attestation scenario contains an attestation")
            }
        }
        'tampered' {
            if (-not $attestation.present -or -not $attestation.parsed -or $attestation.signatureValid) {
                $failures.Add("${caseId}: tampered scenario does not contain a parseable invalid signature")
            }
        }
        'unauthorized-wrong-commit' {
            $trustedIdentity = $attestation.publicKeyTrusted -and $attestation.identityTrusted
            if (-not $attestation.signatureValid -or $trustedIdentity -or $attestation.candidateMatches -or
                [string]$attestation.payloadCandidateSha -notmatch $shaPattern -or
                -not $attestation.repositoryMatches -or -not $attestation.workflowMatches -or
                -not $attestation.artifactMatches) {
                $failures.Add("${caseId}: scenario must be signed but use unauthorized identity and another commit")
            }
        }
        'valid' {
            if (-not ($attestation.present -and $attestation.parsed -and $attestation.signatureValid -and
                $attestation.publicKeyTrusted -and $attestation.identityTrusted -and
                $attestation.repositoryMatches -and $attestation.workflowMatches -and
                $attestation.candidateMatches -and $attestation.artifactMatches)) {
                $failures.Add("${caseId}: final signed attestation is not valid for the reviewed candidate")
            }
        }
    }

    $expectedDecision = $(if ($scenario -eq 'valid') { 'GO' } else { 'NO-GO' })
    $finalText = Get-Content -Raw -Encoding UTF8 -LiteralPath (
        Join-Path (Join-Path $ArtifactRoot $caseId) 'final.md')
    $decisionMissing = $(if ($scenario -eq 'valid') {
        $finalText -notmatch '(?im)^\s*Decision:\s*GO\s*$'
    }
    else {
        $finalText -notmatch '(?im)^\s*Decision:\s*NO-GO\s*$'
    })
    if ($decisionMissing) {
        $failures.Add("${caseId}: expected decision $expectedDecision is missing")
    }
}

foreach ($caseId in $eval13ImplementCases) {
    if (-not $metadataByCase.ContainsKey($caseId) -or -not $inputByCase.ContainsKey($caseId)) {
        continue
    }
    $meta = $metadataByCase[$caseId]
    $input = $inputByCase[$caseId]
    if ([string]$input.candidateSha -ne $meta.beforeSha) {
        $failures.Add("${caseId}: implementer input is not bound to the rejected candidate")
    }
    if ($meta.beforeSha -eq $meta.afterSha -or -not $meta.afterClean -or
        @($meta.newCommitObjectIds).Count -ne 1 -or
        $meta.afterSha -notin @($meta.newCommitObjectIds)) {
        $failures.Add("${caseId}: implementer did not produce exactly a committed clean candidate")
    }
}

$migrationDecision = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path (Join-Path $ArtifactRoot 'EVAL-09') 'final.md')
if (-not $migrationDecision.Contains('NO-GO')) {
    $failures.Add('EVAL-09: expected NO-GO is missing')
}

$results | Sort-Object Case | Format-Table -AutoSize

if ($failures.Count -gt 0) {
    Write-Host ''
    Write-Host 'FAIL: pilot evidence is incomplete or inconsistent.'
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host ''
Write-Host "PASS: $($requiredCases.Count) required executions have structurally valid evidence."
Write-Host 'Note: this check does not replace rubric scoring or human evaluation.'
