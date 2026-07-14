[CmdletBinding()]
param(
    [string]$GodotPath = "",
    [string]$RunId = "",
    [string]$CommitSha = "",
    [ValidateRange(30, 1800)]
    [int]$TrialTimeoutSeconds = 300,
    [ValidateRange(30, 600)]
    [int]$SummaryTimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"
$script:RootPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$trialScene = "res://tools/update3_baseline/Update3BaselineTrial.tscn"
$summaryScene = "res://tools/update3_baseline/Update3BaselineSummary.tscn"
$expectedTrialCount = 54

function Resolve-GodotExecutable {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        return (Resolve-Path -LiteralPath $RequestedPath -ErrorAction Stop).Path
    }
    foreach ($commandName in @("godot4", "godot", "godot.exe")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command.Source
        }
    }
    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        foreach ($folder in Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Directory -Filter "Godot*" -ErrorAction SilentlyContinue) {
            $candidates += Get-ChildItem -LiteralPath $folder.FullName -File -Filter "Godot*_console.exe" -Recurse -ErrorAction SilentlyContinue
        }
    }
    $candidate = $candidates | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if ($null -eq $candidate) {
        throw "Godot executable was not found. Pass -GodotPath with the console executable path."
    }
    return $candidate.FullName
}

function Quote-NativeArgument {
    param([string]$Value)
    return '"' + $Value.Replace('"', '\"') + '"'
}

function Stop-VerificationProcessTree {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process) {
        return $true
    }
    try {
        if ($Process.HasExited) {
            return $true
        }
    }
    catch {
        return $false
    }
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        try {
            & taskkill.exe /PID $Process.Id /T /F 2>$null | Out-Null
        }
        catch {
            # Fall through to Stop-Process below.
        }
        try {
            if ($Process.WaitForExit(10000)) {
                return $true
            }
        }
        catch {
            # Fall through to Stop-Process below.
        }
    }
    try {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    }
    catch {
        # The bounded wait below decides whether cleanup succeeded.
    }
    try {
        return $Process.WaitForExit(10000)
    }
    catch {
        return $false
    }
}

function Invoke-BaselineScene {
    param(
        [string]$Name,
        [string]$Executable,
        [string]$Scene,
        [string[]]$UserArguments,
        [string]$LogDirectory,
        [string]$ExpectedArtifact,
        [int]$TimeoutSeconds
    )

    $arguments = New-Object System.Collections.Generic.List[string]
    foreach ($argument in @("--headless", "--path", $script:RootPath, "--scene", $Scene, "--")) {
        $arguments.Add($argument)
    }
    foreach ($argument in $UserArguments) {
        $arguments.Add($argument)
    }
    $argumentLine = (($arguments | ForEach-Object { Quote-NativeArgument $_ }) -join " ")
    $stdoutPath = Join-Path $LogDirectory ($Name + ".stdout.log")
    $stderrPath = Join-Path $LogDirectory ($Name + ".stderr.log")
    $combinedPath = Join-Path $LogDirectory ($Name + ".log")
    $startedAt = Get-Date
    $exitCode = -1
    $launchError = ""
    $cleanupSucceeded = $true
    $process = $null
    Write-Host ("[RUN] {0}" -f $Name)
    try {
        $process = Start-Process -FilePath $Executable -ArgumentList $argumentLine -WorkingDirectory $script:RootPath -NoNewWindow -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $null = $process.Handle
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $cleanupSucceeded = Stop-VerificationProcessTree -Process $process
            $exitCode = 124
            $launchError = "Timed out after $TimeoutSeconds seconds."
            if (-not $cleanupSucceeded) {
                $launchError += " Process-tree cleanup did not finish within 10 seconds."
            }
        }
        else {
            if (-not $process.WaitForExit(10000)) {
                $cleanupSucceeded = Stop-VerificationProcessTree -Process $process
                $launchError = "Process exit stream flush did not finish within 10 seconds."
                $exitCode = 125
            }
            $process.Refresh()
            if ($exitCode -ne 125) {
                $exitCode = $process.ExitCode
            }
        }
    }
    catch {
        $launchError = $_.Exception.Message
        if ($null -ne $process) {
            $cleanupSucceeded = Stop-VerificationProcessTree -Process $process
            if (-not $cleanupSucceeded) {
                $launchError += " Process-tree cleanup did not finish within 10 seconds."
            }
        }
    }
    finally {
        if ($null -ne $process) {
            $process.Dispose()
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($launchError)) {
        Add-Content -LiteralPath $stderrPath -Value $launchError -Encoding UTF8
    }
    $combinedLines = @()
    if (Test-Path -LiteralPath $stdoutPath) {
        $combinedLines += Get-Content -LiteralPath $stdoutPath -Encoding UTF8
    }
    if (Test-Path -LiteralPath $stderrPath) {
        $combinedLines += Get-Content -LiteralPath $stderrPath -Encoding UTF8
    }
    Set-Content -LiteralPath $combinedPath -Value $combinedLines -Encoding UTF8
    $completedAt = Get-Date
    $artifactExists = Test-Path -LiteralPath $ExpectedArtifact -PathType Leaf
    $artifactFresh = $false
    if ($artifactExists) {
        $artifactFresh = (Get-Item -LiteralPath $ExpectedArtifact).LastWriteTimeUtc -ge $startedAt.ToUniversalTime().AddSeconds(-2)
    }
    $passed = $exitCode -eq 0 -and $artifactFresh -and $cleanupSucceeded
    Write-Host ("[{0}] {1} ({2:N1}s)" -f $(if ($passed) { "PASS" } else { "FAIL" }), $Name, ($completedAt - $startedAt).TotalSeconds)
    return [pscustomobject][ordered]@{
        name = $Name
        passed = $passed
        exit_code = $exitCode
        launch_error = $launchError
        cleanup_succeeded = $cleanupSucceeded
        started_at = $startedAt.ToString("o")
        completed_at = $completedAt.ToString("o")
        duration_seconds = [math]::Round(($completedAt - $startedAt).TotalSeconds, 2)
        command = (Quote-NativeArgument $Executable) + " " + $argumentLine
        log_path = $combinedPath
        artifact_path = $ExpectedArtifact
        artifact_exists = $artifactExists
        artifact_fresh = $artifactFresh
    }
}

$sourceStatus = @(& git -C $script:RootPath status --porcelain=v1 --untracked-files=all)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the Git source tree."
}
if ($sourceStatus.Count -ne 0) {
    throw "Update3 baseline evidence requires a clean source tree. Commit or remove intended changes first."
}
$actualCommitSha = (& git -C $script:RootPath rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $actualCommitSha.Length -ne 40) {
    throw "Unable to resolve the full Git commit SHA."
}
if (-not [string]::IsNullOrWhiteSpace($CommitSha) -and $CommitSha -ne $actualCommitSha) {
    throw "Requested CommitSha does not match HEAD: $CommitSha != $actualCommitSha"
}
$CommitSha = $actualCommitSha
$shortSha = $CommitSha.Substring(0, 8)
if ([string]::IsNullOrWhiteSpace($RunId)) {
    $RunId = "{0}-{1}" -f (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ"), $shortSha
}
if ($RunId -notmatch '^[A-Za-z0-9._-]+$') {
    throw "RunId may contain only letters, numbers, dot, underscore, and hyphen."
}

$executable = Resolve-GodotExecutable -RequestedPath $GodotPath
$runDirectory = Join-Path $script:RootPath ("tmp\update3_baseline\runs\" + $RunId)
if (Test-Path -LiteralPath $runDirectory) {
    throw "Run directory already exists; choose a fresh RunId: $runDirectory"
}
$trialDirectory = Join-Path $runDirectory "trials"
$logDirectory = Join-Path $runDirectory "logs"
New-Item -ItemType Directory -Path $trialDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$runStartedAt = Get-Date
$trialResults = New-Object System.Collections.Generic.List[object]

for ($trialIndex = 0; $trialIndex -lt $expectedTrialCount; $trialIndex++) {
    $name = "trial_{0:D2}" -f $trialIndex
    $artifact = Join-Path $trialDirectory ($name + ".json")
    $result = Invoke-BaselineScene `
        -Name $name `
        -Executable $executable `
        -Scene $trialScene `
        -UserArguments @(
            "--trial-index=$trialIndex",
            "--baseline-run-id=$RunId",
            "--commit-sha=$CommitSha",
            "--output-path=$artifact"
        ) `
        -LogDirectory $logDirectory `
        -ExpectedArtifact $artifact `
        -TimeoutSeconds $TrialTimeoutSeconds
    $trialResults.Add($result)
}

$summaryArtifact = Join-Path $runDirectory "summary.json"
$summaryResult = Invoke-BaselineScene `
    -Name "summary" `
    -Executable $executable `
    -Scene $summaryScene `
    -UserArguments @(
        "--input-dir=$trialDirectory",
        "--output-dir=$runDirectory",
        "--baseline-run-id=$RunId",
        "--commit-sha=$CommitSha"
    ) `
    -LogDirectory $logDirectory `
    -ExpectedArtifact $summaryArtifact `
    -TimeoutSeconds $SummaryTimeoutSeconds

$runCompletedAt = Get-Date
$failedTrials = @($trialResults | Where-Object { -not $_.passed }).Count
$passed = $failedTrials -eq 0 -and $summaryResult.passed
$runnerReport = [ordered]@{
    schema_version = 1
    tool = "RunUpdate3Baseline.ps1"
    evidence_kind = "automated_update3_day30_proxy_runner"
    assignment_kind = "forced_automated_proxy"
    run_id = $RunId
    commit_sha = $CommitSha
    source_tree_clean = $true
    godot_path = $executable
    started_at = $runStartedAt.ToString("o")
    completed_at = $runCompletedAt.ToString("o")
    duration_seconds = [math]::Round(($runCompletedAt - $runStartedAt).TotalSeconds, 2)
    expected_trials = $expectedTrialCount
    passed_trials = $expectedTrialCount - $failedTrials
    failed_trials = $failedTrials
    passed = $passed
    trials = @($trialResults)
    summary = $summaryResult
    limitations = @(
        "This runner assigns combinations; it does not measure player choice rates.",
        "The 54 DAY 30 proxy trials do not replace the original 15 full-campaign proxy runs.",
        "The matrix repeats 18 pairwise-balanced fractional assignments across three seeds and cannot estimate triple interactions.",
        "Each front includes one fixed reachable DAY 28 operation, so front and operation effects are confounded."
    )
}
$runnerReportPath = Join-Path $runDirectory "runner.json"
$runnerReport | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $runnerReportPath -Encoding UTF8
Write-Host ("UPDATE3_BASELINE_RUNNER_JSON: {0}" -f $runnerReportPath)
Write-Host ("UPDATE3_BASELINE_RUNNER: {0}" -f $(if ($passed) { "PASS" } else { "FAIL" }))
exit $(if ($passed) { 0 } else { 1 })
