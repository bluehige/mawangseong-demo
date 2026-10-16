param(
    [ValidateSet('manual','import','direct','capture','balance')][string]$Mode = 'manual',
    [switch]$UnlockAll,
    [switch]$LastDayOnly,
    [switch]$Fresh
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) { throw 'Close existing Godot first; one process maximum.' }
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Official Godot executable missing from wrapper.' }
$taskOutput = Join-Path $taskRoot 'tmp/v130r_step7'
New-Item -ItemType Directory -Force -Path $taskOutput | Out-Null
$taskAppData = $env:APPDATA
$taskLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $taskOutput 'isolated_appdata'
    $env:LOCALAPPDATA = Join-Path $taskOutput 'isolated_localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    $taskArgs = '--path . --rendering-method gl_compatibility --max-fps 60'
    switch ($Mode) {
        'import' { $taskArgs += ' --headless --editor --import --quit' }
        'balance' { $taskArgs += ' --headless --scene res://tools/tests/V130RStep7MonstersTest.tscn -- --food-system --monsters --unlock-all --balance' }
        'direct' { $taskArgs += ' --headless --scene res://tools/tests/V130RStep7MonstersTest.tscn -- --food-system --monsters --unlock-all' }
        'capture' { $taskArgs += ' --resolution 1920x1080 --scene res://tools/tests/V130RStep7MonstersTest.tscn -- --food-system --monsters --unlock-all --capture' }
        'manual' { $taskArgs += ' --resolution 1920x1080 --scene res://scenes/map_builder/ApprovedPlacementPreview.tscn -- --food-system --monsters' }
    }
    if ($LastDayOnly -and $Mode -eq 'balance') { $taskArgs += ' --balance-last' }
    if ($UnlockAll -and $Mode -eq 'manual') { $taskArgs += ' --unlock-all' }
    if ($Fresh -and $Mode -eq 'manual') { $taskArgs += ' --fresh-grade-f' }
    $taskStyle = 'Hidden'
    $taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle $taskStyle -PassThru -ArgumentList $taskArgs -RedirectStandardOutput (Join-Path $taskOutput "$Mode.log") -RedirectStandardError (Join-Path $taskOutput "$Mode.err.log")
    $null = $taskProcess.Handle
    $taskDeadline = (Get-Date).AddSeconds(420)
    while (-not $taskProcess.WaitForExit(1000)) {
        if ((Get-Date) -gt $taskDeadline) { Stop-Process -Id $taskProcess.Id; throw 'Owned Godot timed out and was stopped.' }
        if ($Mode -ne 'manual' -and (Get-Item -LiteralPath (Join-Path $taskOutput "$Mode.err.log")).Length -gt 0) {
            $taskErrors = Get-Content -LiteralPath (Join-Path $taskOutput "$Mode.err.log") -Raw
            if ($taskErrors -match 'SCRIPT ERROR|Parse Error|Failed to load script') { Stop-Process -Id $taskProcess.Id; throw 'Godot script error; owned process stopped. See logs.' }
        }
    }
    $taskFinalErrors = Get-Content -LiteralPath (Join-Path $taskOutput "$Mode.err.log") -Raw
    if ($taskFinalErrors -match 'SCRIPT ERROR|Parse Error|Failed to load script|ERROR:') { throw "Godot $Mode reported errors; see logs." }
    if ($taskProcess.ExitCode -ne 0) { throw "Godot $Mode failed: $($taskProcess.ExitCode); see tmp/v130r_step7 logs." }
} finally {
    $env:APPDATA = $taskAppData
    $env:LOCALAPPDATA = $taskLocalData
}
