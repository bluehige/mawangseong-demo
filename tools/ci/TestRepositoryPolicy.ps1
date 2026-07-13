[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$policySource = Join-Path $PSScriptRoot "ValidateRepositoryPolicy.ps1"
$shellPath = (Get-Process -Id $PID).Path
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) (
    "mawangseong-policy-tests-" + [guid]::NewGuid().ToString("N")
)

function Invoke-Git {
    param(
        [string]$Repository,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    Push-Location $Repository
    try {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $output = @(& git @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousPreference
        if ($exitCode -ne 0) {
            throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
        }
        return $output
    } finally {
        Pop-Location
    }
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $crlf = ([string][char]13) + ([char]10)
    $cr = [string][char]13
    $lf = [string][char]10
    $normalized = $Content.Replace($crlf, $lf).Replace($cr, $lf)
    $normalized = $normalized.TrimEnd([char[]]@([char]13, [char]10)) + $lf
    [IO.File]::WriteAllText(
        $Path,
        $normalized,
        [Text.UTF8Encoding]::new($false)
    )
}

function New-PolicyFixture {
    param([string]$Name)

    $repository = Join-Path $tempRoot $Name
    New-Item -ItemType Directory -Force -Path $repository | Out-Null
    Invoke-Git $repository init --initial-branch=main | Out-Null
    Invoke-Git $repository config core.autocrlf false | Out-Null
    Invoke-Git $repository config user.email policy-tests@example.invalid | Out-Null
    Invoke-Git $repository config user.name "Repository Policy Tests" | Out-Null

    Write-TextFile (Join-Path $repository "AGENTS.md") "# Test working agreement"
    Write-TextFile (
        Join-Path $repository "docs/GIT_VERSIONING_WORKFLOW.md"
    ) "# Test workflow"
    Write-TextFile (
        Join-Path $repository "docs/handoff/CURRENT.md"
    ) "# Test current handoff"
    Write-TextFile (
        Join-Path $repository "docs/handoff/HANDOFF_TEMPLATE.md"
    ) "# Test handoff template"
    New-Item -ItemType Directory -Force -Path (
        Join-Path $repository "tools/ci"
    ) | Out-Null
    Copy-Item -LiteralPath $policySource -Destination (
        Join-Path $repository "tools/ci/ValidateRepositoryPolicy.ps1"
    )

    Invoke-Git $repository add AGENTS.md docs tools | Out-Null
    Invoke-Git $repository commit -m "test: create policy fixture" | Out-Null
    $baseOutput = @(Invoke-Git $repository rev-parse HEAD)
    $base = [string]$baseOutput[-1]
    return [PSCustomObject]@{
        Repository = $repository
        Base = $base
    }
}

function Add-ReviewedHandoff {
    param(
        [object]$Fixture,
        [string]$ReviewSha,
        [string]$RangeBase = ""
    )

    if (-not $RangeBase) {
        $RangeBase = $Fixture.Base
    }
    $content = @"
# Policy test handoff

- Review task ID: NOT_REQUESTED
- Reviewed SHA: $ReviewSha
- Review range: $RangeBase..$ReviewSha
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
"@
    Write-TextFile (
        Join-Path $Fixture.Repository "docs/handoff/POLICY_TEST_2026-07-13.md"
    ) $content
    Invoke-Git $Fixture.Repository add docs/handoff/POLICY_TEST_2026-07-13.md | Out-Null
    Invoke-Git $Fixture.Repository commit -m "docs: add reviewed handoff" | Out-Null
}

function Commit-ReviewTarget {
    param(
        [object]$Fixture,
        [string]$Message
    )

    $currentPath = Join-Path $Fixture.Repository "docs/handoff/CURRENT.md"
    $currentContent = [IO.File]::ReadAllText($currentPath).TrimEnd()
    Write-TextFile $currentPath (
        $currentContent + ([string][char]10) + "Updated by $Message."
    )
    Invoke-Git $Fixture.Repository add docs/handoff/CURRENT.md | Out-Null
    foreach ($path in @("scripts", "assets")) {
        if (Test-Path -LiteralPath (Join-Path $Fixture.Repository $path)) {
            Invoke-Git $Fixture.Repository add $path | Out-Null
        }
    }
    Invoke-Git $Fixture.Repository commit -m $Message | Out-Null
    $reviewOutput = @(Invoke-Git $Fixture.Repository rev-parse HEAD)
    return [string]$reviewOutput[-1]
}

function Invoke-Policy {
    param([object]$Fixture)

    Push-Location $Fixture.Repository
    try {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $output = @(& $shellPath -NoProfile -File tools/ci/ValidateRepositoryPolicy.ps1 -BaseRef $Fixture.Base -HeadRef codex/policy-test 2>&1)
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousPreference
        return [PSCustomObject]@{
            ExitCode = $exitCode
            Output = $output -join [Environment]::NewLine
        }
    } finally {
        Pop-Location
    }
}

function Assert-PolicyPass {
    param(
        [string]$Name,
        [object]$Result
    )

    if ($Result.ExitCode -ne 0) {
        throw "$Name should pass, but failed: $($Result.Output)"
    }
    if ($Result.Output -notmatch 'REPOSITORY_POLICY: PASS') {
        throw "$Name did not emit a PASS marker: $($Result.Output)"
    }
    Write-Host "PASS: $Name"
}

function Assert-PolicyFailure {
    param(
        [string]$Name,
        [object]$Result,
        [string]$ExpectedMessage
    )

    if ($Result.ExitCode -eq 0) {
        throw "$Name should fail, but passed: $($Result.Output)"
    }
    $expectedPattern = (($ExpectedMessage -split '\s+' | ForEach-Object {
        [regex]::Escape($_)
    }) -join '\s+')
    if ($Result.Output -notmatch $expectedPattern) {
        throw "$Name failed for the wrong reason: $($Result.Output)"
    }
    Write-Host "PASS: $Name"
}

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    $valid = New-PolicyFixture "valid-handoff"
    Write-TextFile (
        Join-Path $valid.Repository "scripts/feature.gd"
    ) "extends Node"
    $validReview = Commit-ReviewTarget $valid "feat: add reviewed feature"
    Add-ReviewedHandoff $valid $validReview
    Assert-PolicyPass "valid reviewed handoff" (Invoke-Policy $valid)

    $merged = New-PolicyFixture "merge-commit"
    Invoke-Git $merged.Repository checkout -b codex/reviewed-feature | Out-Null
    Write-TextFile (
        Join-Path $merged.Repository "scripts/feature.gd"
    ) "extends Node"
    $mergedReview = Commit-ReviewTarget $merged "feat: add merge-reviewed feature"
    Add-ReviewedHandoff $merged $mergedReview
    Invoke-Git $merged.Repository checkout main | Out-Null
    Invoke-Git $merged.Repository merge --no-ff codex/reviewed-feature -m "Merge reviewed feature" | Out-Null
    Assert-PolicyPass "reviewed merge commit lineage" (Invoke-Policy $merged)

    $intermediate = New-PolicyFixture "intermediate-artifact"
    Write-TextFile (
        Join-Path $intermediate.Repository "dist/game.pck"
    ) "generated build"
    Invoke-Git $intermediate.Repository add dist/game.pck | Out-Null
    Invoke-Git $intermediate.Repository commit -m "test: add hidden build" | Out-Null
    Invoke-Git $intermediate.Repository rm dist/game.pck | Out-Null
    Invoke-Git $intermediate.Repository commit -m "test: remove hidden build" | Out-Null
    Write-TextFile (
        Join-Path $intermediate.Repository "scripts/feature.gd"
    ) "extends Node"
    $intermediateReview = Commit-ReviewTarget $intermediate "feat: add feature"
    Add-ReviewedHandoff $intermediate $intermediateReview
    Assert-PolicyFailure (
        "intermediate binary artifact"
    ) (Invoke-Policy $intermediate) "binary build artifact extension is not allowed"

    $missingSource = New-PolicyFixture "missing-image-source"
    Write-TextFile (
        Join-Path $missingSource.Repository "assets/sprites/new_monster.png"
    ) "image"
    $missingSourceReview = Commit-ReviewTarget $missingSource "art: add unmapped image"
    Add-ReviewedHandoff $missingSource $missingSourceReview
    Assert-PolicyFailure (
        "image without source metadata"
    ) (Invoke-Policy $missingSource) "image changes require a changed"

    $deceptiveSource = New-PolicyFixture "deceptive-image-source"
    Write-TextFile (
        Join-Path $deceptiveSource.Repository "assets/sprites/actual_monster.png"
    ) "actual runtime image"
    Write-TextFile (
        Join-Path $deceptiveSource.Repository "assets/sprites/decoy_monster.png"
    ) "decoy runtime image"
    Write-TextFile (
        Join-Path $deceptiveSource.Repository "assets/source/imagegen/deceptive/source.png"
    ) "decoy source image"
    $deceptiveMetadata = @"
# Deceptive image source

- Generation model: GPT internal image generation
- Generated date: 2026-07-13
- Target version: v0.4
- Source image path: assets/source/imagegen/deceptive/source.png
- Runtime image path: assets/sprites/decoy_monster.png

The real changed file is assets/sprites/actual_monster.png.
"@
    Write-TextFile (
        Join-Path $deceptiveSource.Repository "assets/source/imagegen/deceptive/SOURCE.md"
    ) $deceptiveMetadata
    $deceptiveReview = Commit-ReviewTarget $deceptiveSource "art: add deceptive mapping"
    Add-ReviewedHandoff $deceptiveSource $deceptiveReview
    Assert-PolicyFailure (
        "image path mentioned outside mapping fields"
    ) (Invoke-Policy $deceptiveSource) "changed image is not mapped by a SOURCE.md path field"

    $mappedImage = New-PolicyFixture "mapped-image"
    Write-TextFile (
        Join-Path $mappedImage.Repository "assets/sprites/new_monster.png"
    ) "runtime image"
    Write-TextFile (
        Join-Path $mappedImage.Repository "assets/source/imagegen/new_monster/source.png"
    ) "source image"
    $sourceMetadata = @"
# New monster image source

- Generation model: GPT internal image generation
- Generated date: 2026-07-13
- Target version: v0.4
- Source image path: assets/source/imagegen/new_monster/source.png
- Runtime image path: assets/sprites/new_monster.png
"@
    Write-TextFile (
        Join-Path $mappedImage.Repository "assets/source/imagegen/new_monster/SOURCE.md"
    ) $sourceMetadata
    $mappedImageReview = Commit-ReviewTarget $mappedImage "art: add mapped image"
    Add-ReviewedHandoff $mappedImage $mappedImageReview
    Assert-PolicyPass "image with exact source mapping" (Invoke-Policy $mappedImage)

    $invalidRange = New-PolicyFixture "invalid-review-range"
    Write-TextFile (
        Join-Path $invalidRange.Repository "scripts/feature.gd"
    ) "extends Node"
    $invalidRangeReview = Commit-ReviewTarget $invalidRange "feat: add range test"
    Add-ReviewedHandoff $invalidRange $invalidRangeReview ("b" * 40)
    Assert-PolicyFailure (
        "handoff with false review range"
    ) (Invoke-Policy $invalidRange) "session handoff must record a coherent"

    Write-Host "REPOSITORY_POLICY_TESTS: PASS (7 scenarios)"
} finally {
    $resolvedRoot = [IO.Path]::GetFullPath($tempRoot)
    $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $leaf = Split-Path -Leaf $resolvedRoot
    if (
        $resolvedRoot.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -and
        $leaf -like "mawangseong-policy-tests-*"
    ) {
        Remove-Item -LiteralPath $resolvedRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
