[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Worktree,
    [Parameter(Mandatory)][string]$ArtifactPath,
    [Parameter(Mandatory)][string]$OutputPath,
    [Parameter(Mandatory)][string]$RepositoryIdentity,
    [Parameter(Mandatory)][string]$WorkflowIdentity,
    [Parameter(Mandatory)][string]$Issuer,
    [Parameter(Mandatory)][string]$Builder,
    [Parameter(Mandatory)][string]$PrivateKeyPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Resolve-ChildPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Parent,
        [switch]$MayNotExist
    )

    $resolvedParent = [System.IO.Path]::GetFullPath($Parent).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $prefix = $resolvedParent + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path must be inside the disposable worktree: $resolvedPath"
    }
    if (-not $MayNotExist -and -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        throw "Required file does not exist: $resolvedPath"
    }
    return $resolvedPath
}

$Worktree = [System.IO.Path]::GetFullPath($Worktree)
if (-not (Test-Path -LiteralPath (Join-Path $Worktree '.git'))) {
    throw "Worktree is not a Git repository: $Worktree"
}
$ArtifactPath = Resolve-ChildPath -Path $ArtifactPath -Parent $Worktree
$OutputPath = Resolve-ChildPath -Path $OutputPath -Parent $Worktree -MayNotExist
$PrivateKeyPath = [System.IO.Path]::GetFullPath($PrivateKeyPath)
$worktreePrefix = $Worktree.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
if ($PrivateKeyPath.StartsWith($worktreePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'The signing private key must remain outside the candidate worktree.'
}
if (-not (Test-Path -LiteralPath $PrivateKeyPath -PathType Leaf)) {
    throw "Signing private key does not exist: $PrivateKeyPath"
}
$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}
if (Test-Path -LiteralPath $OutputPath) {
    throw "Refusing to replace an existing attestation: $OutputPath"
}

$candidateSha = [string]@(& git -C $Worktree rev-parse HEAD)[0]
if ($LASTEXITCODE -ne 0 -or $candidateSha -notmatch '^[0-9a-f]{40,64}$') {
    throw 'Could not resolve the immutable candidate SHA.'
}
$artifactRelativePath = [System.IO.Path]::GetRelativePath($Worktree, $ArtifactPath).Replace('\', '/')
$artifactSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $ArtifactPath).Hash.ToLowerInvariant()

$payload = [ordered]@{
    schemaVersion = 1
    repository = $RepositoryIdentity
    workflow = $WorkflowIdentity
    candidateSha = $candidateSha
    artifactPath = $artifactRelativePath
    artifactSha256 = $artifactSha256
    issuer = $Issuer
    builder = $Builder
}
$payloadJson = $payload | ConvertTo-Json -Compress
$payloadBytes = $utf8NoBom.GetBytes($payloadJson)

$rsa = [System.Security.Cryptography.RSA]::Create()
try {
    $rsa.ImportFromPem((Get-Content -Raw -Encoding UTF8 -LiteralPath $PrivateKeyPath))
    $signature = $rsa.SignData(
        $payloadBytes,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pss)
    $publicKeyPem = $rsa.ExportSubjectPublicKeyInfoPem()
}
finally {
    $rsa.Dispose()
}

$publicKeySha256 = [Convert]::ToHexString(
    [System.Security.Cryptography.SHA256]::HashData($utf8NoBom.GetBytes($publicKeyPem))
).ToLowerInvariant()
$envelope = [ordered]@{
    schemaVersion = 1
    payload = $payload
    payloadJson = $payloadJson
    algorithm = 'RSA-PSS-SHA256'
    publicKeyPem = $publicKeyPem
    publicKeySha256 = $publicKeySha256
    signatureBase64 = [Convert]::ToBase64String($signature)
}
[System.IO.File]::WriteAllText(
    $OutputPath,
    (($envelope | ConvertTo-Json -Depth 8) + "`n"),
    $utf8NoBom)

$relativeOutput = [System.IO.Path]::GetRelativePath($Worktree, $OutputPath).Replace('\', '/')
$ignored = @(& git -C $Worktree check-ignore --quiet -- $relativeOutput; $LASTEXITCODE) | Select-Object -Last 1
if ($ignored -ne 0) {
    Remove-Item -LiteralPath $OutputPath -Force
    throw "Attestation output must be Git-ignored so the candidate remains immutable: $relativeOutput"
}

[pscustomobject]@{
    candidateSha = $candidateSha
    artifactPath = $artifactRelativePath
    artifactSha256 = $artifactSha256
    attestationPath = $relativeOutput
    attestationSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutputPath).Hash.ToLowerInvariant()
    publicKeySha256 = $publicKeySha256
    issuer = $Issuer
    builder = $Builder
    repository = $RepositoryIdentity
    workflow = $WorkflowIdentity
} | ConvertTo-Json -Depth 4
