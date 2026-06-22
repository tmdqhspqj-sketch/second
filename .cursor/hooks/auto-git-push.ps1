$ErrorActionPreference = "SilentlyContinue"

# Cursor hook: auto commit + push when agent session ends
$null = [Console]::In.ReadToEnd()

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root

if (-not (Test-Path ".git")) {
    exit 0
}

$changes = git status --porcelain
if (-not $changes) {
    exit 0
}

git add -A

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$message = "Auto sync: $timestamp"

git -c user.name="tmdqhspqj-sketch" -c user.email="tmdqhspqj-sketch@users.noreply.github.com" commit -m $message
if ($LASTEXITCODE -ne 0) {
    exit 0
}

$branch = git rev-parse --abbrev-ref HEAD
if (-not $branch) {
    $branch = "main"
}

git push origin $branch
exit 0
