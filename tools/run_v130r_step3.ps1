param(
    [ValidateSet('manual','import','direct','capture')][string]$Mode = 'manual',
    [switch]$UnlockAll
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) { throw 'Close the existing Godot process first; only one is allowed.' }
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Official Godot executable was not found in the wrapper.' }
$taskOutput = Join-Path $taskRoot 'tmp/v130r_step3'
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
        'direct' { $taskArgs += ' --headless --scene res://tools/tests/V130RStep3PlacementTest.tscn' }
        'capture' { $taskArgs += ' --resolution 1920x1080 --scene res://tools/tests/V130RStep3PlacementTest.tscn -- --capture' }
        'manual' { $taskArgs += ' --resolution 1920x1080 --scene res://scenes/map_builder/ApprovedPlacementPreview.tscn' }
    }
    if ($UnlockAll -and $Mode -eq 'manual') { $taskArgs += ' -- --unlock-all' }
    $taskStyle = if ($Mode -eq 'manual') { 'Normal' } else { 'Hidden' }
    $taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle $taskStyle -PassThru -ArgumentList $taskArgs -RedirectStandardOutput (Join-Path $taskOutput "$Mode.log") -RedirectStandardError (Join-Path $taskOutput "$Mode.err.log")
    $null = $taskProcess.Handle
    if (-not $taskProcess.WaitForExit(120000)) {
        Stop-Process -Id $taskProcess.Id
        throw 'Owned Godot process timed out and was stopped.'
    }
    if ($taskProcess.ExitCode -ne 0) { throw "Godot $Mode failed: $($taskProcess.ExitCode). See tmp/v130r_step3/$Mode*.log" }
} finally {
    $env:APPDATA = $taskAppData
    $env:LOCALAPPDATA = $taskLocalData
}
