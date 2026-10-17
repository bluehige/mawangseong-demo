param([ValidateSet('import','direct','capture','export','offline','export_smoke')][string]$Mode = 'direct')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) { throw 'One Godot maximum; existing process present.' }
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Godot executable unavailable.' }
$taskOutput = Join-Path $taskRoot 'tmp/v130r_step13'
New-Item -ItemType Directory -Force -Path $taskOutput | Out-Null
$taskAppData = $env:APPDATA; $taskLocalData = $env:LOCALAPPDATA; $taskSteam = $env:MAWANG_DISABLE_STEAM
try {
    $env:APPDATA = Join-Path $taskOutput ($Mode + '_appdata')
    $env:LOCALAPPDATA = Join-Path $taskOutput ($Mode + '_localappdata')
    $env:MAWANG_DISABLE_STEAM = if ($Mode -in @('offline','export_smoke')) { '0' } else { '1' }
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    if ($Mode -eq 'export') {
        $taskTemplates = Join-Path $taskAppData 'Godot/export_templates/4.6.3.stable'
        $taskTemplateParent = Join-Path $env:APPDATA 'Godot/export_templates'
        New-Item -ItemType Directory -Force -Path $taskTemplateParent | Out-Null
        $taskTemplateLink = Join-Path $taskTemplateParent '4.6.3.stable'
        if (-not (Test-Path -LiteralPath $taskTemplateLink)) { New-Item -ItemType Junction -Path $taskTemplateLink -Target $taskTemplates | Out-Null }
    }
    $taskArgs = '--path . --rendering-method gl_compatibility --max-fps 120 --resolution 1920x1080'
    if ($Mode -ne 'capture') { $taskArgs += ' --headless' }
    if ($Mode -eq 'import') { $taskArgs += ' --editor --import' }
    elseif ($Mode -eq 'export') {
        New-Item -ItemType Directory -Force -Path (Join-Path $taskOutput 'export') | Out-Null
        $taskArgs += ' --export-release "Windows Desktop" tmp/v130r_step13/export/MawangCastle.exe'
    } elseif ($Mode -eq 'export_smoke') {
        $taskExe = Join-Path $taskOutput 'export/MawangCastle.exe'
        $taskArgs = '--headless --quit-after 60'
    } else { $taskArgs += ' --scene res://tools/tests/V130RStep13AchievementTest.tscn -- --ach-mode=' + $Mode }
    $taskLog = Join-Path $taskOutput ($Mode + '.log')
    $taskError = Join-Path $taskOutput ($Mode + '.err.log')
    $taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -ArgumentList $taskArgs -RedirectStandardOutput $taskLog -RedirectStandardError $taskError
    $null = $taskProcess.Handle
    $taskDeadline = (Get-Date).AddMinutes(8)
    while (-not $taskProcess.WaitForExit(1000)) {
        if ((Get-Date) -gt $taskDeadline -or (Get-Content -LiteralPath $taskError -Raw) -match 'SCRIPT ERROR|Parse Error|Failed to load script') {
            Stop-Process -Id $taskProcess.Id; throw 'Owned Godot stopped after error or timeout; inspect Step13 logs.'
        }
    }
    if ($taskProcess.ExitCode -ne 0 -or (Get-Content -LiteralPath $taskError -Raw) -match 'ERROR:') { throw 'Godot failed; inspect Step13 logs.' }
    Get-Content -LiteralPath $taskLog -Tail 6
} finally {
    if ($taskProcess -and -not $taskProcess.HasExited) { Stop-Process -Id $taskProcess.Id }
    $env:APPDATA = $taskAppData; $env:LOCALAPPDATA = $taskLocalData; $env:MAWANG_DISABLE_STEAM = $taskSteam
}
