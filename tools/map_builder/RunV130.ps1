param([string]$Scene='V130AutoRoadTest', [switch]$Gui, [string]$Resolution='1920x1080', [string[]]$ExtraArgs=@(), [int]$TimeoutSeconds=240)
$ErrorActionPreference='Stop'
function Get-TaskGodotProcesses {
    foreach ($taskCandidate in @(Get-Process Godot* -ErrorAction SilentlyContinue)) {
        try {
            if (-not $taskCandidate.HasExited) { [pscustomobject]@{Id=$taskCandidate.Id;Name=$taskCandidate.ProcessName} }
        } catch [System.InvalidOperationException] {
            # The process exited between enumeration and the live-state probe.
        } finally { $taskCandidate.Dispose() }
    }
}
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskOut=Join-Path $taskRoot "tmp/v130_map/$Scene-$Resolution"
$taskWrapper=(Get-Command godot-gui.cmd).Source
$taskWrapperText=Get-Content -LiteralPath $taskWrapper -Raw
$taskGodot=[regex]::Match($taskWrapperText,'"([^"]+\.exe)"').Groups[1].Value
if (-not (Test-Path -LiteralPath $taskGodot)) { throw 'Cannot resolve installed Godot wrapper executable.' }
if (@(Get-TaskGodotProcesses).Count) { throw 'Godot pre-launch count is not zero; do not launch.' }
Write-Output 'Godot pre-launch count=0'
New-Item -ItemType Directory -Force $taskOut | Out-Null
foreach ($taskExtra in $ExtraArgs) {
    if ($taskExtra.StartsWith('--output-dir=res://')) {
        $taskResultDir=Join-Path $taskRoot $taskExtra.Substring('--output-dir=res://'.Length)
        New-Item -ItemType Directory -Force $taskResultDir | Out-Null
    }
}
$taskOldAppData=$env:APPDATA
$taskProcess=$null
try {
    $taskProfileNames=@{V1213StageOneTest='v1213_s1';V1213S1FollowupTest='v1213_s1fu';V1213StageTwoTest='v1213_s2';V1213U5ATest='v1213_u5a';V1213U5BTest='v1213_u5b';V1213PerfFreezeTest='v1213_perf';V1213U5CTest='v1213_u5c';V1213U5DTest='v1213_u5d';V1213U5ETest='v1213_u5e';V1213U5FTest='v1213_u5f'}
    $taskProfileName=$taskProfileNames[$Scene]
    if (-not $taskProfileName) { $taskProfileName='v130' }
    $env:APPDATA=Join-Path $taskRoot "tmp/v130_map/profile/tmp/$taskProfileName/profile"
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    $taskArgs=@('--path',"`"$taskRoot`"",'--max-fps','60','--rendering-method','gl_compatibility','--resolution',$Resolution,"res://tools/tests/$Scene.tscn")
    if (-not $Gui) { $taskArgs=@('--headless')+$taskArgs }
    if ($ExtraArgs.Count) { $taskArgs+=@('--')+$ExtraArgs }
    $taskProcess=Start-Process -FilePath $taskGodot -WindowStyle Hidden -PassThru -ArgumentList $taskArgs -WorkingDirectory $taskRoot -RedirectStandardOutput "$taskOut/run.log" -RedirectStandardError "$taskOut/errors.log"
    $null=$taskProcess.Handle
    $taskDeadline=(Get-Date).AddSeconds($TimeoutSeconds)
    while (-not $taskProcess.HasExited) {
        if ((Get-Date) -gt $taskDeadline) { throw "Owned Godot timed out: $Scene" }
        if (Select-String -Path "$taskOut/errors.log" -Pattern 'Parse Error:|Compile Error:|SCRIPT ERROR:' -Quiet) { throw "Compilation/runtime failed: $Scene" }
        Start-Sleep -Milliseconds 200
    }
    $taskProcess.WaitForExit()
    Get-Content "$taskOut/run.log" -Tail 8
    $taskErrors=@(Select-String -Path "$taskOut/run.log","$taskOut/errors.log" -Pattern 'SCRIPT ERROR:|^ERROR:')
    $taskUnexpected=@($taskErrors | Where-Object { $Scene -ne 'V1213S1FollowupTest' -or $_.Line -notmatch '^ERROR: Condition "!is_inside_tree\(\)" is true\. Returning: false$' })
    if ($taskProcess.ExitCode -ne 0 -or $taskUnexpected.Count) { Get-Content "$taskOut/errors.log" -First 45; throw "$Scene FAILED exit=$($taskProcess.ExitCode) errors=$($taskUnexpected.Count)" }
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id; $taskProcess.WaitForExit() }
    if ($taskProcess) { $taskProcess.Dispose(); $taskProcess=$null }
    $env:APPDATA=$taskOldAppData
    for ($taskRetry=0; $taskRetry -lt 50 -and @(Get-TaskGodotProcesses).Count; $taskRetry++) { Start-Sleep -Milliseconds 100 }
    if (@(Get-TaskGodotProcesses).Count) { Get-TaskGodotProcesses | Format-Table; throw 'Godot post-run live count is not zero.' }
    Write-Output 'Godot post-run count=0'
}

Write-Output "$Scene PASS baseline_diagnostics=$($taskErrors.Count)"
