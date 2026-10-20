param([ValidateSet('import','direct','balance','capture')][string]$Mode = 'direct')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) { throw 'One Godot maximum; existing process present.' }
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Godot executable unavailable.' }
$taskOutput = Join-Path $taskRoot 'tmp/v130r_step10b'
New-Item -ItemType Directory -Force -Path $taskOutput | Out-Null
$taskAppData = $env:APPDATA; $taskLocalData = $env:LOCALAPPDATA
$taskSteamDisabled = $env:MAWANG_DISABLE_STEAM
try {
    $env:MAWANG_DISABLE_STEAM = '1'
    $env:APPDATA = Join-Path $taskOutput 'isolated_appdata'
    $env:LOCALAPPDATA = Join-Path $taskOutput 'isolated_localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $taskArgs = '--path . --rendering-method gl_compatibility --max-fps 240 --resolution 1920x1080'
    if ($Mode -ne 'capture') { $taskArgs += ' --headless' }
    if ($Mode -eq 'import') { $taskArgs += ' --editor --quit' }
    else { $taskArgs += ' --scene res://tools/tests/V130RStep10BSpreadTest.tscn -- --food-system --monsters --unlock-all --spread-mode=' + $Mode }
    $taskLog = Join-Path $taskOutput ($Mode + '.log')
    $taskError = Join-Path $taskOutput ($Mode + '.err.log')
    $taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -ArgumentList $taskArgs -RedirectStandardOutput $taskLog -RedirectStandardError $taskError
    Set-Content -LiteralPath (Join-Path $taskOutput 'owned_pid.txt') -Value $taskProcess.Id -Encoding ascii
    $null = $taskProcess.Handle
    while (-not $taskProcess.WaitForExit(1000)) {
        if ((Get-Content -LiteralPath $taskError -Raw) -match 'SCRIPT ERROR|Parse Error|Failed to load script') { Stop-Process -Id $taskProcess.Id; throw 'Owned Godot stopped after script error.' }
    }
    if ($taskProcess.ExitCode -ne 0 -or (Get-Content -LiteralPath $taskError -Raw) -match 'ERROR:') { throw 'Godot failed; inspect Step10B logs.' }
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id }
    $env:APPDATA = $taskAppData; $env:LOCALAPPDATA = $taskLocalData
    $env:MAWANG_DISABLE_STEAM = $taskSteamDisabled
}
