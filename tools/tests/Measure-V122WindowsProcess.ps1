[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$TargetProcessId,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    [int]$DurationSeconds = 610,
    [int]$SampleIntervalSeconds = 5
)

$ErrorActionPreference = "Stop"
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$samplePath = Join-Path $outputRoot "windows_process_samples.csv"
$summaryPath = Join-Path $outputRoot "windows_process_summary.json"
$rows = [System.Collections.Generic.List[object]]::new()
$started = Get-Date

function Get-Percentile {
    param(
        [double[]]$Values,
        [double]$Percentile
    )
    if ($Values.Count -eq 0) {
        return 0.0
    }
    $sorted = @($Values | Sort-Object)
    $index = [Math]::Max(0, [Math]::Min($sorted.Count - 1, [Math]::Ceiling($sorted.Count * $Percentile) - 1))
    return [double]$sorted[$index]
}

while (((Get-Date) - $started).TotalSeconds -lt $DurationSeconds) {
    $process = Get-Process -Id $TargetProcessId -ErrorAction SilentlyContinue
    if ($null -eq $process) {
        break
    }

    $gpuUtilization = 0.0
    $gpuDedicatedBytes = 0.0
    $gpuSharedBytes = 0.0
    try {
        $counterSamples = (Get-Counter -Counter @(
            "\GPU Engine(*)\Utilization Percentage",
            "\GPU Process Memory(*)\Dedicated Usage",
            "\GPU Process Memory(*)\Shared Usage"
        ) -ErrorAction Stop).CounterSamples
        $processPrefix = "pid_${TargetProcessId}_"
        foreach ($sample in $counterSamples) {
            if (-not $sample.InstanceName.StartsWith($processPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
            if ($sample.Path.EndsWith("\utilization percentage", [System.StringComparison]::OrdinalIgnoreCase)) {
                $gpuUtilization += [Math]::Max(0.0, [double]$sample.CookedValue)
            } elseif ($sample.Path.EndsWith("\dedicated usage", [System.StringComparison]::OrdinalIgnoreCase)) {
                $gpuDedicatedBytes += [Math]::Max(0.0, [double]$sample.CookedValue)
            } elseif ($sample.Path.EndsWith("\shared usage", [System.StringComparison]::OrdinalIgnoreCase)) {
                $gpuSharedBytes += [Math]::Max(0.0, [double]$sample.CookedValue)
            }
        }
    } catch {
        $gpuUtilization = 0.0
        $gpuDedicatedBytes = 0.0
        $gpuSharedBytes = 0.0
    }

    $rows.Add([pscustomobject]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        elapsed_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
        working_set_bytes = [int64]$process.WorkingSet64
        private_memory_bytes = [int64]$process.PrivateMemorySize64
        cpu_seconds = [Math]::Round([double]$process.CPU, 3)
        thread_count = [int]$process.Threads.Count
        handle_count = [int]$process.HandleCount
        gpu_utilization_percent = [Math]::Round($gpuUtilization, 3)
        gpu_dedicated_bytes = [int64]$gpuDedicatedBytes
        gpu_shared_bytes = [int64]$gpuSharedBytes
    })
    $rows | Export-Csv -LiteralPath $samplePath -NoTypeInformation -Encoding UTF8
    Start-Sleep -Seconds $SampleIntervalSeconds
}

$workingSet = [double[]]@($rows | ForEach-Object { $_.working_set_bytes })
$privateMemory = [double[]]@($rows | ForEach-Object { $_.private_memory_bytes })
$gpuUtilization = [double[]]@($rows | ForEach-Object { $_.gpu_utilization_percent })
$gpuDedicated = [double[]]@($rows | ForEach-Object { $_.gpu_dedicated_bytes })
$gpuShared = [double[]]@($rows | ForEach-Object { $_.gpu_shared_bytes })
$summary = [ordered]@{
    schema_version = 1
    target_process_id = $TargetProcessId
    requested_duration_seconds = $DurationSeconds
    sample_interval_seconds = $SampleIntervalSeconds
    sample_count = $rows.Count
    elapsed_seconds = if ($rows.Count -gt 0) { [double]$rows[-1].elapsed_seconds } else { 0.0 }
    working_set_bytes = [ordered]@{
        start = if ($rows.Count -gt 0) { [int64]$rows[0].working_set_bytes } else { 0 }
        end = if ($rows.Count -gt 0) { [int64]$rows[-1].working_set_bytes } else { 0 }
        peak = if ($workingSet.Count -gt 0) { [int64](($workingSet | Measure-Object -Maximum).Maximum) } else { 0 }
        p95 = [int64](Get-Percentile $workingSet 0.95)
    }
    private_memory_bytes = [ordered]@{
        start = if ($rows.Count -gt 0) { [int64]$rows[0].private_memory_bytes } else { 0 }
        end = if ($rows.Count -gt 0) { [int64]$rows[-1].private_memory_bytes } else { 0 }
        peak = if ($privateMemory.Count -gt 0) { [int64](($privateMemory | Measure-Object -Maximum).Maximum) } else { 0 }
        p95 = [int64](Get-Percentile $privateMemory 0.95)
    }
    gpu_utilization_percent = [ordered]@{
        avg = if ($gpuUtilization.Count -gt 0) { [Math]::Round((($gpuUtilization | Measure-Object -Average).Average), 3) } else { 0.0 }
        p95 = [Math]::Round((Get-Percentile $gpuUtilization 0.95), 3)
        max = if ($gpuUtilization.Count -gt 0) { [Math]::Round((($gpuUtilization | Measure-Object -Maximum).Maximum), 3) } else { 0.0 }
    }
    gpu_dedicated_bytes_peak = if ($gpuDedicated.Count -gt 0) { [int64](($gpuDedicated | Measure-Object -Maximum).Maximum) } else { 0 }
    gpu_shared_bytes_peak = if ($gpuShared.Count -gt 0) { [int64](($gpuShared | Measure-Object -Maximum).Maximum) } else { 0 }
    process_exited = $null -eq (Get-Process -Id $TargetProcessId -ErrorAction SilentlyContinue)
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
Write-Output $summaryPath
