[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CodexPath,
    [Parameter(Mandatory)][string]$Model,
    [Parameter(Mandatory)][string]$Worktree,
    [Parameter(Mandatory)][string]$CaseId,
    [Parameter(Mandatory)][string]$PromptFile,
    [Parameter(Mandatory)][string]$ArtifactRoot,
    [ValidateSet('read-only', 'workspace-write', 'danger-full-access')][string]$Sandbox = 'workspace-write',
    [switch]$AllowDangerFullAccess,
    [string]$IsolationRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

foreach ($path in @($CodexPath, $Worktree, $PromptFile)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required path does not exist: $path"
    }
}

$resolvedWorktree = [System.IO.Path]::GetFullPath($Worktree).TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar)

if ($Sandbox -eq 'danger-full-access') {
    if (-not $AllowDangerFullAccess) {
        throw 'danger-full-access requires the explicit -AllowDangerFullAccess switch.'
    }
    if ([string]::IsNullOrWhiteSpace($IsolationRoot) -or -not (Test-Path -LiteralPath $IsolationRoot -PathType Container)) {
        throw 'danger-full-access requires an existing -IsolationRoot.'
    }

    $resolvedIsolationRoot = [System.IO.Path]::GetFullPath($IsolationRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $requiredPrefix = $resolvedIsolationRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedWorktree.StartsWith($requiredPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Worktree must be a child of IsolationRoot for danger-full-access: $resolvedIsolationRoot"
    }
}
else {
    $resolvedIsolationRoot = $null
}

$beforeSha = (& git -C $resolvedWorktree rev-parse HEAD).Trim()
$beforeStatus = @(& git -C $resolvedWorktree status --porcelain)
if ($beforeStatus.Count -gt 0) {
    throw "Worktree must be clean before execution: $($beforeStatus -join '; ')"
}

$caseDirectory = Join-Path ([System.IO.Path]::GetFullPath($ArtifactRoot)) $CaseId
if (Test-Path -LiteralPath $caseDirectory) {
    throw "Artifact directory already exists: $caseDirectory"
}

New-Item -ItemType Directory -Path $caseDirectory | Out-Null

$eventsPath = Join-Path $caseDirectory 'events.jsonl'
$stderrPath = Join-Path $caseDirectory 'stderr.log'
$finalPath = Join-Path $caseDirectory 'final.md'
$metaPath = Join-Path $caseDirectory 'meta.json'
$promptCopyPath = Join-Path $caseDirectory 'prompt.md'

Copy-Item -LiteralPath $PromptFile -Destination $promptCopyPath

$startedAt = [DateTimeOffset]::Now
$arguments = @(
    'exec',
    '--ephemeral',
    '--ignore-user-config',
    '--model', $Model,
    '--json',
    '--color', 'never',
    '--sandbox', $Sandbox,
    '-C', $resolvedWorktree,
    '--output-last-message', $finalPath,
    '-'
)

$prompt = Get-Content -Raw -Encoding UTF8 -LiteralPath $PromptFile
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$prompt | & $CodexPath @arguments 2> $stderrPath | Set-Content -Encoding UTF8 -LiteralPath $eventsPath
$exitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
$finishedAt = [DateTimeOffset]::Now

$afterSha = (& git -C $resolvedWorktree rev-parse HEAD).Trim()
$afterStatus = @(& git -C $resolvedWorktree status --porcelain)
$diffStat = @(& git -C $resolvedWorktree diff --stat)
$diffNameStatus = @(& git -C $resolvedWorktree diff --name-status)

$metadata = [ordered]@{
    caseId = $CaseId
    startedAt = $startedAt.ToString('o')
    finishedAt = $finishedAt.ToString('o')
    durationSeconds = [Math]::Round(($finishedAt - $startedAt).TotalSeconds, 3)
    codexPath = [System.IO.Path]::GetFullPath($CodexPath)
    codexVersion = (& $CodexPath --version | Out-String).Trim()
    model = $Model
    sandbox = $Sandbox
    dangerFullAccessExplicitlyAllowed = [bool]$AllowDangerFullAccess
    isolationRoot = $resolvedIsolationRoot
    worktree = $resolvedWorktree
    promptFile = [System.IO.Path]::GetFullPath($PromptFile)
    exitCode = $exitCode
    beforeSha = $beforeSha
    afterSha = $afterSha
    beforeClean = $true
    afterClean = $afterStatus.Count -eq 0
    afterStatus = $afterStatus
    diffStat = $diffStat
    diffNameStatus = $diffNameStatus
    finalMessagePresent = Test-Path -LiteralPath $finalPath
}

$metadata | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 -LiteralPath $metaPath
exit $exitCode
