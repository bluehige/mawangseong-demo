[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BuildDir,

    [Parameter(Mandatory = $true)]
    [string]$SteamUser,

    [string]$SteamworksSdkPath = '',

    [string]$Description = '',

    [string]$SetLive = '',

    [switch]$Preview,

    [switch]$GenerateOnly
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$configPath = Join-Path $repoRoot 'steam/release_config.json'
$config = Get-Content -LiteralPath $configPath -Encoding utf8 -Raw | ConvertFrom-Json
$appId = [int64]$config.product.app_id
$depotId = [int64]$config.product.windows_depot_id
if ($appId -le 0 -or $depotId -le 0) {
    throw 'Replace app_id and windows_depot_id in steam/release_config.json before generating an upload.'
}
if ([string]::IsNullOrWhiteSpace($SteamUser)) {
    throw 'A dedicated Steam build account name is required.'
}

$contentRoot = (Resolve-Path -LiteralPath $BuildDir).Path
python (Join-Path $PSScriptRoot 'validate_steam_release.py') --build-dir $contentRoot
if ($LASTEXITCODE -ne 0) {
    throw 'Steam depot validation failed before VDF generation.'
}

$manifest = Get-Content -LiteralPath (Join-Path $contentRoot 'steam-build-manifest.json') -Encoding utf8 -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($Description)) {
    $Description = "$($manifest.tag) $($manifest.source_commit.Substring(0, 12))"
}
if ($Description.Contains('"') -or $Description.Contains("`r") -or $Description.Contains("`n")) {
    throw 'Description may not contain quotes or newlines.'
}
if ($SetLive -eq 'default') {
    throw 'The upload script never sets the default branch live. Use Steamworks after testing.'
}
if ($SetLive -and $SetLive -notmatch '^[A-Za-z0-9_-]+$') {
    throw 'SetLive beta branch contains unsupported characters.'
}

$workRoot = Join-Path $repoRoot 'tmp/steamworks'
$scriptsDir = Join-Path $workRoot 'scripts'
$outputDir = Join-Path $workRoot 'output'
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

function ConvertTo-VdfPath([string]$Path) {
    return $Path.Replace('\', '/').Replace('"', '\"')
}

$contentVdf = ConvertTo-VdfPath $contentRoot
$outputVdf = ConvertTo-VdfPath $outputDir
$previewLine = if ($Preview) { '    "Preview" "1"' } else { '' }
$setLiveLine = if ($SetLive) { "    `"SetLive`" `"$SetLive`"" } else { '' }
$vdfPath = Join-Path $scriptsDir "app_build_$appId.vdf"
$vdf = @"
"AppBuild"
{
    "AppID" "$appId"
    "Desc" "$Description"
$previewLine
$setLiveLine
    "ContentRoot" "$contentVdf"
    "BuildOutput" "$outputVdf"
    "Depots"
    {
        "$depotId"
        {
            "FileMapping"
            {
                "LocalPath" "*"
                "DepotPath" "."
                "Recursive" "1"
            }
            "FileExclusion" "steam_appid.txt"
            "FileExclusion" "*.pdb"
        }
    }
}
"@
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($vdfPath, $vdf + [Environment]::NewLine, $utf8NoBom)
Write-Output "STEAMPIPE_VDF: $vdfPath"

if ($GenerateOnly) {
    Write-Output 'STEAMPIPE: GENERATED_ONLY (no network call)'
    exit 0
}
if ([string]::IsNullOrWhiteSpace($SteamworksSdkPath)) {
    throw 'SteamworksSdkPath is required unless -GenerateOnly is used.'
}
$steamCmd = Join-Path ([System.IO.Path]::GetFullPath($SteamworksSdkPath)) 'tools/ContentBuilder/builder/steamcmd.exe'
if (-not (Test-Path -LiteralPath $steamCmd -PathType Leaf)) {
    throw "steamcmd.exe was not found at $steamCmd"
}

# Passwords and Steam Guard codes are intentionally omitted. Bootstrap this
# dedicated account interactively once so SteamCMD can reuse its login token.
& $steamCmd +login $SteamUser +run_app_build $vdfPath +quit
if ($LASTEXITCODE -ne 0) {
    throw "SteamPipe upload failed with exit code $LASTEXITCODE. Check $outputDir logs."
}
Write-Output 'STEAMPIPE: UPLOAD_PASS (build was not set live on the default branch)'
