[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$LogPath,
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
    if ($LogPath) {
        $logFile = [IO.Path]::GetFullPath($LogPath)
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
        # Only subprocess output is logged; Read-Host is outside this pipeline.
        # Native stderr must reach the redactor even on Windows PowerShell 5.1.
        $savedErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            & $venvPython $pipeline @PipelineArgs 2>&1 | ForEach-Object {
                $line = [string]$_
                if ($env:GEMINI_API_KEY) {
                    $line = $line.Replace($env:GEMINI_API_KEY, "[REDACTED]")
                }
                $line = $line -replace 'AIza[0-9A-Za-z_-]{30,}', '[REDACTED]'
                Write-Host $line
                Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
            }
        }
        finally {
            $ErrorActionPreference = $savedErrorAction
        }
    }
    else {
        & $venvPython $pipeline @PipelineArgs
    }
    exit $LASTEXITCODE
}
finally {
    if ($temporaryKey) {
        Remove-Item Env:GEMINI_API_KEY -ErrorAction SilentlyContinue
    }
}
