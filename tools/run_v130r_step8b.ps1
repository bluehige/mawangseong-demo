param([switch]$Capture, [switch]$VerboseEngine)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) { throw 'One Godot maximum; existing process present.' }
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Official Godot executable unavailable.' }
$taskOutput = Join-Path $taskRoot 'tmp/v130r_step8b'
$taskConfig = Get-Content -LiteralPath (Join-Path $taskOutput 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$taskRunName = [string]$taskConfig.name
if ($taskRunName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use an ASCII run name.' }
foreach ($taskPriorSuffix in @('.json','.log','.err.log','_checks.json')) {
    if (Test-Path -LiteralPath (Join-Path $taskOutput ($taskRunName + $taskPriorSuffix))) { throw 'Use a new name to preserve existing trial evidence.' }
}
Copy-Item -LiteralPath (Join-Path $taskOutput 'config.json') -Destination (Join-Path $taskOutput ($taskRunName + '_config.json'))
$taskAppData = $env:APPDATA; $taskLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $taskOutput 'isolated_appdata'
    $env:LOCALAPPDATA = Join-Path $taskOutput 'isolated_localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $taskArgs = '--path . --rendering-method gl_compatibility --max-fps 240 --resolution 1920x1080'
    if ($VerboseEngine) { $taskArgs += ' --verbose' }
    if (-not $Capture) { $taskArgs += ' --headless' }
    $taskArgs += ' --scene res://tools/tests/V130RStep8BSpreadTest.tscn -- --food-system --monsters --unlock-all'
    $taskLog = Join-Path $taskOutput ($taskRunName + '.log')
    $taskError = Join-Path $taskOutput ($taskRunName + '.err.log')
    $taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -ArgumentList $taskArgs -RedirectStandardOutput $taskLog -RedirectStandardError $taskError
    $null = $taskProcess.Handle
    while (-not $taskProcess.WaitForExit(1000)) {
        if ((Get-Content -LiteralPath $taskError -Raw) -match 'SCRIPT ERROR|Parse Error|Failed to load script') { Stop-Process -Id $taskProcess.Id; throw 'Owned Godot stopped after script error.' }
    }
    if ($taskProcess.ExitCode -ne 0 -or (Get-Content -LiteralPath $taskError -Raw) -match 'ERROR:') { throw 'Godot failed; inspect Step8B logs.' }
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id }
    $env:APPDATA = $taskAppData; $env:LOCALAPPDATA = $taskLocalData
}
