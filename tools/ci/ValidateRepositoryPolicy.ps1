[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseRef,

    [string]$HeadRef = ""
)

$ErrorActionPreference = "Stop"

function Fail-Policy([string]$Message) {
    Write-Error "REPOSITORY_POLICY: FAIL - $Message"
    exit 1
}

function Invoke-GitProbe {
    param([string[]]$Arguments)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output = $output
    }
}

function Convert-NameStatusLines {
    param(
        [object[]]$Lines,
        [string]$Commit = ""
    )

    $parsed = @()
    foreach ($lineValue in $Lines) {
        $line = [string]$lineValue
        if (-not $line) {
            continue
        }

        $parts = @($line -split [char]9)
        $status = $parts[0]
        if ($status -match '^[RC]') {
            if ($parts.Count -lt 3) {
                Fail-Policy "invalid rename/copy record: $line"
            }
            $paths = @($parts[1], $parts[2])
        } else {
            if ($parts.Count -lt 2) {
                Fail-Policy "invalid name-status record: $line"
            }
            $paths = @($parts[1])
        }

        $parsed += [PSCustomObject]@{
            Commit = $Commit
            Status = $status
            Paths = $paths
        }
    }
    return $parsed
}

function Assert-NoGeneratedArtifacts {
    param([object[]]$Records)

    $blockedPathPattern = '^(tmp/|output/|builds/|web_Demo/)'
    $blockedExtensionPattern = '\.(pck|wasm|exe|zip|7z|rar|msi|dmg|apk|aab)$'

    foreach ($record in $Records) {
        $kind = $record.Status.Substring(0, 1)
        $commitSuffix = if ($record.Commit) { " in commit $($record.Commit)" } else { "" }

        if ($kind -match '^[AMCT]$') {
            $path = $record.Paths[-1]
            if ($path -match $blockedPathPattern) {
                Fail-Policy "generated or exported file must not be added or modified$($commitSuffix): $path"
            }
            if ($path -match $blockedExtensionPattern) {
                Fail-Policy "binary build artifact extension is not allowed in Git$($commitSuffix): $path"
            }
            continue
        }

        if ($kind -eq 'R') {
            $oldPath = $record.Paths[0]
            $newPath = $record.Paths[1]
            if ($newPath -match $blockedPathPattern) {
                Fail-Policy "file must not be renamed into a generated or exported path$($commitSuffix): $newPath"
            }
            if ($newPath -match $blockedExtensionPattern) {
                Fail-Policy "binary build artifact extension is not allowed in Git$($commitSuffix): $newPath"
            }
            if ($oldPath -match $blockedPathPattern) {
                $approvedImagegenMigration =
                    $oldPath -match '^output/imagegen/' -and
                    $newPath -match '^assets/source/imagegen/'
                if (-not $approvedImagegenMigration) {
                    Fail-Policy "generated files may only be deleted; output/imagegen may move to assets/source/imagegen$($commitSuffix): $oldPath -> $newPath"
                }
            }
        }
    }
}

$requiredFiles = @(
    "AGENTS.md",
    "docs/GIT_VERSIONING_WORKFLOW.md",
    "docs/handoff/CURRENT.md",
    "docs/handoff/HANDOFF_TEMPLATE.md"
)

foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail-Policy "required file is missing: $path"
    }
}

if ($HeadRef -and $HeadRef -notmatch '^(main$|codex/|release/v\d+\.\d+(?:$|[-/])|test/|hotfix/v\d+\.\d+\.\d+(?:$|[-/])|v\.\d+$|dependabot/)') {
    Fail-Policy "branch name is outside the allowed patterns: $HeadRef"
}

$baseProbe = Invoke-GitProbe -Arguments @("cat-file", "-e", "$BaseRef^{commit}")
if ($baseProbe.ExitCode -ne 0) {
    Fail-Policy "base ref cannot be resolved: $BaseRef"
}

$range = "$BaseRef...HEAD"
$finalNameStatusLines = @(git diff --name-status --find-renames $range)
if ($LASTEXITCODE -ne 0) {
    Fail-Policy "failed to list changed paths for $range"
}
$finalRecords = @(Convert-NameStatusLines -Lines $finalNameStatusLines)
$finalChangedFiles = @(
    $finalRecords |
        ForEach-Object { $_.Paths } |
        Sort-Object -Unique
)

$commits = @(git rev-list --reverse "$BaseRef..HEAD")
if ($LASTEXITCODE -ne 0) {
    Fail-Policy "failed to list commits for $BaseRef..HEAD"
}
$historyRecords = @()
foreach ($commit in $commits) {
    $commitLines = @(git diff-tree --no-commit-id --name-status -r --root --find-renames $commit)
    if ($LASTEXITCODE -ne 0) {
        Fail-Policy "failed to inspect commit: $commit"
    }
    $historyRecords += @(Convert-NameStatusLines -Lines $commitLines -Commit $commit)
}
$historyChangedFiles = @(
    $historyRecords |
        ForEach-Object { $_.Paths } |
        Sort-Object -Unique
)

$diffCheck = @(git diff --check $range 2>&1)
if ($LASTEXITCODE -ne 0) {
    $diffCheck | ForEach-Object { Write-Host $_ }
    Fail-Policy "git diff --check failed"
}

Assert-NoGeneratedArtifacts -Records $historyRecords

$statePathPattern = '^(scripts/|data/|assets/|scenes/|tools/|\.github/workflows/|project\.godot$|export_presets\.cfg$)'
$changesRepositoryState = $null -ne (
    $historyChangedFiles |
        Where-Object { $_ -match $statePathPattern } |
        Select-Object -First 1
)
if ($changesRepositoryState -and $finalChangedFiles -notcontains "docs/handoff/CURRENT.md") {
    Fail-Policy "code, data, asset, scene, tool, or workflow changes require docs/handoff/CURRENT.md"
}

if ($changesRepositoryState) {
    $sessionPattern = '^docs/handoff/(?!CURRENT\.md$)(?!HANDOFF_TEMPLATE\.md$)[^/]+_\d{4}-\d{2}-\d{2}\.md$'
    $sessionHandoffs = @(
        $finalChangedFiles |
            Where-Object {
                $_ -match $sessionPattern -and
                (Test-Path -LiteralPath $_ -PathType Leaf)
            }
    )
    if ($sessionHandoffs.Count -eq 0) {
        Fail-Policy "repository state changes require a dated session handoff"
    }

    $approvedHandoff = ""
    foreach ($handoff in $sessionHandoffs) {
        $content = Get-Content -Raw -Encoding utf8 -LiteralPath $handoff
        $idMatch = [regex]::Match($content, '(?m)^- Review task ID:\s*(?!PENDING|NONE|N/A)(\S.*)$')
        $shaMatch = [regex]::Match($content, '(?m)^- Reviewed SHA:\s*([0-9a-f]{40})\s*$')
        $rangeMatch = [regex]::Match($content, '(?m)^- Review range:\s*([0-9a-f]{40})\.\.([0-9a-f]{40})\s*$')
        $p12Match = [regex]::Match($content, '(?m)^- Remaining P1/P2:\s*0\s*$')
        $resultMatch = [regex]::Match($content, '(?m)^- Final review result:\s*PASS\s*$')
        if (-not ($idMatch.Success -and $shaMatch.Success -and $rangeMatch.Success -and $p12Match.Success -and $resultMatch.Success)) {
            continue
        }

        $reviewSha = $shaMatch.Groups[1].Value
        $rangeBase = $rangeMatch.Groups[1].Value
        $rangeHead = $rangeMatch.Groups[2].Value
        if ($rangeHead -ne $reviewSha) {
            continue
        }
        $reviewProbe = Invoke-GitProbe -Arguments @("cat-file", "-e", "$reviewSha^{commit}")
        if ($reviewProbe.ExitCode -ne 0) {
            continue
        }
        $rangeBaseProbe = Invoke-GitProbe -Arguments @("cat-file", "-e", "$rangeBase^{commit}")
        if ($rangeBaseProbe.ExitCode -ne 0) {
            continue
        }
        $rangeAncestorProbe = Invoke-GitProbe -Arguments @(
            "merge-base",
            "--is-ancestor",
            $rangeBase,
            $reviewSha
        )
        if ($rangeAncestorProbe.ExitCode -ne 0) {
            continue
        }
        $expectedBaseProbe = Invoke-GitProbe -Arguments @(
            "merge-base",
            $BaseRef,
            $reviewSha
        )
        if ($expectedBaseProbe.ExitCode -ne 0) {
            continue
        }
        $expectedRangeBase = (
            [string]($expectedBaseProbe.Output | Select-Object -Last 1)
        ).Trim()
        if ($rangeBase -ne $expectedRangeBase) {
            continue
        }
        $reviewAncestorProbe = Invoke-GitProbe -Arguments @(
            "merge-base",
            "--is-ancestor",
            $reviewSha,
            "HEAD"
        )
        if ($reviewAncestorProbe.ExitCode -ne 0) {
            continue
        }
        $postReviewChanges = @(git diff --name-only "$reviewSha..HEAD")
        $invalidPostReview = $postReviewChanges |
            Where-Object { $_ -notmatch '^docs/handoff/' } |
            Select-Object -First 1
        if ($invalidPostReview) {
            continue
        }
        $approvedHandoff = $handoff
        break
    }
    if (-not $approvedHandoff) {
        Fail-Policy "session handoff must record a valid review ID, range, reviewed SHA, zero P1/P2 findings, and PASS; only handoff files may change after the reviewed SHA"
    }
}

$activeImagePaths = @(
    $finalRecords |
        Where-Object {
            $_.Status -notmatch '^D' -and
            $_.Paths[-1] -match '^assets/.+\.(png|jpe?g|webp|gif)$'
        } |
        ForEach-Object { $_.Paths[-1] } |
        Sort-Object -Unique
)
if ($activeImagePaths.Count -gt 0) {
    $sourceDocs = @(
        $finalChangedFiles |
            Where-Object {
                $_ -match '^assets/source/imagegen/[^/]+/SOURCE\.md$' -and
                (Test-Path -LiteralPath $_ -PathType Leaf)
            }
    )
    if ($sourceDocs.Count -eq 0) {
        Fail-Policy "image changes require a changed assets/source/imagegen/<asset>/SOURCE.md"
    }

    $pathOwners = @{}
    foreach ($sourceDoc in $sourceDocs) {
        $content = Get-Content -Raw -Encoding utf8 -LiteralPath $sourceDoc
        if ($content -notmatch '(?m)^- Generation model:\s*GPT internal image generation\s*$') {
            Fail-Policy "image generation model is missing or invalid: $sourceDoc"
        }
        if ($content -notmatch '(?m)^- Generated date:\s*\d{4}-\d{2}-\d{2}\s*$') {
            Fail-Policy "image generation date is missing or invalid: $sourceDoc"
        }
        if ($content -notmatch '(?m)^- Target version:\s*v\d+\.\d+(?:\.\d+)?\s*$') {
            Fail-Policy "image target version is missing or invalid: $sourceDoc"
        }

        $sourcePathMatches = [regex]::Matches(
            $content,
            '(?m)^- Source image path:\s*(assets/source/imagegen/\S+\.(?:png|jpe?g|webp|gif))\s*$'
        )
        $runtimePathMatches = [regex]::Matches(
            $content,
            '(?m)^- Runtime image path:\s*(assets/\S+\.(?:png|jpe?g|webp|gif))\s*$'
        )
        if ($sourcePathMatches.Count -eq 0 -or $runtimePathMatches.Count -eq 0) {
            Fail-Policy "image source and runtime path fields are required: $sourceDoc"
        }

        $sourceDirectory = (Split-Path -Parent $sourceDoc).Replace("\", "/") + "/"
        foreach ($match in $sourcePathMatches) {
            $declaredPath = $match.Groups[1].Value
            if (-not $declaredPath.StartsWith($sourceDirectory, [StringComparison]::Ordinal)) {
                Fail-Policy "source image must be inside its SOURCE.md directory: $declaredPath"
            }
            if (-not (Test-Path -LiteralPath $declaredPath -PathType Leaf)) {
                Fail-Policy "declared source image does not exist: $declaredPath"
            }
            if (-not $pathOwners.ContainsKey($declaredPath)) {
                $pathOwners[$declaredPath] = @()
            }
            $pathOwners[$declaredPath] = @($pathOwners[$declaredPath]) + $sourceDoc
        }
        foreach ($match in $runtimePathMatches) {
            $declaredPath = $match.Groups[1].Value
            if ($declaredPath -match '^assets/source/') {
                Fail-Policy "runtime image must be outside assets/source: $declaredPath"
            }
            if (-not (Test-Path -LiteralPath $declaredPath -PathType Leaf)) {
                Fail-Policy "declared runtime image does not exist: $declaredPath"
            }
            if (-not $pathOwners.ContainsKey($declaredPath)) {
                $pathOwners[$declaredPath] = @()
            }
            $pathOwners[$declaredPath] = @($pathOwners[$declaredPath]) + $sourceDoc
        }
    }

    foreach ($imagePath in $activeImagePaths) {
        if (-not $pathOwners.ContainsKey($imagePath)) {
            Fail-Policy "changed image is not mapped by a SOURCE.md path field: $imagePath"
        }
        if (@($pathOwners[$imagePath]).Count -ne 1) {
            Fail-Policy "changed image must have exactly one SOURCE.md path mapping: $imagePath"
        }
    }
}

Write-Host "REPOSITORY_POLICY: PASS ($($finalChangedFiles.Count) final files, $($commits.Count) commits inspected)"
