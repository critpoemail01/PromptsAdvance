[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('reserve', 'status', 'release')][string]$Command,
    [Parameter(Mandatory)][string]$ApplicationRoot,
    [string]$ProcessRoot,
    [string]$RegistryPath,
    [ValidateRange(1024, 65000)][int]$RangeStart = 5100,
    [ValidateRange(1033, 65535)][int]$RangeEnd = 8999,
    [ValidateRange(6, 100)][int]$BlockSize = 10,
    [switch]$ReallocateIfOccupied,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-NormalizedDirectory {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Label does not exist or is not a directory: $Path"
    }
    return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path).Path)
}

function Get-ApplicationId {
    param([Parameter(Mandatory)][string]$Path)

    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $utf8NoBom.GetBytes($Path.ToLowerInvariant())
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-ActiveTcpPorts {
    $ports = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($endpoint in [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()) {
        [void]$ports.Add([int]$endpoint.Port)
    }
    return $ports
}

function New-PortMap {
    param([Parameter(Mandatory)][int]$BasePort)

    return [pscustomobject][ordered]@{
        apiHttp = $BasePort
        apiHttps = $BasePort + 1
        ssrHttp = $BasePort + 2
        ssrHttps = $BasePort + 3
        webHttp = $BasePort + 4
        webHttps = $BasePort + 5
    }
}

function New-UrlMap {
    param([Parameter(Mandatory)]$Ports)

    return [pscustomobject][ordered]@{
        apiHttp = "http://127.0.0.1:$($Ports.apiHttp)"
        apiHttps = "https://127.0.0.1:$($Ports.apiHttps)"
        ssrHttp = "http://127.0.0.1:$($Ports.ssrHttp)"
        ssrHttps = "https://127.0.0.1:$($Ports.ssrHttps)"
        webHttp = "http://127.0.0.1:$($Ports.webHttp)"
        webHttps = "https://127.0.0.1:$($Ports.webHttps)"
    }
}

function New-Registry {
    return [pscustomobject][ordered]@{
        schemaVersion = 1
        revision = 0
        rangeStart = $RangeStart
        rangeEnd = $RangeEnd
        blockSize = $BlockSize
        reservations = @()
        updatedAt = $null
    }
}

function Read-Registry {
    if (-not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) {
        return New-Registry
    }
    $registry = Get-Content -Raw -Encoding UTF8 -LiteralPath $RegistryPath | ConvertFrom-Json
    if ([int]$registry.schemaVersion -ne 1 -or
        [int]$registry.rangeStart -ne $RangeStart -or
        [int]$registry.rangeEnd -ne $RangeEnd -or
        [int]$registry.blockSize -ne $BlockSize) {
        throw "Port registry configuration is incompatible or invalid: $RegistryPath"
    }
    $duplicateBases = @(
        @($registry.reservations) |
            Group-Object -Property basePort |
            Where-Object { $_.Count -gt 1 }
    )
    $duplicateApplications = @(
        @($registry.reservations) |
            Group-Object -Property applicationId |
            Where-Object { $_.Count -gt 1 }
    )
    if ($duplicateBases.Count -gt 0 -or $duplicateApplications.Count -gt 0) {
        throw "Port registry contains duplicate application or block reservations: $RegistryPath"
    }
    return $registry
}

function Save-Registry {
    param([Parameter(Mandatory)]$Registry)

    $Registry.revision = [int64]$Registry.revision + 1
    $Registry.updatedAt = [DateTimeOffset]::Now.ToString('o')
    $temporaryPath = Join-Path (Split-Path $RegistryPath -Parent) `
        ('.runtime-ports.' + [Guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllText(
            $temporaryPath,
            (($Registry | ConvertTo-Json -Depth 15) + [Environment]::NewLine),
            $utf8NoBom)
        [System.IO.File]::Move($temporaryPath, $RegistryPath, $true)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Get-FreeBasePort {
    param(
        [Parameter(Mandatory)]$Registry,
        [Parameter(Mandatory)][System.Collections.Generic.HashSet[int]]$ActivePorts,
        [AllowNull()][string]$ExcludedApplicationId
    )

    $reservedPorts = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($reservation in @($Registry.reservations)) {
        if (-not [string]::IsNullOrWhiteSpace($ExcludedApplicationId) -and
            [string]$reservation.applicationId -eq $ExcludedApplicationId) {
            continue
        }
        foreach ($port in ([int]$reservation.basePort)..([int]$reservation.basePort + $BlockSize - 1)) {
            [void]$reservedPorts.Add($port)
        }
    }

    for ($basePort = $RangeStart; $basePort + $BlockSize - 1 -le $RangeEnd; $basePort += $BlockSize) {
        $available = $true
        foreach ($port in $basePort..($basePort + $BlockSize - 1)) {
            if ($reservedPorts.Contains($port) -or $ActivePorts.Contains($port)) {
                $available = $false
                break
            }
        }
        if ($available) {
            return $basePort
        }
    }
    throw "No free block of $BlockSize TCP ports exists between $RangeStart and $RangeEnd."
}

function Get-ReservationResult {
    param(
        [Parameter(Mandatory)][string]$Status,
        [AllowNull()]$Reservation,
        [Parameter(Mandatory)][System.Collections.Generic.HashSet[int]]$ActivePorts,
        [bool]$Reallocated = $false
    )

    if ($null -eq $Reservation) {
        return [pscustomobject][ordered]@{
            status = $Status
            applicationId = $applicationId
            applicationRoot = $applicationRoot
            registryPath = $RegistryPath
        }
    }
    $occupied = @(
        foreach ($port in ([int]$Reservation.basePort)..([int]$Reservation.basePort + $BlockSize - 1)) {
            if ($ActivePorts.Contains($port)) { $port }
        }
    )
    return [pscustomobject][ordered]@{
        status = $Status
        applicationId = [string]$Reservation.applicationId
        applicationRoot = [string]$Reservation.applicationRoot
        processRoot = [string]$Reservation.processRoot
        basePort = [int]$Reservation.basePort
        blockSize = $BlockSize
        ports = $Reservation.ports
        urls = $Reservation.urls
        occupiedPorts = @($occupied)
        reallocated = $Reallocated
        registryPath = $RegistryPath
        updatedAt = [string]$Reservation.updatedAt
    }
}

function Write-Result {
    param([Parameter(Mandatory)]$Result)

    if ($Json) {
        $Result | ConvertTo-Json -Depth 10
        return
    }
    Write-Host "Advance local ports: $($Result.status)" -ForegroundColor Green
    Write-Host " - Application: $($Result.applicationRoot)"
    Write-Host " - Registry: $($Result.registryPath)"
    if ($null -ne $Result.PSObject.Properties['basePort']) {
        Write-Host " - Block: $($Result.basePort)-$([int]$Result.basePort + [int]$Result.blockSize - 1)"
        Write-Host " - API: $($Result.urls.apiHttps) / $($Result.urls.apiHttp)"
        Write-Host " - SSR: $($Result.urls.ssrHttps) / $($Result.urls.ssrHttp)"
        Write-Host " - Web: $($Result.urls.webHttps) / $($Result.urls.webHttp)"
        Write-Host " - Ports currently listening: $(@($Result.occupiedPorts) -join ', ')"
    }
}

$applicationRoot = Get-NormalizedDirectory -Path $ApplicationRoot -Label 'ApplicationRoot'
if (-not [string]::IsNullOrWhiteSpace($ProcessRoot)) {
    $ProcessRoot = Get-NormalizedDirectory -Path $ProcessRoot -Label 'ProcessRoot'
}
if ($RangeEnd - $RangeStart + 1 -lt $BlockSize) {
    throw 'The configured port range is smaller than one reservation block.'
}
if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
    $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        throw 'Could not resolve the current user profile for the local port registry.'
    }
    $RegistryPath = Join-Path (Join-Path $userProfile '.advanceappflow') 'runtime-ports.json'
}
$RegistryPath = [System.IO.Path]::GetFullPath($RegistryPath)
$registryDirectory = Split-Path $RegistryPath -Parent
if (-not (Test-Path -LiteralPath $registryDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $registryDirectory | Out-Null
}
$applicationId = Get-ApplicationId -Path $applicationRoot
$lockPath = "$RegistryPath.lock"
$lockStream = $null

try {
    foreach ($attempt in 1..100) {
        try {
            $lockStream = [System.IO.File]::Open(
                $lockPath,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
            break
        }
        catch [System.IO.IOException] {
            if ($attempt -eq 100) {
                throw 'Could not acquire the local port registry lock within ten seconds.'
            }
            Start-Sleep -Milliseconds 100
        }
    }

    $registry = Read-Registry
    $activePorts = Get-ActiveTcpPorts
    $matches = @(
        @($registry.reservations) |
            Where-Object { [string]$_.applicationId -eq $applicationId }
    )
    $reservation = $(if ($matches.Count -eq 1) { $matches[0] } else { $null })

    if ($Command -eq 'status') {
        Write-Result -Result (Get-ReservationResult `
            -Status $(if ($null -eq $reservation) { 'unreserved' } else { 'reserved' }) `
            -Reservation $reservation -ActivePorts $activePorts)
        exit 0
    }

    if ($Command -eq 'release') {
        if ($null -eq $reservation) {
            Write-Result -Result (Get-ReservationResult -Status 'already_unreserved' `
                -Reservation $null -ActivePorts $activePorts)
            exit 0
        }
        $registry.reservations = @(
            @($registry.reservations) |
                Where-Object { [string]$_.applicationId -ne $applicationId }
        )
        Save-Registry -Registry $registry
        if (-not [string]::IsNullOrWhiteSpace($ProcessRoot)) {
            $localAssignmentPath = Join-Path $ProcessRoot 'APP_LOCAL_PORTS.json'
            if (Test-Path -LiteralPath $localAssignmentPath -PathType Leaf) {
                Remove-Item -LiteralPath $localAssignmentPath -Force
            }
        }
        Write-Result -Result (Get-ReservationResult -Status 'released' `
            -Reservation $null -ActivePorts $activePorts)
        exit 0
    }

    $reallocated = $false
    $occupiedExistingPorts = @()
    if ($null -ne $reservation) {
        $occupiedExistingPorts = @(
            foreach ($port in ([int]$reservation.basePort)..([int]$reservation.basePort + $BlockSize - 1)) {
                if ($activePorts.Contains($port)) { $port }
            }
        )
    }
    if ($null -eq $reservation -or ($ReallocateIfOccupied -and $occupiedExistingPorts.Count -gt 0)) {
        $basePort = Get-FreeBasePort -Registry $registry -ActivePorts $activePorts `
            -ExcludedApplicationId $(if ($null -eq $reservation) { $null } else { $applicationId })
        $ports = New-PortMap -BasePort $basePort
        $now = [DateTimeOffset]::Now.ToString('o')
        $newReservation = [pscustomobject][ordered]@{
            applicationId = $applicationId
            applicationRoot = $applicationRoot
            processRoot = $(if ([string]::IsNullOrWhiteSpace($ProcessRoot)) { '' } else { $ProcessRoot })
            basePort = $basePort
            ports = $ports
            urls = New-UrlMap -Ports $ports
            createdAt = $(if ($null -eq $reservation) { $now } else { [string]$reservation.createdAt })
            updatedAt = $now
        }
        $registry.reservations = @(
            @($registry.reservations) |
                Where-Object { [string]$_.applicationId -ne $applicationId }
        ) + @($newReservation)
        $reservation = $newReservation
        $reallocated = $null -ne $matches -and $matches.Count -eq 1
    }
    else {
        $reservation.applicationRoot = $applicationRoot
        $reservation.processRoot = $(if ([string]::IsNullOrWhiteSpace($ProcessRoot)) { '' } else { $ProcessRoot })
        $reservation.updatedAt = [DateTimeOffset]::Now.ToString('o')
    }
    Save-Registry -Registry $registry

    if (-not [string]::IsNullOrWhiteSpace($ProcessRoot)) {
        $assignment = [pscustomobject][ordered]@{
            schemaVersion = 1
            machineLocal = $true
            doNotCommit = $true
            applicationId = $applicationId
            applicationRoot = $applicationRoot
            basePort = [int]$reservation.basePort
            blockSize = $BlockSize
            ports = $reservation.ports
            urls = $reservation.urls
            registryPath = $RegistryPath
            updatedAt = [string]$reservation.updatedAt
        }
        [System.IO.File]::WriteAllText(
            (Join-Path $ProcessRoot 'APP_LOCAL_PORTS.json'),
            (($assignment | ConvertTo-Json -Depth 10) + [Environment]::NewLine),
            $utf8NoBom)
    }

    Write-Result -Result (Get-ReservationResult -Status 'reserved' `
        -Reservation $reservation -ActivePorts $activePorts -Reallocated $reallocated)
}
finally {
    if ($null -ne $lockStream) {
        $lockStream.Dispose()
    }
}
