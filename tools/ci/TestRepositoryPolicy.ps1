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

function Add-MinimalHandoff {
    param(
        [object]$Fixture,
        [string]$Content = ""
    )

    if (-not $Content) {
        $Content = @"
# Policy test handoff

- Related tests: repository policy self-test
- UI check: no UI changes
- Unresolved issues: none
"@
    }
    Write-TextFile (
        Join-Path $Fixture.Repository "docs/handoff/POLICY_TEST_2026-07-13.md"
    ) $Content
    Invoke-Git $Fixture.Repository add docs/handoff/POLICY_TEST_2026-07-13.md | Out-Null
    Invoke-Git $Fixture.Repository commit -m "docs: add minimal handoff" | Out-Null
}

function Commit-StateChange {
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
}

function Invoke-Policy {
    param(
        [object]$Fixture,
        [string]$HeadRef = "codex/policy-test",
        [switch]$AllowWebDemoArtifacts
    )

    Push-Location $Fixture.Repository
    try {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $arguments = @(
            "-NoProfile",
            "-File",
            "tools/ci/ValidateRepositoryPolicy.ps1",
            "-BaseRef",
            $Fixture.Base,
            "-HeadRef",
            $HeadRef
        )
        if ($AllowWebDemoArtifacts.IsPresent) {
            $arguments += "-AllowWebDemoArtifacts"
        }
        $output = @(& $shellPath @arguments 2>&1)
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
    $ansiPattern = "$([char]27)\[[0-?]*[ -/]*[@-~]"
    $normalizedOutput = (($Result.Output -replace $ansiPattern, '') -replace '\s+', ' ').Trim()
    $cursor = 0
    $messageFound = $true
    foreach ($token in ($ExpectedMessage -split '\s+')) {
        $index = $normalizedOutput.IndexOf($token, $cursor, [StringComparison]::Ordinal)
        if ($index -lt 0) {
            $messageFound = $false
            break
        }
        $cursor = $index + $token.Length
    }
    if (-not $messageFound) {
        throw "$Name failed for the wrong reason: $($Result.Output)"
    }
    Write-Host "PASS: $Name"
}

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    $valid = New-PolicyFixture "valid-minimal-handoff"
    Write-TextFile (
        Join-Path $valid.Repository "scripts/feature.gd"
    ) "extends Node"
    Commit-StateChange $valid "feat: add feature"
    Add-MinimalHandoff $valid
    Assert-PolicyPass "valid minimal handoff" (Invoke-Policy $valid)

    $merged = New-PolicyFixture "merge-commit"
    Invoke-Git $merged.Repository checkout -b codex/policy-feature | Out-Null
    Write-TextFile (
        Join-Path $merged.Repository "scripts/feature.gd"
    ) "extends Node"
    Commit-StateChange $merged "feat: add merge feature"
    Add-MinimalHandoff $merged
    Invoke-Git $merged.Repository checkout main | Out-Null
    Invoke-Git $merged.Repository merge --no-ff codex/policy-feature -m "Merge policy feature" | Out-Null
    Assert-PolicyPass "merge commit with minimal handoff" (Invoke-Policy $merged)

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
    Commit-StateChange $intermediate "feat: add feature"
    Add-MinimalHandoff $intermediate
    Assert-PolicyFailure (
        "intermediate binary artifact"
    ) (Invoke-Policy $intermediate) "binary build artifact extension is not allowed"

    $webDemo = New-PolicyFixture "web-demo-artifact"
    Invoke-Git $webDemo.Repository checkout -b test/web-policy | Out-Null
    Write-TextFile (
        Join-Path $webDemo.Repository "web_Demo/index.html"
    ) "web demo"
    Write-TextFile (
        Join-Path $webDemo.Repository "web_Demo/index.pck"
    ) "web pack"
    Invoke-Git $webDemo.Repository add web_Demo | Out-Null
    Invoke-Git $webDemo.Repository commit -m "build: export web demo" | Out-Null
    Assert-PolicyFailure (
        "web demo without explicit branch allowance"
    ) (
        Invoke-Policy $webDemo -HeadRef "test/web-policy"
    ) "generated or exported file must not be added or modified"
    Assert-PolicyPass (
        "web demo on test web push"
    ) (
        Invoke-Policy $webDemo -HeadRef "test/web-policy" -AllowWebDemoArtifacts
    )

    $missingSource = New-PolicyFixture "missing-image-source"
    Write-TextFile (
        Join-Path $missingSource.Repository "assets/sprites/new_monster.png"
    ) "image"
    Commit-StateChange $missingSource "art: add unmapped image"
    Add-MinimalHandoff $missingSource
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
    Commit-StateChange $deceptiveSource "art: add deceptive mapping"
    Add-MinimalHandoff $deceptiveSource
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
    Commit-StateChange $mappedImage "art: add mapped image"
    Add-MinimalHandoff $mappedImage
    Assert-PolicyPass "image with exact source mapping" (Invoke-Policy $mappedImage)

    $incompleteHandoff = New-PolicyFixture "incomplete-minimal-handoff"
    Write-TextFile (
        Join-Path $incompleteHandoff.Repository "scripts/feature.gd"
    ) "extends Node"
    Commit-StateChange $incompleteHandoff "feat: add incomplete handoff test"
    $incompleteContent = @"
# Policy test handoff

- Related tests: repository policy self-test
- UI check: no UI changes
"@
    Add-MinimalHandoff $incompleteHandoff $incompleteContent
    Assert-PolicyFailure (
        "handoff missing minimal verification field"
    ) (Invoke-Policy $incompleteHandoff) "session handoff must record minimal verification fields"

    Write-Host "REPOSITORY_POLICY_TESTS: PASS (9 scenarios)"
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

exit 0
