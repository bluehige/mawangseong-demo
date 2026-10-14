param([ValidateSet('capture','contract','kit','sweep_desktop','sweep_touch','s1','s1fu','s2')][string]$Mode='capture', [string]$GodotPath='D:/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64.exe')
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskOut=Join-Path $taskRoot "tmp/v1213_u5a/$Mode"
$taskPreviousAppData=$env:APPDATA
$taskProcess=$null
$taskGpu=[System.Collections.Generic.List[object]]::new()
if (Get-Process -Name '*Godot*' -ErrorAction SilentlyContinue) { throw 'Existing Godot process is active; do not start another GUI.' }
$taskProfile="tmp/v1213_u5a/$Mode/profile"
$taskArgs=@('--path','.', '--max-fps','60', '--rendering-method','gl_compatibility','--resolution','1920x1080')
switch ($Mode) {
    'capture' { $taskArgs+=@('res://tools/tests/V1213U5ATest.tscn','--','--capture-only') }
    'contract' { $taskArgs+=@('res://tools/tests/V1213U5ATest.tscn') }
    'kit' { $taskProfile='tmp/v1213_u4/u5a_contract/profile'; $taskArgs+=@('res://tools/ui_kit/KitContractTest.tscn','--','--kit-empty-tooltip') }
    'sweep_desktop' { $taskArgs+=@('res://tools/ux_audit/Sweep.tscn','--','--audit-out=tmp/v1213_u5a/sweep_desktop') }
    'sweep_touch' { $taskArgs+=@('res://tools/ux_audit/Sweep.tscn','--','--audit-out=tmp/v1213_u5a/sweep_touch','--mobile-touch-ui') }
    's1' { $taskProfile='tmp/v1213_s1/u5a/profile'; $taskArgs+=@('--headless','res://tools/tests/V1213StageOneTest.tscn') }
    's1fu' { $taskProfile='tmp/v1213_s1fu/u5a/profile'; $taskArgs+=@('--headless','res://tools/tests/V1213S1FollowupTest.tscn') }
    's2' { $taskProfile='tmp/v1213_s2/u5a/profile'; $taskArgs+=@('--headless','res://tools/tests/V1213StageTwoTest.tscn') }
}
New-Item -ItemType Directory -Force $taskOut,(Join-Path $taskRoot $taskProfile) | Out-Null
try {
    $env:APPDATA=Join-Path $taskRoot $taskProfile
    $taskProcess=Start-Process -FilePath $GodotPath -WindowStyle Hidden -PassThru -WorkingDirectory $taskRoot -ArgumentList $taskArgs -RedirectStandardOutput "$taskOut/run.log" -RedirectStandardError "$taskOut/errors.log"
    $null=$taskProcess.Handle
    $taskDeadline=(Get-Date).AddSeconds(180)
    while (-not $taskProcess.HasExited) {
        if ((Get-Date) -gt $taskDeadline) { throw "Godot timeout: $Mode" }
        if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
            $taskGpu.Add([string](& nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used --format=csv,noheader,nounits))
        }
        Start-Sleep -Milliseconds 500
    }
    $taskProcess.WaitForExit()
    $taskGpu | Set-Content -Encoding UTF8 "$taskOut/gpu_samples.csv"
    if ($taskProcess.ExitCode -ne 0) { throw "Godot exit=$($taskProcess.ExitCode): $Mode" }
    if (Select-String -Path "$taskOut/run.log","$taskOut/errors.log" -Pattern 'SCRIPT ERROR:' -Quiet) { throw "Godot script errors: $Mode" }
    $taskErrors=@(Select-String -Path "$taskOut/run.log","$taskOut/errors.log" -Pattern '^ERROR:')
    if ($taskErrors.Count -gt 0) {
        $taskKnown='^ERROR: Condition "!is_inside_tree\(\)" is true\. Returning: false$'
        if ($Mode -ne 's1fu' -or $taskErrors.Count -gt 7 -or @($taskErrors | Where-Object { $_.Line -notmatch $taskKnown }).Count -gt 0) { throw "Godot errors: $Mode" }
        Write-Output "S1 followup: $($taskErrors.Count) documented baseline can_process diagnostics."
    }
    Get-Content "$taskOut/run.log" -Tail 5
    Write-Output "U5-A $Mode PASS; process exited."
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id }
    $env:APPDATA=$taskPreviousAppData
}
