param([switch]$Capture, [switch]$Import)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) { throw 'One Godot maximum; existing process present.' }
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Official Godot executable unavailable.' }
$taskOutput = Join-Path $taskRoot 'tmp/v130r_step8'
New-Item -ItemType Directory -Force -Path $taskOutput | Out-Null
$taskRunName = 'import'
if (-not $Import) {
    $taskConfig = Get-Content -LiteralPath (Join-Path $taskOutput 'config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $taskRunName = [string]$taskConfig.name
    if ($taskRunName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple ASCII run name; prepare the configuration first.' }
}
# Preserve previous evidence before any retry can truncate a result or its logs.
$taskBackup = Join-Path $taskOutput ('run_backups/' + (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss_fff'))
New-Item -ItemType Directory -Force -Path $taskBackup | Out-Null
foreach ($taskPriorFile in @('run.log','run.err.log',($taskRunName + '.json'),'config.json')) {
    $taskPriorPath = Join-Path $taskOutput $taskPriorFile
    if (Test-Path -LiteralPath $taskPriorPath -PathType Leaf) { Copy-Item -LiteralPath $taskPriorPath -Destination (Join-Path $taskBackup $taskPriorFile) }
}
$taskAppData = $env:APPDATA; $taskLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $taskOutput 'isolated_appdata'
    $env:LOCALAPPDATA = Join-Path $taskOutput 'isolated_localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $taskArgs = '--path . --rendering-method gl_compatibility --max-fps 240'
    if ($Import) { $taskArgs += ' --headless --editor --import --quit' }
    else {
        if (-not $Capture) { $taskArgs += ' --headless' }
        $taskArgs += ' --resolution 1920x1080 --scene res://tools/tests/V130RStep8BalanceTest.tscn -- --food-system --monsters --unlock-all'
    }
    $taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -ArgumentList $taskArgs -RedirectStandardOutput (Join-Path $taskOutput 'run.log') -RedirectStandardError (Join-Path $taskOutput 'run.err.log')
    $null = $taskProcess.Handle
    while (-not $taskProcess.WaitForExit(1000)) {
        $taskErrors = Get-Content -LiteralPath (Join-Path $taskOutput 'run.err.log') -Raw
        if ($taskErrors -match 'SCRIPT ERROR|Parse Error|Failed to load script') { Stop-Process -Id $taskProcess.Id; throw 'Owned Godot stopped after script error.' }
    }
    $taskErrors = Get-Content -LiteralPath (Join-Path $taskOutput 'run.err.log') -Raw
    if ($taskProcess.ExitCode -ne 0 -or $taskErrors -match 'ERROR:') { throw 'Godot failed; inspect tmp/v130r_step8 logs.' }
} finally {
    $env:APPDATA = $taskAppData; $env:LOCALAPPDATA = $taskLocalData
    if ($taskRunName -ne 'run') {
        foreach ($taskLogSuffix in @('.log','.err.log')) {
            $taskLogPath = Join-Path $taskOutput ('run' + $taskLogSuffix)
            if (Test-Path -LiteralPath $taskLogPath -PathType Leaf) { Copy-Item -LiteralPath $taskLogPath -Destination (Join-Path $taskOutput ($taskRunName + $taskLogSuffix)) }
        }
    }
}
