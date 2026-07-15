[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PipelineArgs
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$venvPython = Join-Path $repoRoot "tmp\lyria_audio_venv\Scripts\python.exe"
$pipeline = Join-Path $PSScriptRoot "lyria_pipeline.py"

if (-not (Test-Path -LiteralPath $venvPython)) {
    throw "Lyria environment is missing. Run tools/audio/setup_lyria.ps1 first."
}

$temporaryKey = $false
$isPaidExecution = ($PipelineArgs -contains "generate") -and ($PipelineArgs -contains "--execute")
if ($isPaidExecution -and [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
    $secureKey = Read-Host "Gemini API key (used only by this process)" -AsSecureString
    $keyPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    try {
        $env:GEMINI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPointer)
        $temporaryKey = $true
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer)
    }
}

try {
    & $venvPython $pipeline @PipelineArgs
    exit $LASTEXITCODE
}
finally {
    if ($temporaryKey) {
        Remove-Item Env:GEMINI_API_KEY -ErrorAction SilentlyContinue
    }
}
