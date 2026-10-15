param([string[]]$Tests = @('AndroidLifecycleTest', 'V130SavePlotTest', 'V1213StageOneTest'))
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$out = Join-Path $repo 'tmp/android_build'
New-Item -ItemType Directory -Force $out | Out-Null
$shim = (Get-Command godot-gui.cmd -ErrorAction Stop).Source
$match = [regex]::Match([IO.File]::ReadAllText($shim), '(?m)^"([^"\r\n]+\.exe)"')
if (!$match.Success) { throw 'Cannot resolve installed Godot executable.' }
$command = $match.Groups[1].Value
$previousAppData = $env:APPDATA
$results = @()
try {
    foreach ($test in $Tests) {
        $profileRoot = $out
        if ($test -eq 'V1213StageOneTest') { $profileRoot = Join-Path $repo 'tmp/v1213_s1/android_build' }
        $env:APPDATA = Join-Path $profileRoot ('profiles/continuity_review/' + $test + '/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
        New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
        if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count) { throw 'Godot must be stopped before each test.' }
        $history = Join-Path $out ('history/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
        foreach ($suffix in @('.log', '.stderr.log')) {
            $old = Join-Path $out ($test + $suffix)
            if (Test-Path -LiteralPath $old) {
                New-Item -ItemType Directory -Force $history | Out-Null
                Copy-Item -LiteralPath $old -Destination $history
            }
        }
        $scene = 'res://tools/tests/' + $test + '.tscn'
        if (!(Test-Path -LiteralPath (Join-Path $repo ('tools/tests/' + $test + '.tscn')))) { $scene = 'res://tools/' + $test + '.tscn' }
        $arguments = '--headless --path "' + $repo + '" ' + $scene
        $process = Start-Process -FilePath $command -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $out "$test.log") -RedirectStandardError (Join-Path $out "$test.stderr.log")
        [void]$process.Handle
        $maximum = 1
        $deadline = (Get-Date).AddMinutes(4)
        while (!$process.WaitForExit(250)) {
            $count = @(Get-Process *godot* -ErrorAction SilentlyContinue).Count
            $maximum = [Math]::Max($maximum, $count)
            if ($count -gt 1 -or (Get-Date) -gt $deadline) {
                Stop-Process -Id $process.Id
                throw "Process count or deadline exceeded: $test"
            }
        }
        $process.WaitForExit()
        $after = @(Get-Process *godot* -ErrorAction SilentlyContinue).Count
        $results += @{ test = $test; exit_code = $process.ExitCode; before = 0; maximum = $maximum; after = $after }
        $results | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $out 'test_process_counts.json')
        if ($process.ExitCode -ne 0 -or $after) { throw "$test failed; see tmp/android_build/$test.log and .stderr.log" }
        Write-Output "$test PASS (Godot 0 -> $maximum -> $after)"
    }
} finally {
    $env:APPDATA = $previousAppData
}
