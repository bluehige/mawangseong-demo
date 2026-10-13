param([switch]$WaitForIdle)
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskExe = 'D:/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64.exe'
$taskOut = Join-Path $taskRoot 'tmp/v1213_u4/fidelity'
$taskPreviousAppData = $env:APPDATA
Push-Location $taskRoot
function Wait-TaskIdle {
    while ($WaitForIdle -and (Get-Process -Name '*Godot*' -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 3 }
    if (Get-Process -Name '*Godot*' -ErrorAction SilentlyContinue) { throw 'An existing Godot instance is active.' }
}
function Invoke-TaskGodot([string[]]$TaskArguments,[string]$TaskLog,[int]$TaskTimeout) {
    $taskProcess = Start-Process -FilePath $taskExe -WindowStyle Hidden -PassThru -WorkingDirectory $taskRoot -ArgumentList $TaskArguments -RedirectStandardOutput "$TaskLog.log" -RedirectStandardError "$TaskLog.errors.log"
    $null = $taskProcess.Handle
    try {
        if (-not $taskProcess.WaitForExit($TaskTimeout*1000)) { throw "Godot timeout: $TaskLog" }
        if ($taskProcess.ExitCode -ne 0) { throw "Godot exit=$($taskProcess.ExitCode): $TaskLog" }
        if (Select-String -Path "$TaskLog.log","$TaskLog.errors.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw "Godot errors: $TaskLog" }
    } finally { if (-not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id } }
}
try {
    Wait-TaskIdle
    $env:APPDATA = Join-Path $taskOut 'contracts/profile'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    Invoke-TaskGodot @('--path','.','--max-fps','60','--rendering-method','gl_compatibility','--resolution','1280x720','res://tools/ui_kit/KitContractTest.tscn','--','--kit-empty-tooltip') (Join-Path $taskOut 'contracts_final') 60
    Write-Output 'CONTRACT complete'
    foreach ($taskMode in @('desktop','touch')) {
        Wait-TaskIdle
        $taskSweep = "tmp/v1213_u4/fidelity/sweep_$taskMode"
        $env:APPDATA = Join-Path $taskRoot "$taskSweep/profile"
        New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
        $taskArgs = @('--path','.','--max-fps','60','--rendering-method','gl_compatibility','--resolution','1920x1080','res://tools/ux_audit/Sweep.tscn','--',"--audit-out=$taskSweep")
        if ($taskMode -eq 'touch') { $taskArgs += '--mobile-touch-ui' }
        Invoke-TaskGodot $taskArgs (Join-Path $taskOut "sweep_$taskMode") 180
        Write-Output "SWEEP $taskMode complete"
    }
    & python tools/ux_audit/scan.py tmp/v1213_u4/fidelity/sweep_desktop tmp/v1213_u4/fidelity/sweep_touch
    if ($LASTEXITCODE -ne 0) { throw 'Sweep scanner failed.' }
} finally {
    $env:APPDATA = $taskPreviousAppData
    Pop-Location
}
