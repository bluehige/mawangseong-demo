param([string]$Profile = 'gallery')
$ErrorActionPreference = 'Stop'
if ($Profile -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple profile name.' }
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskOutput = Join-Path $taskRoot "tmp/v1213_u4/$Profile"
New-Item -ItemType Directory -Force (Join-Path $taskOutput 'profile') | Out-Null
$previousAppData = $env:APPDATA
Push-Location $taskRoot
try {
    $env:APPDATA = Join-Path $taskOutput 'profile'
    & godot --path . --rendering-method gl_compatibility --resolution 1920x1080 res://tools/ui_kit/KitGallery.tscn -- "--kit-out=tmp/v1213_u4/$Profile" *> (Join-Path $taskOutput 'render.log')
    if ($LASTEXITCODE -ne 0) { throw "Gallery renderer failed: $LASTEXITCODE" }
    if (Select-String -Path (Join-Path $taskOutput 'render.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'Gallery render log contains errors.' }
    & python tools/ux_audit/scan.py --kit-gallery "tmp/v1213_u4/$Profile"
    if ($LASTEXITCODE -ne 0) { throw 'Gallery scanner failed.' }
    & python tools/ui_kit/compare.py "tmp/v1213_u4/$Profile"
    if ($LASTEXITCODE -ne 0) { throw 'Gallery comparison failed.' }
} finally {
    $env:APPDATA = $previousAppData
    Pop-Location
}
