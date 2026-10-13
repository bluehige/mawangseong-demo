param([string]$LogName = 'save_lock.log', [switch]$Graphical)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$evidence = Join-Path $repo 'tmp/v1213_s1'
$taskProfile = Join-Path $evidence ('lock-profile-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $taskProfile | Out-Null
foreach ($name in @('lock-ready.txt','lock-held.txt','unlock-request.txt','lock-released.txt')) {
    $marker = Join-Path $evidence $name
    if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker }
}
$previousAppData = $env:APPDATA
$process = $null
$locked = $null
try {
    $env:APPDATA = $taskProfile
    # Resolve the installed command; do not depend on a versioned application path.
    $command = (Get-Command godot.cmd).Source
    $launch = Join-Path $taskProfile 'launch.cmd'
    $log = Join-Path $evidence $LogName
    $displayArgs = if ($Graphical) { '--rendering-method gl_compatibility' } else { '--headless' }
    $arguments = $displayArgs + ' --path "' + $repo + '" res://tools/tests/V1213SaveLockTest.tscn'
    [IO.File]::WriteAllText($launch, '@call "' + $command + '" ' + $arguments + ' > "' + $log + '" 2>&1', [Text.Encoding]::Default)
    $process = Start-Process -FilePath $env:ComSpec -ArgumentList @('/c', ('"' + $launch + '"')) -WindowStyle Hidden -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(40)
    $ready = Join-Path $evidence 'lock-ready.txt'
    while (!(Test-Path -LiteralPath $ready)) {
        if ($process.HasExited -or [DateTime]::UtcNow -gt $deadline) { throw 'Test did not produce lock-ready marker' }
        Start-Sleep -Milliseconds 100
    }
    $savePath = [IO.File]::ReadAllText($ready)
    $resolvedSave = [IO.Path]::GetFullPath($savePath)
    if (!$resolvedSave.StartsWith($taskProfile + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Save path escaped isolated profile' }
    $locked = [IO.File]::Open($resolvedSave, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    [IO.File]::WriteAllText((Join-Path $evidence 'lock-held.txt'),'locked')
    while (!(Test-Path -LiteralPath (Join-Path $evidence 'unlock-request.txt'))) {
        if ($process.HasExited -or [DateTime]::UtcNow -gt $deadline) { throw 'Test did not reach unlock request' }
        Start-Sleep -Milliseconds 100
    }
    $locked.Dispose()
    $locked = $null
    [IO.File]::WriteAllText((Join-Path $evidence 'lock-released.txt'),'released')
    if (!$process.WaitForExit(10000)) { throw 'Test did not exit' }
    Get-Content -Encoding UTF8 -LiteralPath $log
    if ($process.ExitCode -ne 0) { throw ('Save lock test failed: ' + $process.ExitCode) }
} finally {
    if ($null -ne $locked) { $locked.Dispose() }
    $env:APPDATA = $previousAppData
}
