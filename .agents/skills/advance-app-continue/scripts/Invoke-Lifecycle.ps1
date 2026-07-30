[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$LifecycleArguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..'))
$entryPoint = Join-Path $root 'software-lifecycle.ps1'
if (-not (Test-Path -LiteralPath $entryPoint -PathType Leaf)) {
    throw "Lifecycle entry point is missing: $entryPoint"
}

& $entryPoint @LifecycleArguments
exit $LASTEXITCODE
