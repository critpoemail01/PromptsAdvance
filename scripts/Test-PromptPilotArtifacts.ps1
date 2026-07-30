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
$shaPattern = '^[0-9a-f]{40}$'

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
        $allowedPrompt01Paths = @('PRODUCT_DEFINITION.md', 'IMPLEMENTATION_STATUS.md')
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
        if ($meta.afterClean -or $changedPrompt01Paths.Count -eq 0) {
            $failures.Add('EVAL-01-R2: expected durable prompt 01 evidence was not written')
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

$expectedReleaseChain = @(
    @('EVAL-13-REVIEW-1', '5bd59f8c56b72d34613e5a5923a0091a25751229', '5bd59f8c56b72d34613e5a5923a0091a25751229', 'NO-GO'),
    @('EVAL-13-IMPLEMENT', '5bd59f8c56b72d34613e5a5923a0091a25751229', '248a7fa3dc3c1284f113e0d954be7624018b7725', $null),
    @('EVAL-13-REVIEW-2', '248a7fa3dc3c1284f113e0d954be7624018b7725', '248a7fa3dc3c1284f113e0d954be7624018b7725', 'NO-GO'),
    @('EVAL-13-IMPLEMENT-2', '248a7fa3dc3c1284f113e0d954be7624018b7725', '133d9455752f4a25823f526372683a81bee9863d', $null),
    @('EVAL-13-REVIEW-3', '133d9455752f4a25823f526372683a81bee9863d', '133d9455752f4a25823f526372683a81bee9863d', 'NO-GO'),
    @('EVAL-13-IMPLEMENT-3', '133d9455752f4a25823f526372683a81bee9863d', '80903df4ff43aacec9db5609f585a93d93b4dfd8', $null),
    @('EVAL-13-REVIEW-4', '80903df4ff43aacec9db5609f585a93d93b4dfd8', '80903df4ff43aacec9db5609f585a93d93b4dfd8', 'GO')
)

foreach ($entry in $expectedReleaseChain) {
    $caseId, $expectedBefore, $expectedAfter, $expectedDecision = $entry
    if (-not $metadataByCase.ContainsKey($caseId)) {
        continue
    }

    $meta = $metadataByCase[$caseId]
    if ($meta.beforeSha -ne $expectedBefore -or $meta.afterSha -ne $expectedAfter) {
        $failures.Add("${caseId}: release SHA chain does not match the frozen manifest")
    }

    if ($null -ne $expectedDecision) {
        $finalPath = Join-Path (Join-Path $ArtifactRoot $caseId) 'final.md'
        $finalText = Get-Content -Raw -Encoding UTF8 -LiteralPath $finalPath
        if (-not $finalText.Contains($expectedDecision)) {
            $failures.Add("${caseId}: expected decision $expectedDecision is missing")
        }
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
