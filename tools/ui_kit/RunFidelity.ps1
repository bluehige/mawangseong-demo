param([string]$Profile = 'fidelity', [string]$GodotPath = 'D:/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64.exe', [switch]$WaitForIdle)
$ErrorActionPreference = 'Stop'
if ($Profile -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple profile name.' }
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskOut = Join-Path $taskRoot "tmp/v1213_u4/$Profile"
New-Item -ItemType Directory -Force "$taskOut/profile" | Out-Null
$taskPreviousAppData = $env:APPDATA
$taskProcess = $null
$taskGpu = [System.Collections.Generic.List[object]]::new()
try {
    while ($WaitForIdle -and (Get-Process -Name '*Godot*' -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 3 }
    if (Get-Process -Name '*Godot*' -ErrorAction SilentlyContinue) { throw 'Close the existing Godot instance first.' }
    $env:APPDATA = "$taskOut/profile"
    $taskProcess = Start-Process -FilePath $GodotPath -WindowStyle Hidden -PassThru -WorkingDirectory $taskRoot -ArgumentList @('--path', '.', '--rendering-method', 'gl_compatibility', '--resolution', '1920x1080', 'res://tools/ui_kit/FidelityGallery.tscn', '--', "--fidelity-out=tmp/v1213_u4/$Profile") -RedirectStandardOutput "$taskOut/render.log" -RedirectStandardError "$taskOut/render_errors.log"
    $null = $taskProcess.Handle
    $taskDeadline = (Get-Date).AddSeconds(45)
    while (-not $taskProcess.HasExited) {
        if ((Get-Date) -gt $taskDeadline) { throw 'Fidelity renderer exceeded 45 seconds.' }
        $taskUsage = & nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used --format=csv,noheader,nounits
        $taskGpu.Add([string]$taskUsage)
        Start-Sleep -Milliseconds 250
    }
    $taskProcess.WaitForExit()
    $taskGpu | Set-Content -Encoding UTF8 "$taskOut/gpu_samples.csv"
    if ($taskProcess.ExitCode -ne 0) { throw "Renderer exit=$($taskProcess.ExitCode)" }
    if (Select-String -Path "$taskOut/render.log","$taskOut/render_errors.log" -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Renderer reported an error.' }
    & python (Join-Path $PSScriptRoot 'fidelity.py') $taskOut
    if ($LASTEXITCODE -ne 0) { throw 'Fidelity geometry check failed.' }
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id }
    $env:APPDATA = $taskPreviousAppData
}
