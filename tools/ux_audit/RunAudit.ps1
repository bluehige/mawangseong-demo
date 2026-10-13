param([string]$Profile = 'profile', [switch]$Resume, [switch]$Touch)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$evidence = Join-Path $repo 'tmp/v1213_uiux_audit'
$taskProfile = [IO.Path]::GetFullPath((Join-Path $evidence $Profile))
if (!$taskProfile.StartsWith($evidence + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Profile must stay inside audit evidence directory' }
New-Item -ItemType Directory -Force $taskProfile | Out-Null
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = $taskProfile
    $command = (Get-Command godot.cmd).Source
    $launch = Join-Path $taskProfile 'launch.cmd'
    $log = Join-Path $evidence ($Profile + '.log')
    $arguments = '--rendering-method gl_compatibility --path "' + $repo + '" --resolution 1920x1080 res://tools/ux_audit/Audit.tscn'
    if ($Resume -or $Touch) { $arguments += ' --' }
    if ($Resume) { $arguments += ' --resume-audit' }
    if ($Touch) { $arguments += ' --mobile-touch-ui' }
    [IO.File]::WriteAllText($launch, '@call "' + $command + '" ' + $arguments + ' > "' + $log + '" 2>&1', [Text.Encoding]::Default)
    $startedAt = [DateTime]::UtcNow
    $process = Start-Process -FilePath $env:ComSpec -ArgumentList @('/c', ('"' + $launch + '"')) -WindowStyle Hidden -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    $ready = Join-Path $evidence 'ready.json'
    do {
        Start-Sleep -Milliseconds 200
        if ($process.HasExited) { throw ('Audit exited before readiness. Inspect ' + $log) }
        if ([DateTime]::UtcNow -gt $deadline) { throw ('Audit readiness timeout. Inspect ' + $log) }
        $matchesProfile = $false
        if ((Test-Path -LiteralPath $ready) -and (Get-Item -LiteralPath $ready).LastWriteTimeUtc -ge $startedAt) {
            $state = Get-Content -Raw -Encoding UTF8 -LiteralPath $ready | ConvertFrom-Json
            $matchesProfile = $state.user_dir.Replace('/', '\').StartsWith($taskProfile + '\', [StringComparison]::OrdinalIgnoreCase)
        }
    } until ($matchesProfile)
    Write-Output ('Audit launcher PID: ' + $process.Id)
    Write-Output ('Isolated APPDATA: ' + $taskProfile)
    Write-Output ('Log: ' + $log)
} finally {
    $env:APPDATA = $previousAppData
}
