param([ValidateSet('before','direct','capture','import','manual')][string]$Mode = 'direct')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if ($Mode -eq 'before' -and (Get-Content -LiteralPath (Join-Path $taskRoot 'scripts/game/GameRoot.gd') -Raw).Contains('var start_flow')) { throw 'Baseline captures are already preserved. Before mode requires the pre-Step14 source.' }
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) { throw 'One Godot maximum; existing process present.' }
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Godot executable unavailable.' }
$taskOutput = Join-Path $taskRoot 'tmp/v130r_step14'
New-Item -ItemType Directory -Force -Path $taskOutput | Out-Null
$taskAppData = $env:APPDATA; $taskLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $taskOutput ($Mode + '_appdata')
    $env:LOCALAPPDATA = Join-Path $taskOutput ($Mode + '_localappdata')
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $taskArgs = '--path . --rendering-method gl_compatibility --max-fps 120 --resolution 1920x1080'
    if ($Mode -in @('direct','import')) { $taskArgs += ' --headless' }
    if ($Mode -eq 'import') { $taskArgs += ' --editor --quit' }
    elseif ($Mode -eq 'manual') { $taskArgs += ' --scene res://scenes/main/Main.tscn' }
    else { $taskArgs += ' --scene res://tools/tests/V130RStep14StartTest.tscn -- --start-mode=' + $Mode + ' --fresh-grade-f' }
    $taskLog = Join-Path $taskOutput ($Mode + '.log')
    $taskError = Join-Path $taskOutput ($Mode + '.err.log')
    $taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -ArgumentList $taskArgs -RedirectStandardOutput $taskLog -RedirectStandardError $taskError
    $null = $taskProcess.Handle
    while (-not $taskProcess.WaitForExit(1000)) {
        if ((Get-Content -LiteralPath $taskError -Raw) -match 'SCRIPT ERROR|Parse Error|Failed to load script') { Stop-Process -Id $taskProcess.Id; throw 'Owned Godot stopped after script error.' }
    }
    if ($taskProcess.ExitCode -ne 0 -or (Get-Content -LiteralPath $taskError -Raw) -match 'ERROR:') { throw 'Godot failed; inspect Step14 logs.' }
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id }
    $env:APPDATA = $taskAppData; $env:LOCALAPPDATA = $taskLocalData
}
