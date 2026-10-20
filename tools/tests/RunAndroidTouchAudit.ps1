param([switch]$Capture)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$out = Join-Path $repo 'tmp/android_audit'
New-Item -ItemType Directory -Force $out | Out-Null
$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*godot*' })
if ($running.Count) { throw 'Godot must be at zero processes before the audit.' }
if ($Capture -and @(Get-ChildItem -LiteralPath $out -Filter '*.png').Count) {
    throw 'Existing audit captures found. Preserve them and use a measurement-only run, or explicitly archive them before a new capture run.'
}
$previousAppData = $env:APPDATA
$started = Get-Date
try {
    $env:APPDATA = Join-Path $out 'profile'
    New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
    $shim = (Get-Command godot-gui.cmd -ErrorAction Stop).Source
    $match = [regex]::Match([IO.File]::ReadAllText($shim), '(?m)^"([^"\r\n]+\.exe)"')
    if (!$match.Success -or !(Test-Path -LiteralPath $match.Groups[1].Value)) { throw 'Cannot resolve the installed godot-gui.cmd executable.' }
    $command = $match.Groups[1].Value
    $arguments = '--path "' + $repo + '" --rendering-method gl_compatibility --resolution 1920x1080 --max-fps 30 res://tools/tests/AndroidTouchAuditTest.tscn -- --mobile-touch-ui'
    if ($Capture) { $arguments += ' --capture' }
    # Direct GUI executable avoids the console shim's second Godot process.
    $process = Start-Process -FilePath $command -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $out 'run.log') -RedirectStandardError (Join-Path $out 'stderr.log')
    [void]$process.Handle
    $maxProcesses = 0
    $deadline = (Get-Date).AddMinutes(5)
    while (!$process.WaitForExit(250)) {
        $count = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*godot*' }).Count
        $maxProcesses = [Math]::Max($maxProcesses, $count)
        if ($count -gt 1) { Stop-Process -Id $process.Id; throw 'More than one Godot process detected.' }
        if ((Get-Date) -gt $deadline) { Stop-Process -Id $process.Id; throw 'Audit exceeded five minutes.' }
    }
    $process.WaitForExit()
    $engineExit = $process.ExitCode
    @{ before = 0; maximum = $maxProcesses; after = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*godot*' }).Count; exit_code = $engineExit } | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $out 'process_counts.json')
    if ($engineExit -ne 0) { throw "Android audit exited $engineExit. See tmp/android_audit/run.log" }
    $resultFile = Join-Path $out 'audit.json'
    if (!(Test-Path -LiteralPath $resultFile) -or (Get-Item -LiteralPath $resultFile).LastWriteTime -lt $started) { throw 'Fresh audit.json was not produced.' }
    $result = Get-Content -Raw -Encoding UTF8 -LiteralPath $resultFile | ConvertFrom-Json
    if ($result.failures.Count) { throw ($result.failures -join '; ') }
    Write-Output "AndroidTouchAuditTest PASS: $($result.screens.Count) states; $($result.checks) checks; $($result.captures.Count) captures."
} finally {
    $env:APPDATA = $previousAppData
    $remaining = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*godot*' })
    if ($remaining.Count) { throw 'Godot is still running after the audit. Check the owned audit process before continuing.' }
}
