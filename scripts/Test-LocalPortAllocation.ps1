[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$allocator = Join-Path $root 'scripts/Manage-AdvanceLocalPorts.ps1'
$powerShell = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $powerShell) { $powerShell = Get-Command powershell -ErrorAction Stop }
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('advance-local-ports-' + [Guid]::NewGuid().ToString('N'))
$listener = $null

function Get-FreeTestRangeStart {
    $active = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($endpoint in [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()) {
        [void]$active.Add([int]$endpoint.Port)
    }
    foreach ($candidate in 20000..40000 | Where-Object { $_ % 100 -eq 0 }) {
        $available = $true
        foreach ($port in $candidate..($candidate + 499)) {
            if ($active.Contains($port)) {
                $available = $false
                break
            }
        }
        if ($available) { return $candidate }
    }
    throw 'No free 500-port fixture range is available.'
}

function Invoke-Allocator {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$ExpectedExitCode = 0
    )
    $output = @(& $powerShell.Source -NoProfile -File $allocator @Arguments 2>&1)
    if ($LASTEXITCODE -ne $ExpectedExitCode) {
        throw "Allocator expected exit code $ExpectedExitCode, found $LASTEXITCODE. Output: $($output -join [Environment]::NewLine)"
    }
    return ($output -join [Environment]::NewLine)
}

try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    $registry = Join-Path $temporaryRoot 'machine/runtime-ports.json'
    $rangeStart = Get-FreeTestRangeStart
    $rangeEnd = $rangeStart + 499
    $apps = [ordered]@{}
    foreach ($name in @('app-a', 'app-b', 'app-c', 'app-d', 'app-e', 'app-f', 'app-g', 'app-h')) {
        $appRoot = Join-Path $temporaryRoot $name
        $processRoot = Join-Path $temporaryRoot "$name-process"
        New-Item -ItemType Directory -Path $appRoot | Out-Null
        New-Item -ItemType Directory -Path $processRoot | Out-Null
        $apps[$name] = [pscustomobject]@{ App = $appRoot; Process = $processRoot }
    }

    $listener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        $rangeStart)
    $listener.Start()

    $common = @(
        '-RegistryPath', $registry,
        '-RangeStart', [string]$rangeStart,
        '-RangeEnd', [string]$rangeEnd,
        '-BlockSize', '10',
        '-Json'
    )
    $appA = (Invoke-Allocator -Arguments (@(
        'reserve', '-ApplicationRoot', $apps['app-a'].App,
        '-ProcessRoot', $apps['app-a'].Process
    ) + $common)) | ConvertFrom-Json
    if ([int]$appA.basePort -ne $rangeStart + 10) {
        throw 'Allocator did not skip an OS-occupied block.'
    }
    $appB = (Invoke-Allocator -Arguments (@(
        'reserve', '-ApplicationRoot', $apps['app-b'].App,
        '-ProcessRoot', $apps['app-b'].Process
    ) + $common)) | ConvertFrom-Json
    if ([int]$appB.basePort -ne $rangeStart + 20 -or $appB.basePort -eq $appA.basePort) {
        throw 'Two applications received the same local port block.'
    }

    $appARepeat = (Invoke-Allocator -Arguments (@(
        'reserve', '-ApplicationRoot', $apps['app-a'].App,
        '-ProcessRoot', $apps['app-a'].Process
    ) + $common)) | ConvertFrom-Json
    if ($appARepeat.applicationId -ne $appA.applicationId -or
        [int]$appARepeat.basePort -ne [int]$appA.basePort) {
        throw 'Repeated reservation was not stable for the same application.'
    }
    $assignmentPath = Join-Path $apps['app-a'].Process 'APP_LOCAL_PORTS.json'
    $assignment = Get-Content -Raw -Encoding UTF8 -LiteralPath $assignmentPath | ConvertFrom-Json
    if (-not [bool]$assignment.machineLocal -or -not [bool]$assignment.doNotCommit -or
        [int]$assignment.ports.apiHttp -ne [int]$appA.ports.apiHttp -or
        [int]$assignment.ports.webHttps -ne [int]$appA.basePort + 5) {
        throw 'Machine-local application assignment is missing or inconsistent.'
    }

    $appAListener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        [int]$appA.basePort)
    $appAListener.Start()
    try {
        $appAReallocated = (Invoke-Allocator -Arguments (@(
            'reserve', '-ApplicationRoot', $apps['app-a'].App,
            '-ProcessRoot', $apps['app-a'].Process,
            '-ReallocateIfOccupied'
        ) + $common)) | ConvertFrom-Json
    }
    finally {
        $appAListener.Stop()
    }
    if (-not [bool]$appAReallocated.reallocated -or
        [int]$appAReallocated.basePort -eq [int]$appA.basePort -or
        [int]$appAReallocated.basePort -eq [int]$appB.basePort) {
        throw 'An occupied reservation was not moved to a distinct free block.'
    }

    $runningProcesses = @()
    foreach ($name in @('app-d', 'app-e', 'app-f', 'app-g', 'app-h')) {
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $powerShell.Source
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        foreach ($argument in @(
            '-NoProfile', '-File', $allocator, 'reserve',
            '-ApplicationRoot', $apps[$name].App,
            '-ProcessRoot', $apps[$name].Process,
            '-RegistryPath', $registry,
            '-RangeStart', [string]$rangeStart,
            '-RangeEnd', [string]$rangeEnd,
            '-BlockSize', '10', '-Json'
        )) {
            [void]$startInfo.ArgumentList.Add([string]$argument)
        }
        $runningProcesses += [pscustomobject]@{
            Name = $name
            Process = [System.Diagnostics.Process]::Start($startInfo)
        }
    }
    $concurrentResults = @(
        foreach ($running in $runningProcesses) {
            if (-not $running.Process.WaitForExit(30000)) {
                $running.Process.Kill($true)
                throw "Concurrent reservation timed out: $($running.Name)"
            }
            $stdout = $running.Process.StandardOutput.ReadToEnd()
            $stderr = $running.Process.StandardError.ReadToEnd()
            if ($running.Process.ExitCode -ne 0) {
                throw "Concurrent reservation failed for $($running.Name): $stderr $stdout"
            }
            $stdout | ConvertFrom-Json
        }
    )
    if (@($concurrentResults.basePort | Sort-Object -Unique).Count -ne $concurrentResults.Count) {
        throw 'Concurrent applications received duplicate port blocks.'
    }

    $registryState = Get-Content -Raw -Encoding UTF8 -LiteralPath $registry | ConvertFrom-Json
    $allBases = @($registryState.reservations | ForEach-Object { [int]$_.basePort })
    if (@($allBases | Sort-Object -Unique).Count -ne $allBases.Count) {
        throw 'Persisted registry contains duplicate port blocks.'
    }

    $releaseB = (Invoke-Allocator -Arguments (@(
        'release', '-ApplicationRoot', $apps['app-b'].App,
        '-ProcessRoot', $apps['app-b'].Process
    ) + $common)) | ConvertFrom-Json
    if ($releaseB.status -ne 'released' -or
        (Test-Path -LiteralPath (Join-Path $apps['app-b'].Process 'APP_LOCAL_PORTS.json'))) {
        throw 'Explicit release did not remove the reservation and local assignment.'
    }

    Write-Host 'PASS: concurrent local application port allocation.' -ForegroundColor Green
    Write-Host " - Registry locking: $($runningProcesses.Count) concurrent reservations"
    Write-Host " - Occupied OS block skipped: $rangeStart-$($rangeStart + 9)"
    Write-Host ' - Stable reuse, conflict reallocation and explicit release: verified'
}
finally {
    if ($null -ne $listener) { $listener.Stop() }
    if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
