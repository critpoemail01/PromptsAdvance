[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Worktree,
    [Parameter(Mandatory)][string]$ArtifactPath,
    [Parameter(Mandatory)][string]$AttestationPath,
    [Parameter(Mandatory)][string]$ExpectedRepository,
    [Parameter(Mandatory)][string]$ExpectedWorkflow,
    [Parameter(Mandatory)][string]$ExpectedCandidateSha,
    [Parameter(Mandatory)][string]$ExpectedArtifactSha256,
    [Parameter(Mandatory)][string]$ExpectedIssuer,
    [Parameter(Mandatory)][string]$ExpectedBuilder,
    [Parameter(Mandatory)][string]$ExpectedPublicKeySha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Fail {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
    exit 1
}

function Resolve-ChildFile {
    param([Parameter(Mandatory)][string]$Path)
    $parent = [System.IO.Path]::GetFullPath($Worktree).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $candidate = [System.IO.Path]::GetFullPath($Path)
    $prefix = $parent + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Fail "Evidence path is outside the worktree: $candidate"
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        Fail "Evidence file is missing: $candidate"
    }
    return $candidate
}

$Worktree = [System.IO.Path]::GetFullPath($Worktree)
$ArtifactPath = Resolve-ChildFile -Path $ArtifactPath
$AttestationPath = Resolve-ChildFile -Path $AttestationPath
$headSha = [string]@(& git -C $Worktree rev-parse HEAD)[0]
if ($LASTEXITCODE -ne 0 -or $headSha -ne $ExpectedCandidateSha) {
    Fail "HEAD '$headSha' does not match candidate '$ExpectedCandidateSha'."
}
$actualArtifactSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $ArtifactPath).Hash.ToLowerInvariant()
if ($actualArtifactSha256 -ne $ExpectedArtifactSha256.ToLowerInvariant()) {
    Fail 'The candidate artifact digest does not match.'
}

try {
    $envelope = Get-Content -Raw -Encoding UTF8 -LiteralPath $AttestationPath | ConvertFrom-Json
    $payload = $envelope.payload
    $payloadJson = [string]$envelope.payloadJson
    $publicKeyPem = [string]$envelope.publicKeyPem
    $signature = [Convert]::FromBase64String([string]$envelope.signatureBase64)
}
catch {
    Fail "The attestation envelope is invalid: $($_.Exception.Message)"
}
if ($envelope.schemaVersion -ne 1 -or $payload.schemaVersion -ne 1 -or
    $envelope.algorithm -ne 'RSA-PSS-SHA256') {
    Fail 'The attestation schema or signature algorithm is unsupported.'
}
$canonicalPayload = $payload | ConvertTo-Json -Compress
if ($payloadJson -cne $canonicalPayload) {
    Fail 'The signed payload differs from the structured payload.'
}
$actualPublicKeySha256 = [Convert]::ToHexString(
    [System.Security.Cryptography.SHA256]::HashData($utf8NoBom.GetBytes($publicKeyPem))
).ToLowerInvariant()
if ($actualPublicKeySha256 -ne $ExpectedPublicKeySha256.ToLowerInvariant() -or
    [string]$envelope.publicKeySha256 -ne $actualPublicKeySha256) {
    Fail 'The attestation public key is not trusted.'
}

$expectedArtifactPath = [System.IO.Path]::GetRelativePath($Worktree, $ArtifactPath).Replace('\', '/')
$expectedValues = [ordered]@{
    repository = $ExpectedRepository
    workflow = $ExpectedWorkflow
    candidateSha = $ExpectedCandidateSha
    artifactPath = $expectedArtifactPath
    artifactSha256 = $ExpectedArtifactSha256.ToLowerInvariant()
    issuer = $ExpectedIssuer
    builder = $ExpectedBuilder
}
foreach ($entry in $expectedValues.GetEnumerator()) {
    if ([string]$payload.($entry.Key) -cne [string]$entry.Value) {
        Fail "Attestation $($entry.Key) does not match the frozen review input."
    }
}

$rsa = [System.Security.Cryptography.RSA]::Create()
try {
    $rsa.ImportFromPem($publicKeyPem)
    $validSignature = $rsa.VerifyData(
        $utf8NoBom.GetBytes($payloadJson),
        $signature,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pss)
}
catch {
    Fail "The attestation signature could not be verified: $($_.Exception.Message)"
}
finally {
    $rsa.Dispose()
}
if (-not $validSignature) {
    Fail 'The attestation signature is invalid.'
}

Write-Host 'PASS: signed pilot attestation matches candidate and artifact.' -ForegroundColor Green
Write-Host " - Candidate: $ExpectedCandidateSha"
Write-Host " - Artifact SHA-256: $actualArtifactSha256"
Write-Host " - Issuer/builder: $ExpectedIssuer / $ExpectedBuilder"
