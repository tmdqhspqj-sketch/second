$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Starting Local LLM Agent ===" -ForegroundColor Cyan

try {
    $null = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3
} catch {
    Write-Host "Ollama is not running. Start the Ollama app first." -ForegroundColor Red
    exit 1
}

$venvPython = Join-Path $Root "backend\.venv\Scripts\python.exe"
$backendDir = Join-Path $Root "backend"
$frontendDir = Join-Path $Root "frontend"

Push-Location $backendDir
& $venvPython -m scripts.seed_sample 2>$null
Pop-Location

Write-Host "Backend:  http://localhost:8000" -ForegroundColor Green
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Green
Write-Host "API docs: http://localhost:8000/docs" -ForegroundColor Green

Start-Process powershell -ArgumentList @(
    "-NoExit", "-Command",
    "Set-Location '$backendDir'; & '$venvPython' -m uvicorn app.main:app --reload --port 8000"
)

Start-Sleep -Seconds 2

Start-Process powershell -ArgumentList @(
    "-NoExit", "-Command",
    "Set-Location '$frontendDir'; npm run dev"
)

Write-Host "Open http://localhost:3000 in your browser."
