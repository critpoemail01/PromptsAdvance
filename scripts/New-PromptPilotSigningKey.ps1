[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $OutputDirectory) {
    throw "Signing-key directory already exists; refusing to replace it: $OutputDirectory"
}
New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
$privateKeyPath = Join-Path $OutputDirectory 'private-key.pem'
$publicKeyPath = Join-Path $OutputDirectory 'public-key.pem'

$rsa = [System.Security.Cryptography.RSA]::Create(3072)
try {
    $privateKeyPem = $rsa.ExportPkcs8PrivateKeyPem()
    $publicKeyPem = $rsa.ExportSubjectPublicKeyInfoPem()
}
finally {
    $rsa.Dispose()
}
[System.IO.File]::WriteAllText($privateKeyPath, $privateKeyPem, $utf8NoBom)
[System.IO.File]::WriteAllText($publicKeyPath, $publicKeyPem, $utf8NoBom)
if (-not $IsWindows) {
    [System.IO.File]::SetUnixFileMode(
        $privateKeyPath,
        [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite)
}
$publicKeySha256 = [Convert]::ToHexString(
    [System.Security.Cryptography.SHA256]::HashData($utf8NoBom.GetBytes($publicKeyPem))
).ToLowerInvariant()

Write-Host 'PASS: isolated pilot signing key created.' -ForegroundColor Green
Write-Host " - Public key: $publicKeyPath"
Write-Host " - Public key SHA-256: $publicKeySha256"
Write-Host ' - Private key: created outside the worktree; path and material are not emitted'
