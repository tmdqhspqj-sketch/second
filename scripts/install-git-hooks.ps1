$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

$hookPath = Join-Path $Root ".git\hooks\post-commit"
$hookContent = @'
#!/bin/sh
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
if [ -n "$branch" ]; then
  git push origin "$branch" >/dev/null 2>&1 &
fi
'@

New-Item -ItemType Directory -Force -Path (Split-Path $hookPath) | Out-Null
Set-Content -Path $hookPath -Value $hookContent -NoNewline
Write-Host "Installed post-commit hook: git push after every commit"
