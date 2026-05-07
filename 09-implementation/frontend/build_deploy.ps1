# build_deploy.ps1 — Build Flutter web + deploy lên Cloudflare Pages
# Usage: .\build_deploy.ps1
# Requires: flutter, wrangler (npm i -g wrangler)

$API_BASE = "https://ptit-contest-mobile-app-production.up.railway.app"
$PROJECT  = "ptit-contest-app"

Write-Host "=== Flutter clean ===" -ForegroundColor Cyan
flutter clean

Write-Host "=== Flutter build web ===" -ForegroundColor Cyan
flutter build web `
  --dart-define=API_BASE=$API_BASE `
  --release

if ($LASTEXITCODE -ne 0) {
  Write-Host "Build FAILED" -ForegroundColor Red
  exit 1
}

Write-Host "=== Wrangler deploy ===" -ForegroundColor Cyan
wrangler pages deploy build/web --project-name=$PROJECT --branch=main

if ($LASTEXITCODE -ne 0) {
  Write-Host "Deploy FAILED" -ForegroundColor Red
  exit 1
}

Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Production: https://ptit-contest-app.pages.dev"
