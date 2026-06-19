$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Local LLM Agent Setup ===" -ForegroundColor Cyan

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "Ollama not found. Install from https://ollama.com/download" -ForegroundColor Red
    exit 1
}

Write-Host "`n[1/4] Checking Ollama models..." -ForegroundColor Yellow
$models = ollama list 2>&1
Write-Host $models

$hasLlm = $models -match "local-agent|gemma4"
$hasEmbed = $models -match "embeddinggemma|nomic-embed"

if (-not $hasLlm) {
    Write-Host "Pulling gemma4:e4b..." -ForegroundColor Yellow
    ollama pull gemma4:e4b
}
if (-not $hasEmbed) {
    Write-Host "Pulling embeddinggemma..." -ForegroundColor Yellow
    ollama pull embeddinggemma
}

Write-Host "`n[2/4] Installing Python packages..." -ForegroundColor Yellow
$venvPython = Join-Path $Root "backend\.venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    python -m venv (Join-Path $Root "backend\.venv")
}
& $venvPython -m pip install -q -r (Join-Path $Root "backend\requirements.txt")

Write-Host "`n[3/4] Checking frontend packages..." -ForegroundColor Yellow
Push-Location (Join-Path $Root "frontend")
if (-not (Test-Path "node_modules")) {
    npm install
}
Pop-Location

Write-Host "`n[4/4] Checking Ollama server..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
    Write-Host "Ollama server is running" -ForegroundColor Green
} catch {
    Write-Host "Start Ollama app first, then run start.ps1" -ForegroundColor Yellow
}

Write-Host "`nIndexing sample document..." -ForegroundColor Yellow
Push-Location (Join-Path $Root "backend")
try {
    & $venvPython -m scripts.seed_sample
} catch {
    Write-Host "Indexing skipped. Run start.ps1 after Ollama is up." -ForegroundColor Yellow
}
Pop-Location

Write-Host "`n=== Setup complete ===" -ForegroundColor Green
Write-Host "Run: .\start.ps1"
