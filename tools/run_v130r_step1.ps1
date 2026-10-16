param()
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (@(Get-Process *godot* -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'Close the existing Godot process first. This preview allows one Godot process.'
}
$taskWrapper = Get-Content -LiteralPath (Get-Command godot.cmd -ErrorAction Stop).Source -Raw
$taskExe = [regex]::Match($taskWrapper, '"([^"\r\n]+\.exe)"').Groups[1].Value -replace '_console\.exe$', '.exe'
if (-not (Test-Path -LiteralPath $taskExe -PathType Leaf)) { throw 'Godot GUI executable from godot.cmd was not found.' }
$taskAppData = $env:APPDATA
$taskLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $taskRoot 'tmp/v130r_step1/manual_appdata'
    $env:LOCALAPPDATA = Join-Path $taskRoot 'tmp/v130r_step1/manual_localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    # Visible interactive window is the purpose of this manual preview command.
    $taskPreview = Start-Process -FilePath $taskExe -WorkingDirectory $taskRoot -WindowStyle Normal -PassThru -ArgumentList '--path . --rendering-method gl_compatibility --resolution 1920x1080 --max-fps 60 --scene res://scenes/map_builder/ApprovedMapPreview.tscn'
    Wait-Process -Id $taskPreview.Id
} finally {
    $env:APPDATA = $taskAppData
    $env:LOCALAPPDATA = $taskLocalData
}
