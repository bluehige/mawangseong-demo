[CmdletBinding()]
param(
    [ValidateSet("Quick", "Full", "SelfTest")]
    [string]$Mode = "Full",
    [string]$GodotPath = "",
    [string[]]$SkipCheckId = @()
)

$ErrorActionPreference = "Stop"
$script:RootPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$configPath = Join-Path $PSScriptRoot "core_verification_suite.json"

function Resolve-GodotExecutable {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        $resolved = Resolve-Path -LiteralPath $RequestedPath -ErrorAction Stop
        return $resolved.Path
    }

    foreach ($commandName in @("godot4", "godot", "godot.exe")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command.Source
        }
    }

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $godotFolders = Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Directory -Filter "Godot*" -ErrorAction SilentlyContinue
        foreach ($folder in $godotFolders) {
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

function Expand-VerificationChecks {
    param([array]$Checks)

    $expandedChecks = @()
    foreach ($check in $Checks) {
        $cases = if ($check.PSObject.Properties.Name -contains "cases") { @($check.cases) } else { @() }
        if ($cases.Count -eq 0) {
            $expandedChecks += $check
            continue
        }
        foreach ($case in $cases) {
            $expanded = [ordered]@{}
            foreach ($property in $check.PSObject.Properties) {
                if ($property.Name -ne "cases") {
                    $expanded[$property.Name] = $property.Value
                }
            }
            $expanded["id"] = "{0}_{1}" -f [string]$check.id, [string]$case.id_suffix
            $expanded["name"] = "{0} · {1}" -f [string]$check.name, [string]$case.name_suffix
            foreach ($property in $case.PSObject.Properties) {
                if ($property.Name -notin @("id_suffix", "name_suffix")) {
                    $expanded[$property.Name] = $property.Value
                }
            }
            $expandedChecks += [pscustomobject]$expanded
        }
    }
    return $expandedChecks
}

function Stop-VerificationProcessTree {
    param([System.Diagnostics.Process]$Process)

    if ($null -eq $Process) {
        return
    }
    if ($env:OS -eq "Windows_NT") {
        $taskkillPath = Join-Path $env:SystemRoot "System32\taskkill.exe"
        if (Test-Path -LiteralPath $taskkillPath -PathType Leaf) {
            & $taskkillPath /PID ([string]$Process.Id) /T /F 2>$null | Out-Null
        }
    }
    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    }
    $null = $Process.WaitForExit(10000)
}

function Invoke-VerificationCheck {
    param(
        [object]$Check,
        [string]$Executable,
        [string]$RunDirectory,
        [datetime]$RunStartedAt,
        [int]$StaleToleranceSeconds,
        [int]$DefaultTimeoutSeconds
    )

    $arguments = New-Object System.Collections.Generic.List[string]
    if ([bool]$Check.headless) {
        $arguments.Add("--headless")
    }
    $arguments.Add("--path")
    $arguments.Add($script:RootPath)
    if ([bool]$Check.editor_import) {
        if ($null -ne $Check.PSObject.Properties["wait_for_import"] -and [bool]$Check.wait_for_import) {
            $arguments.Add("--import")
        }
        else {
            $arguments.Add("--editor")
            $arguments.Add("--quit")
        }
    }
    else {
        $arguments.Add("--scene")
        $arguments.Add([string]$Check.scene)
    }
    $userArguments = @($Check.user_args | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($userArguments.Count -gt 0) {
        $arguments.Add("--")
        foreach ($argument in $userArguments) {
            $arguments.Add([string]$argument)
        }
    }

    $stdoutPath = Join-Path $RunDirectory (([string]$Check.id) + ".stdout.log")
    $stderrPath = Join-Path $RunDirectory (([string]$Check.id) + ".stderr.log")
    $combinedPath = Join-Path $RunDirectory (([string]$Check.id) + ".log")
    $argumentLine = (($arguments | ForEach-Object { Quote-NativeArgument $_ }) -join " ")
    $startedAt = Get-Date
    $exitCode = -1
    $launchError = ""
	$timeoutSeconds = if ($Check.PSObject.Properties.Name -contains "timeout_seconds") { [int]$Check.timeout_seconds } else { $DefaultTimeoutSeconds }

    Write-Host ("[RUN] {0}" -f [string]$Check.name)
	$process = $null
    try {
        $process = Start-Process -FilePath $Executable -ArgumentList $argumentLine -WorkingDirectory $script:RootPath -NoNewWindow -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
		$null = $process.Handle
        if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
            Stop-VerificationProcessTree -Process $process
            $exitCode = 124
            $launchError = "Timed out after $timeoutSeconds seconds."
        }
        else {
			$process.WaitForExit()
			$process.Refresh()
            $exitCode = $process.ExitCode
        }
    }
    catch {
        $launchError = $_.Exception.Message
		$exitCode = -1
		Stop-VerificationProcessTree -Process $process
	}
	finally {
		if ($null -ne $process) {
			$process.Dispose()
		}
	}
    $completedAt = Get-Date

    $combinedLines = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $stdoutPath) {
        foreach ($line in Get-Content -LiteralPath $stdoutPath -Encoding UTF8) {
            $combinedLines.Add($line)
        }
    }
    if (Test-Path -LiteralPath $stderrPath) {
        foreach ($line in Get-Content -LiteralPath $stderrPath -Encoding UTF8) {
            $combinedLines.Add($line)
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($launchError)) {
        $combinedLines.Add($launchError)
    }
    Set-Content -LiteralPath $combinedPath -Value $combinedLines -Encoding UTF8

    $artifactResults = @()
    $artifactFailure = $false
    foreach ($relativePath in @($Check.artifacts)) {
        $absolutePath = Join-Path $script:RootPath ([string]$relativePath)
        $exists = Test-Path -LiteralPath $absolutePath -PathType Leaf
        $fresh = $false
        $lastWriteTime = $null
        $artifactStatus = "missing"
        if ($exists) {
            $file = Get-Item -LiteralPath $absolutePath
            $lastWriteTime = $file.LastWriteTime
            $fresh = $file.LastWriteTimeUtc -ge $RunStartedAt.ToUniversalTime().AddSeconds(-$StaleToleranceSeconds)
            $artifactStatus = if ($fresh) { "fresh" } else { "stale" }
        }
        if (-not $fresh) {
            $artifactFailure = $true
        }
        $artifactResults += [ordered]@{
            path = ([string]$relativePath).Replace("\", "/")
            exists = $exists
            fresh = $fresh
            status = $artifactStatus
            last_write_time = if ($null -eq $lastWriteTime) { $null } else { $lastWriteTime.ToString("o") }
        }
    }

    $passed = ($exitCode -eq 0) -and (-not $artifactFailure)
    Write-Host ("[{0}] {1} ({2:N1}s)" -f $(if ($passed) { "PASS" } else { "FAIL" }), [string]$Check.name, ($completedAt - $startedAt).TotalSeconds)
    return [ordered]@{
        id = [string]$Check.id
        name = [string]$Check.name
        passed = $passed
        exit_code = $exitCode
        launch_error = $launchError
        started_at = $startedAt.ToString("o")
        completed_at = $completedAt.ToString("o")
        duration_seconds = [math]::Round(($completedAt - $startedAt).TotalSeconds, 2)
        command = ((Quote-NativeArgument $Executable) + " " + $argumentLine)
        log = $combinedPath.Substring($script:RootPath.Length).TrimStart([char[]]@('\', '/')).Replace("\", "/")
        artifacts = $artifactResults
    }
}

function Write-VerificationReport {
    param(
        [object]$Config,
        [string]$SelectedMode,
        [string]$Executable,
        [datetime]$StartedAt,
        [datetime]$CompletedAt,
        [array]$Results,
        [string]$CommitSha,
        [string]$CatalogSha256,
        [bool]$SourceTreeClean,
        [string]$OutputDirectory,
        [string]$RunDirectory
    )

    $passedCount = @($Results | Where-Object { $_.passed }).Count
    $failedCount = $Results.Count - $passedCount
    $report = [ordered]@{
        version = 1
        runner = "tools/tests/RunCoreVerification.ps1"
        commit_sha = $CommitSha
        catalog_sha256 = $CatalogSha256
        source_tree_clean = $SourceTreeClean
        generated_at = $CompletedAt.ToString("o")
        mode = $SelectedMode.ToLowerInvariant()
        passed = ($failedCount -eq 0)
        started_at = $StartedAt.ToString("o")
        completed_at = $CompletedAt.ToString("o")
        duration_seconds = [math]::Round(($CompletedAt - $StartedAt).TotalSeconds, 2)
        godot_path = $Executable
        counts = [ordered]@{
            total = $Results.Count
            passed = $passedCount
            failed = $failedCount
        }
        checks = $Results
    }

    $jsonText = $report | ConvertTo-Json -Depth 12
    $latestJsonPath = Join-Path $OutputDirectory "latest.json"
    $runJsonPath = Join-Path $RunDirectory "report.json"
    Set-Content -LiteralPath $latestJsonPath -Value $jsonText -Encoding UTF8
    Set-Content -LiteralPath $runJsonPath -Value $jsonText -Encoding UTF8

    $text = $Config.report
    $overallLabel = if ($report.passed) { [string]$text.pass } else { [string]$text.fail }
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# $([string]$text.title)")
    $lines.Add("")
    $lines.Add("- $([string]$text.generated_at): ``$($CompletedAt.ToString('yyyy-MM-dd HH:mm:ss'))``")
    $lines.Add("- $([string]$text.mode): **$SelectedMode**")
    $lines.Add("- $([string]$text.overall): **$overallLabel** ($passedCount/$($Results.Count))")
    $lines.Add("")
    $lines.Add("## $([string]$text.summary)")
    $lines.Add("")
    $lines.Add("| $([string]$text.check) | $([string]$text.result) | $([string]$text.duration) | $([string]$text.artifacts) | $([string]$text.log) |")
    $lines.Add("|---|---:|---:|---|---|")
    foreach ($result in $Results) {
        $statusLabel = if ($result.passed) { [string]$text.pass } else { [string]$text.fail }
        $artifactLabels = New-Object System.Collections.Generic.List[string]
        foreach ($artifact in @($result.artifacts)) {
            $artifactStatusLabel = switch ([string]$artifact.status) {
                "fresh" { [string]$text.fresh }
                "stale" { [string]$text.stale }
                default { [string]$text.missing }
            }
            $artifactLabels.Add("``$([string]$artifact.path)``: $artifactStatusLabel")
        }
        $artifactText = if ($artifactLabels.Count -eq 0) { [string]$text.not_required } else { $artifactLabels -join "<br>" }
        $lines.Add("| $([string]$result.name) | $statusLabel | $([string]$result.duration_seconds)$([string]$text.seconds) | $artifactText | ``$([string]$result.log)`` |")
    }
    $lines.Add("")
    $lines.Add("## $([string]$text.limitations)")
    $lines.Add("")
    $lines.Add("- $([string]$text.limitation_text)")
    $markdownText = $lines -join [Environment]::NewLine
    $latestMarkdownPath = Join-Path $OutputDirectory "latest.md"
    $runMarkdownPath = Join-Path $RunDirectory "report.md"
    Set-Content -LiteralPath $latestMarkdownPath -Value $markdownText -Encoding UTF8
    Set-Content -LiteralPath $runMarkdownPath -Value $markdownText -Encoding UTF8
    return $report
}

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Verification config is missing: $configPath"
}

$commitOutput = @(git -C $script:RootPath rev-parse HEAD 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Could not resolve the verification commit: $($commitOutput -join ' ')"
}
$commitSha = ([string]($commitOutput | Select-Object -Last 1)).Trim()
if ($commitSha -notmatch '^[0-9a-f]{40}$') {
    throw "Verification commit is not a full lowercase SHA: $commitSha"
}
$catalogSha256 = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash.ToLowerInvariant()
$treeStatus = @(git -C $script:RootPath status --porcelain --untracked-files=normal 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Could not inspect the verification working tree: $($treeStatus -join ' ')"
}
$sourceTreeClean = $treeStatus.Count -eq 0

$config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$godotExecutable = Resolve-GodotExecutable $GodotPath
$selectedMode = $Mode.ToLowerInvariant()
$configuredChecks = @($config.checks | Where-Object {
    (@($_.modes) -contains $selectedMode) -and ($SkipCheckId -notcontains [string]$_.id)
})
$selectedChecks = @(Expand-VerificationChecks -Checks $configuredChecks)
if ($selectedChecks.Count -eq 0) {
    throw "No checks are configured for mode: $Mode"
}

$outputDirectory = Join-Path $script:RootPath "tmp\core_verification"
$runsDirectory = Join-Path $outputDirectory "runs"
$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$runDirectory = Join-Path $runsDirectory $runId
New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null

$startedAt = Get-Date
$results = @()
Write-Host ("Core verification started: mode={0}, checks={1}" -f $Mode, $selectedChecks.Count)
Write-Host ("Godot: {0}" -f $godotExecutable)
foreach ($check in $selectedChecks) {
    $results += Invoke-VerificationCheck -Check $check -Executable $godotExecutable -RunDirectory $runDirectory -RunStartedAt $startedAt -StaleToleranceSeconds ([int]$config.stale_tolerance_seconds) -DefaultTimeoutSeconds ([int]$config.default_timeout_seconds)
}
$completedAt = Get-Date
$finalReport = Write-VerificationReport -Config $config -SelectedMode $Mode -Executable $godotExecutable -StartedAt $startedAt -CompletedAt $completedAt -Results $results -CommitSha $commitSha -CatalogSha256 $catalogSha256 -SourceTreeClean $sourceTreeClean -OutputDirectory $outputDirectory -RunDirectory $runDirectory

Write-Host ("CORE_VERIFICATION_REPORT_JSON: {0}" -f (Join-Path $outputDirectory "latest.json"))
Write-Host ("CORE_VERIFICATION_REPORT_MARKDOWN: {0}" -f (Join-Path $outputDirectory "latest.md"))
Write-Host ("CORE_VERIFICATION: {0}" -f $(if ($finalReport.passed) { "PASS" } else { "FAIL" }))
exit $(if ($finalReport.passed) { 0 } else { 1 })
