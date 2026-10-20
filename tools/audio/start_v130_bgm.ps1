[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$manifestPath = Join-Path $PSScriptRoot "lyria_v130_manifest.json"
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$takes = [int]$manifest.defaults.takes
$requests = $manifest.assets.Count * $takes
$cost = 0.0
foreach ($asset in $manifest.assets) {
    $cost += [double]$manifest.models.($asset.model).usd_per_request * $takes
}
if ($manifest.target_version -ne "v1.3.0" -or $manifest.assets.Count -ne 15 -or $takes -ne 1) {
    throw "Expected the approved v1.3.0 manifest with 15 tracks and one take."
}
$costText = $cost.ToString("F2", [Globalization.CultureInfo]::InvariantCulture)
$logFile = [IO.Path]::GetFullPath($LogPath)
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
function Write-RunLine([string]$Line) {
    Write-Host $Line
    Add-Content -LiteralPath $logFile -Value $Line -Encoding UTF8
}
Write-RunLine "=== $([DateTime]::UtcNow.ToString('o')) BGM v1.3.0 launcher ==="
Write-RunLine "tracks=15 takes=1 requests=$requests estimated_cost_usd=$costText"
Write-Host "BGM 1.3.0: $($manifest.assets.Count) tracks, $requests requests, estimated USD $costText."
Write-Host "Estimate uses the local manifest rate; verify billing before proceeding."
Write-Host "Y starts dependency setup and PAID Gemini Lyria generation. Other input cancels."
$answer = Read-Host "Continue? [Y]"
if ($answer.Trim() -ine "Y") {
    Write-RunLine "Cancelled. No setup or generation was started."
    exit 0
}

# The BAT opens an isolated host: do not inherit a saved key; ask securely in run_lyria.
Remove-Item Env:GEMINI_API_KEY -ErrorAction SilentlyContinue
$powershellExe = Join-Path $PSHOME "powershell.exe"
$runId = "v130-" + [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssfffZ")
Write-RunLine "=== $([DateTime]::UtcNow.ToString('o')) BGM v1.3.0 start ==="
Write-RunLine "tracks=15 takes=1 requests=$requests estimated_cost_usd=$costText run_id=$runId"
Write-RunLine "manifest=$manifestPath"
try {
    Push-Location $repoRoot
    Write-RunLine "stage=setup"
    $ErrorActionPreference = "Continue"
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "setup_lyria.ps1") 2>&1 |
        ForEach-Object { Write-RunLine ([string]$_) }
    $setupExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($setupExit -ne 0) { throw "Dependency setup failed (exit=$setupExit). Generation was not started." }

    Write-RunLine "stage=generate (secure key prompt is not logged)"
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_lyria.ps1") `
        -LogPath $logFile --manifest $manifestPath generate --all --takes 1 --run-id $runId --execute
    $generateExit = $LASTEXITCODE
    Write-RunLine "stage=generate exit=$generateExit run=tmp/lyria_audio_v130/$runId"
    if ($generateExit -ne 0) { throw "Generation failed. Keep partial sources; do not rerun all tracks blindly." }
    Write-RunLine "SUCCESS: source and preview candidates ready. Listening, promotion and playlist wiring remain."
}
catch {
    Write-RunLine "FAILED: $($_.Exception.Message)"
    exit 1
}
finally {
    Pop-Location
}
exit 0
