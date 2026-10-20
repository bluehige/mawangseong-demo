param([ValidateSet('s1','s1fu','s2','u5a','u5b','perf','u5c','u5d','contract','capture')][string]$Mode='contract', [switch]$Touch, [string]$OutputRoot='tmp/v1213_u5e', [string]$CaptureFilter='', [string]$GodotPath='D:/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64.exe')
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskSuffix=if ($Touch) { "${Mode}_touch" } else { $Mode }
$taskOut=Join-Path $taskRoot "$OutputRoot/$taskSuffix"
$taskProfileRoot=@{s1='v1213_s1';s1fu='v1213_s1fu';s2='v1213_s2';u5a='v1213_u5a';u5b='v1213_u5b';perf='v1213_perf';u5c='v1213_u5c';u5d='v1213_u5d';contract='v1213_u5e';capture='v1213_u5e'}[$Mode]
$taskProfile=Join-Path $taskRoot "tmp/$taskProfileRoot/u5e_$Mode/profile"
$taskScenes=@{s1='V1213StageOneTest';s1fu='V1213S1FollowupTest';s2='V1213StageTwoTest';u5a='V1213U5ATest';u5b='V1213U5BTest';perf='V1213PerfFreezeTest';u5c='V1213U5CTest';u5d='V1213U5DTest';contract='V1213U5ETest';capture='V1213U5ETest'}
$taskExisting=@(tasklist /FO CSV | Select-String -Pattern 'Godot')
while ($taskExisting.Count) { Write-Output 'Another Godot is active; waiting without termination.'; Start-Sleep -Seconds 2; $taskExisting=@(tasklist /FO CSV | Select-String -Pattern 'Godot') }
Write-Output 'Godot pre-launch count=0'
New-Item -ItemType Directory -Force $taskOut,$taskProfile | Out-Null
$taskArgs=@('--path','.', '--max-fps','60','--rendering-method','gl_compatibility','--resolution','1920x1080',"res://tools/tests/$($taskScenes[$Mode]).tscn")
if ($Mode -ne 'capture') { $taskArgs=@('--headless')+$taskArgs }
if ($Mode -in @('u5c','u5d','contract','capture','u5b')) { $taskArgs+=@('--',"--output-dir=res://$OutputRoot/$taskSuffix"); if ($Mode -eq 'capture') { $taskArgs+='--capture-only'; if ($CaptureFilter) { $taskArgs+="--capture-filter=$CaptureFilter" } } }
if ($Touch) { $taskArgs+="--mobile-touch-ui" }
$taskPreviousAppData=$env:APPDATA
$taskProcess=$null
try {
    $env:APPDATA=$taskProfile
    $taskProcess=Start-Process -FilePath $GodotPath -WindowStyle Hidden -PassThru -WorkingDirectory $taskRoot -ArgumentList $taskArgs -RedirectStandardOutput "$taskOut/run.log" -RedirectStandardError "$taskOut/errors.log"
    $null=$taskProcess.Handle
    $taskDeadline=(Get-Date).AddSeconds(150)
    while (-not $taskProcess.HasExited) {
        if ((Get-Date) -gt $taskDeadline) { throw "Owned test timed out: $Mode" }
        if (Select-String -Path "$taskOut/errors.log" -Pattern 'Parse Error:|Compile Error:|SCRIPT ERROR:' -Quiet) { throw "Test compilation failed: $Mode" }
        Start-Sleep -Milliseconds 200
    }
    $taskProcess.WaitForExit()
    Get-Content "$taskOut/run.log" -Tail 6
    $taskErrors=@(Select-String -Path "$taskOut/run.log","$taskOut/errors.log" -Pattern 'SCRIPT ERROR:|^ERROR:')
    $taskUnexpected=@($taskErrors | Where-Object { $Mode -ne 's1fu' -or $_.Line -notmatch '^ERROR: Condition "!is_inside_tree\(\)" is true\. Returning: false$' })
    if ($taskProcess.ExitCode -ne 0 -or $taskUnexpected.Count) { Get-Content "$taskOut/errors.log" -First 60; throw "U5-E $Mode FAILED; exit=$($taskProcess.ExitCode), errors=$($taskUnexpected.Count)" }
    Write-Output "U5-E $Mode PASS (baseline diagnostics=$($taskErrors.Count))"
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id; $taskProcess.WaitForExit() }
    $env:APPDATA=$taskPreviousAppData
    $taskRemaining=@(tasklist /FO CSV | Select-String -Pattern 'Godot')
    if ($taskRemaining.Count) { $taskRemaining; throw 'Godot post-run count is not zero.' }
    Write-Output 'Godot post-run count=0'
}
