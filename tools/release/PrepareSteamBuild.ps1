[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$')]
    [string]$Version,

    [string]$GodotPath = 'godot',

    [string]$OutputRoot = '',

    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$workingTreeChanges = @(git -C $repoRoot status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect the Git working tree.'
}
if ($workingTreeChanges.Count -gt 0) {
    throw 'Release builds require a clean Git working tree. Commit or stash the intended source first.'
}
$projectPath = Join-Path $repoRoot 'project.godot'
$projectText = Get-Content -LiteralPath $projectPath -Encoding utf8 -Raw
$versionMatch = [regex]::Match($projectText, '(?m)^config/version="([^"]+)"\r?$')
if (-not $versionMatch.Success) {
    throw 'project.godot config/version is missing.'
}
if ($versionMatch.Groups[1].Value -ne $Version) {
    throw "Requested version $Version does not match project.godot version $($versionMatch.Groups[1].Value)."
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $repoRoot "builds/steam/windows/v$Version"
}
$outputFull = [System.IO.Path]::GetFullPath($OutputRoot)
$managedRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'builds/steam/windows'))

if (Test-Path -LiteralPath $outputFull) {
    $hasFiles = @(Get-ChildItem -LiteralPath $outputFull -Force -ErrorAction SilentlyContinue).Count -gt 0
    if ($hasFiles -and -not $Clean) {
        throw "Output directory is not empty. Pass -Clean to replace it: $outputFull"
    }
    if ($hasFiles -and $Clean) {
        $isManagedPath = $outputFull.StartsWith(
            $managedRoot + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase
        )
        if (-not $isManagedPath) {
            throw "-Clean is only allowed below the managed build root: $managedRoot"
        }
        Remove-Item -LiteralPath $outputFull -Recurse -Force
    }
}
New-Item -ItemType Directory -Path $outputFull -Force | Out-Null

$godotCommand = Get-Command $GodotPath -ErrorAction SilentlyContinue
if ($null -eq $godotCommand) {
    throw "Godot executable was not found: $GodotPath"
}
$godotExecutable = $godotCommand.Source
$executablePath = Join-Path $outputFull 'MawangCastle.exe'

& $godotExecutable --headless --path $repoRoot --import
if ($LASTEXITCODE -ne 0) {
    throw "Godot project import failed with exit code $LASTEXITCODE."
}

& $godotExecutable --headless --path $repoRoot --export-release 'Windows Steam' $executablePath
if ($LASTEXITCODE -ne 0) {
    throw "Godot Steam export failed with exit code $LASTEXITCODE."
}

$requiredRuntime = @(
    'MawangCastle.exe',
    'MawangCastle.pck'
)
foreach ($relative in $requiredRuntime) {
    if (-not (Test-Path -LiteralPath (Join-Path $outputFull $relative) -PathType Leaf)) {
        throw "Godot export did not create required runtime file: $relative"
    }
}

$licenseDir = Join-Path $outputFull 'licenses'
New-Item -ItemType Directory -Path $licenseDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $repoRoot 'legal/THIRD_PARTY_NOTICES.txt') -Destination (Join-Path $outputFull 'THIRD_PARTY_NOTICES.txt')
Copy-Item -LiteralPath (Join-Path $repoRoot 'assets/fonts/NotoSansCJK_LICENSE.txt') -Destination (Join-Path $licenseDir 'NotoSansCJK_LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $repoRoot 'assets/fonts/NEXON_Maplestory_LICENSE.txt') -Destination (Join-Path $licenseDir 'NEXON_Maplestory_LICENSE.txt')

$sourceCommit = (git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $sourceCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'Could not determine the source commit SHA.'
}
$manifestPath = Join-Path $outputFull 'steam-build-manifest.json'
$outputPrefix = $outputFull.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar
$artifacts = @()
Get-ChildItem -LiteralPath $outputFull -File -Recurse |
    Where-Object { $_.FullName -ne $manifestPath } |
    Sort-Object FullName |
    ForEach-Object {
        if (-not $_.FullName.StartsWith($outputPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Build artifact escaped the output root: $($_.FullName)"
        }
        $relative = $_.FullName.Substring($outputPrefix.Length).Replace('\', '/')
        $artifacts += [ordered]@{
            path = $relative
            bytes = $_.Length
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }
$manifest = [ordered]@{
    schema_version = 1
    version = $Version
    tag = "v$Version"
    source_commit = $sourceCommit
    godot_version = (& $godotExecutable --version).Trim()
    built_at_utc = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    artifacts = $artifacts
}
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$manifestJson = $manifest | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText(
    $manifestPath,
    $manifestJson + [Environment]::NewLine,
    $utf8NoBom
)

python (Join-Path $PSScriptRoot 'validate_steam_release.py') --build-dir $outputFull
if ($LASTEXITCODE -ne 0) {
    throw 'Steam depot validation failed.'
}

Write-Output "STEAM_BUILD: PASS $outputFull"
