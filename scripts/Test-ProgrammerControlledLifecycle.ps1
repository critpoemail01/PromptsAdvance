[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$lifecycle = Join-Path $root 'software-lifecycle.ps1'
$boilerplate = [System.IO.Path]::GetFullPath((Join-Path $root '../BoilerPlateAdvance'))
$powerShell = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $powerShell) { $powerShell = Get-Command powershell -ErrorAction Stop }
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
    ('advance-programmer-controlled-' + [Guid]::NewGuid().ToString('N'))

function Invoke-Lifecycle {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& $powerShell.Source -NoProfile -File $lifecycle @Arguments 2>&1)
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
}

function Assert-ExitCode {
    param($Execution, [int]$Expected, [string]$Label)
    if ($Execution.ExitCode -ne $Expected) {
        throw "$Label expected $Expected, found $($Execution.ExitCode). Output: $($Execution.Output)"
    }
}

function Read-State {
    param([string]$ProcessRoot)
    Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $ProcessRoot 'LIFECYCLE_STATE.json') | ConvertFrom-Json
}

try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    if (-not (Test-Path -LiteralPath $boilerplate -PathType Container)) {
        $boilerplate = Join-Path $temporaryRoot 'BoilerPlateAdvance'
        New-Item -ItemType Directory -Path $boilerplate | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $boilerplate 'README.md'), "fixture`n", $utf8NoBom)
    }

    $process = Join-Path $temporaryRoot 'greenfield-process'
    Assert-ExitCode (Invoke-Lifecycle @(
        'start', '-Name', 'programmer-controlled-test', '-Owner', 'Fixture owner',
        '-ProcessRoot', $process, '-BoilerplatePath', $boilerplate
    )) 0 'start'

    Assert-ExitCode (Invoke-Lifecycle @(
        'record', '-ProcessRoot', $process, '-PromptId', '01', '-Result', 'completed',
        '-Evidence', 'fixture://prompt-01', '-Summary', 'Prompt 01 objective achieved'
    )) 0 'record completed'
    $state = Read-State $process
    if ($state.status -ne 'awaiting_programmer' -or $null -ne $state.currentPrompt -or
        $state.nextAction -ne 'next | repeat | correct | skip_and_advance') {
        throw 'record did not stop and wait for the programmer.'
    }

    Assert-ExitCode (Invoke-Lifecycle @('validate', '-ProcessRoot', $process)) 0 'validate after prompt 01'
    Assert-ExitCode (Invoke-Lifecycle @('next', '-ProcessRoot', $process)) 0 'next'
    $state = Read-State $process
    if ($state.currentPrompt -ne '02' -or $state.status -ne 'ready') {
        throw 'next did not prepare exactly prompt 02.'
    }

    $revisionBeforeInvalidPartial = [int64]$state.revision
    $invalidPartial = Invoke-Lifecycle @(
        'record', '-ProcessRoot', $process, '-PromptId', '02', '-Result', 'partial',
        '-Evidence', 'fixture://prompt-02', '-Summary', 'Only a shortlist exists'
    )
    if ($invalidPartial.ExitCode -eq 0) { throw 'partial was accepted without RemainingWork.' }
    if ([int64](Read-State $process).revision -ne $revisionBeforeInvalidPartial) {
        throw 'Rejected partial result changed lifecycle state.'
    }

    Assert-ExitCode (Invoke-Lifecycle @(
        'record', '-ProcessRoot', $process, '-PromptId', '02', '-Result', 'partial',
        '-Evidence', 'fixture://prompt-02', '-Summary', 'Only a shortlist exists',
        '-RemainingWork', 'Choose and validate the final name'
    )) 0 'record partial'

    $unacceptedAdvance = Invoke-Lifecycle @('advance', '-ProcessRoot', $process)
    Assert-ExitCode $unacceptedAdvance 0 'advance confirmation'
    if ($unacceptedAdvance.Output -notmatch 'CONFIRMATION REQUIRED' -or
        (Read-State $process).status -ne 'awaiting_programmer') {
        throw 'Incomplete prompt advanced without explicit acceptance.'
    }

    Assert-ExitCode (Invoke-Lifecycle @(
        'advance', '-ProcessRoot', $process, '-AcceptIncomplete',
        '-Objective', 'Accepted for this fixture iteration'
    )) 0 'skip and advance'
    if ((Read-State $process).currentPrompt -ne '03') { throw 'Prompt 03 was not prepared.' }

    Assert-ExitCode (Invoke-Lifecycle @(
        'record', '-ProcessRoot', $process, '-PromptId', '03', '-Result', 'completed',
        '-Evidence', 'fixture://prompt-03', '-Summary', 'Requirements captured'
    )) 0 'record prompt 03'

    $requestPrevious = Invoke-Lifecycle @('request', '-ProcessRoot', $process, '-PromptId', '01')
    Assert-ExitCode $requestPrevious 0 'request prior prompt'
    if ($requestPrevious.Output -notmatch 'Previous result: completed' -or
        $requestPrevious.Output -notmatch 'Previous summary: Prompt 01 objective achieved') {
        throw 'Request omitted the previous result or summary.'
    }

    Assert-ExitCode (Invoke-Lifecycle @(
        'repeat', '-ProcessRoot', $process, '-PromptId', '01',
        '-Objective', 'Revalidate after changing the target audience', '-ConfirmRepeat'
    )) 0 'confirmed repeat'
    $state = Read-State $process
    if ($state.currentPrompt -ne '01' -or
        $state.prompts.'01'.rerunObjective -ne 'Revalidate after changing the target audience') {
        throw 'Confirmed repeat did not preserve its objective.'
    }
    Assert-ExitCode (Invoke-Lifecycle @('validate', '-ProcessRoot', $process)) 0 'final greenfield validate'

    $application = Join-Path $temporaryRoot 'existing-application'
    New-Item -ItemType Directory -Path $application | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $application 'existing.txt'), "implemented`n", $utf8NoBom)
    $brownfield = Join-Path $temporaryRoot 'brownfield-process'
    Assert-ExitCode (Invoke-Lifecycle @(
        'adopt', '-ProjectPath', $application, '-Name', 'brownfield-test',
        '-Owner', 'Fixture owner', '-ProcessRoot', $brownfield,
        '-BoilerplatePath', $boilerplate
    )) 0 'brownfield adopt'

    $brownfieldRequest = Invoke-Lifecycle @('request', '-ProcessRoot', $brownfield, '-PromptId', '01')
    Assert-ExitCode $brownfieldRequest 0 'brownfield overlap notice'
    if ($brownfieldRequest.Output -notmatch 'existing application' -or
        $brownfieldRequest.Output -notmatch 'no evidence proving') {
        throw 'Brownfield request did not report unproven overlap.'
    }
    Assert-ExitCode (Invoke-Lifecycle @(
        'repeat', '-ProcessRoot', $brownfield, '-PromptId', '01',
        '-Objective', 'Inventory the implemented product and identify gaps', '-ConfirmRepeat'
    )) 0 'brownfield confirmation'
    Assert-ExitCode (Invoke-Lifecycle @('validate', '-ProcessRoot', $brownfield)) 0 'brownfield validate'

    Write-Host 'PASS: programmer-controlled lifecycle.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
