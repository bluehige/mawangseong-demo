param([ValidateSet('s1','s1fu','s2','u5a','perf','contract','capture')][string]$Mode='contract', [string]$GodotPath='D:/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64.exe', [switch]$Probe, [string]$CaptureFilter="")
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskOut=Join-Path $taskRoot "tmp/v1213_u5b/$Mode"
$taskProfileRoot=@{s1='v1213_s1';s1fu='v1213_s1fu';s2='v1213_s2';u5a='v1213_u5a';perf='v1213_perf';contract='v1213_u5b';capture='v1213_u5b'}[$Mode]
$taskProfile=Join-Path $taskRoot "tmp/$taskProfileRoot/u5b_$Mode/profile"
$taskScenes=@{s1='V1213StageOneTest';s1fu='V1213S1FollowupTest';s2='V1213StageTwoTest';u5a='V1213U5ATest';perf='V1213PerfFreezeTest';contract='V1213U5BTest';capture='V1213U5BTest'}
$taskExisting=@(tasklist /FO CSV | Select-String -Pattern 'Godot')
if ($taskExisting.Count) { $taskExisting; throw 'Another Godot is active; wait without terminating it.' }
Write-Output 'Godot pre-launch count=0'
New-Item -ItemType Directory -Force $taskOut,$taskProfile | Out-Null
$taskArgs=@('--path','.', '--max-fps','60','--rendering-method','gl_compatibility','--resolution','1920x1080',"res://tools/tests/$($taskScenes[$Mode]).tscn")
if ($Mode -ne 'capture') { $taskArgs=@('--headless')+$taskArgs }
else { $taskArgs+=@('--','--capture-only'); if ($Probe) { $taskArgs+='--probe' }; if ($CaptureFilter) { $taskArgs+="--capture-filter=$CaptureFilter" } }
$taskPreviousAppData=$env:APPDATA
$taskProcess=$null
try {
    $env:APPDATA=$taskProfile
    $taskProcess=Start-Process -FilePath $GodotPath -WindowStyle Hidden -PassThru -WorkingDirectory $taskRoot -ArgumentList $taskArgs -RedirectStandardOutput "$taskOut/run.log" -RedirectStandardError "$taskOut/errors.log"
    $null=$taskProcess.Handle
    $taskDeadline=(Get-Date).AddSeconds(150)
    while (-not $taskProcess.HasExited) {
        if ((Get-Date) -gt $taskDeadline) { throw "Owned test timed out: $Mode" }
        if (Select-String -Path "$taskOut/errors.log" -Pattern "Parse Error:|Compile Error:" -Quiet) { throw "Test compilation failed: $Mode" }
        Start-Sleep -Milliseconds 200
    }
    $taskProcess.WaitForExit()
    Get-Content "$taskOut/run.log" -Tail 8
    $taskErrors=@(Select-String -Path "$taskOut/run.log","$taskOut/errors.log" -Pattern 'SCRIPT ERROR:|^ERROR:')
    $taskUnexpected=@($taskErrors | Where-Object { $Mode -ne 's1fu' -or $_.Line -notmatch '^ERROR: Condition "!is_inside_tree\(\)" is true\. Returning: false$' })
    if ($taskProcess.ExitCode -ne 0 -or $taskUnexpected.Count) { Get-Content "$taskOut/errors.log" -First 60; throw "U5-B $Mode FAILED; exit=$($taskProcess.ExitCode), errors=$($taskUnexpected.Count)" }
    Write-Output "U5-B $Mode PASS (baseline diagnostics=$($taskErrors.Count))"
} finally {
    # Only the process created above can be stopped on a failed test timeout.
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id; $taskProcess.WaitForExit() }
    $env:APPDATA=$taskPreviousAppData
    $taskRemaining=@(tasklist /FO CSV | Select-String -Pattern 'Godot')
    if ($taskRemaining.Count) { $taskRemaining; throw 'Godot post-run count is not zero.' }
    Write-Output 'Godot post-run count=0'
}
