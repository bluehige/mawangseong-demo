[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$venvRoot = Join-Path $repoRoot "tmp\lyria_audio_venv"
$venvPython = Join-Path $venvRoot "Scripts\python.exe"
$requirements = Join-Path $PSScriptRoot "requirements-lyria.txt"
$pipeline = Join-Path $PSScriptRoot "lyria_pipeline.py"

if (-not (Test-Path -LiteralPath $venvPython)) {
    python -m venv $venvRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Lyria virtual environment creation failed."
    }
}

& $venvPython -m pip install --disable-pip-version-check -r $requirements
if ($LASTEXITCODE -ne 0) {
    throw "Lyria dependency installation failed."
}

& $venvPython $pipeline validate
if ($LASTEXITCODE -ne 0) {
    throw "Lyria manifest validation failed."
}

& $venvPython $pipeline doctor
exit $LASTEXITCODE
