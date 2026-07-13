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

git rev-parse --verify "$BaseRef^{commit}" | Out-Null
if ($LASTEXITCODE -ne 0) {
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
        $rangeMatch = [regex]::Match($content, '(?m)^- Review range:\s*(\S.*)$')
        $p12Match = [regex]::Match($content, '(?m)^- Remaining P1/P2:\s*0\s*$')
        $resultMatch = [regex]::Match($content, '(?m)^- Final review result:\s*PASS\s*$')
        if (-not ($idMatch.Success -and $shaMatch.Success -and $rangeMatch.Success -and $p12Match.Success -and $resultMatch.Success)) {
            continue
        }

        $reviewSha = $shaMatch.Groups[1].Value
        git cat-file -e "$reviewSha^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) {
            continue
        }
        git merge-base --is-ancestor $reviewSha HEAD
        if ($LASTEXITCODE -ne 0) {
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

    $sourceContents = @{}
    foreach ($sourceDoc in $sourceDocs) {
        $content = Get-Content -Raw -Encoding utf8 -LiteralPath $sourceDoc
        $requiredMetadata = @(
            '(?m)^- Generation model:\s*GPT internal image generation\s*$',
            '(?m)^- Generated date:\s*\d{4}-\d{2}-\d{2}\s*$',
            '(?m)^- Target version:\s*v\d+\.\d+(?:\.\d+)?\s*$',
            '(?m)^- Source image path:\s*assets/source/imagegen/\S+\s*$',
            '(?m)^- Runtime image path:\s*assets/\S+\s*$'
        )
        foreach ($pattern in $requiredMetadata) {
            if ($content -notmatch $pattern) {
                Fail-Policy "image provenance metadata is incomplete: $sourceDoc"
            }
        }
        $sourceContents[$sourceDoc] = $content
    }

    foreach ($imagePath in $activeImagePaths) {
        $escapedPath = [regex]::Escape($imagePath)
        $matchingSource = $sourceDocs |
            Where-Object { $sourceContents[$_] -match $escapedPath } |
            Select-Object -First 1
        if (-not $matchingSource) {
            Fail-Policy "changed image is not mapped by a changed SOURCE.md: $imagePath"
        }
    }
}

Write-Host "REPOSITORY_POLICY: PASS ($($finalChangedFiles.Count) final files, $($commits.Count) commits inspected)"
