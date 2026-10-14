param([string]$Scene='V130AutoRoadTest', [switch]$Gui, [string]$Resolution='1920x1080', [string[]]$ExtraArgs=@(), [int]$TimeoutSeconds=240)
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskOut=Join-Path $taskRoot "tmp/v130_map/$Scene-$Resolution"
$taskWrapper=(Get-Command godot-gui.cmd).Source
$taskWrapperText=Get-Content -LiteralPath $taskWrapper -Raw
$taskGodot=[regex]::Match($taskWrapperText,'"([^"]+\.exe)"').Groups[1].Value
if (-not (Test-Path -LiteralPath $taskGodot)) { throw 'Cannot resolve installed Godot wrapper executable.' }
if (@(Get-Process Godot* -ErrorAction SilentlyContinue).Count) { throw 'Godot pre-launch count is not zero; do not launch.' }
Write-Output 'Godot pre-launch count=0'
New-Item -ItemType Directory -Force $taskOut | Out-Null
$taskOldAppData=$env:APPDATA
$taskProcess=$null
try {
    $env:APPDATA=Join-Path $taskRoot 'tmp/v130_map/profile'
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
    Write-Output "$Scene PASS baseline_diagnostics=$($taskErrors.Count)"
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id; $taskProcess.WaitForExit() }
    $env:APPDATA=$taskOldAppData
    for ($taskRetry=0; $taskRetry -lt 20 -and @(Get-Process Godot* -ErrorAction SilentlyContinue).Count; $taskRetry++) { Start-Sleep -Milliseconds 100 }
    if (@(Get-Process Godot* -ErrorAction SilentlyContinue).Count) { throw 'Godot post-run count is not zero.' }
    Write-Output 'Godot post-run count=0'
}
