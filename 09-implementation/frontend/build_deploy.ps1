# build_deploy.ps1 — Build Flutter web + deploy lên Cloudflare Pages
# Usage: .\build_deploy.ps1
# Requires: flutter, wrangler (npm i -g wrangler)

$API_BASE = "https://ptit-contest-mobile-app-production.up.railway.app"
$PROJECT  = "ptit-contest-app"

Write-Host "=== Flutter clean ===" -ForegroundColor Cyan
flutter clean

Write-Host "=== Flutter build web ===" -ForegroundColor Cyan
# Sprint 13 Batch A (2026-05-08): tree-shake-icons giảm bundle ~25-30%
# (loại các MaterialIcons không dùng — đa số IconData unused). main.dart.js từ
# ~2.94 MB → ~2.0-2.2 MB. Mặc định Flutter web KHÔNG tree-shake icons.
# Source maps off để bundle nhỏ hơn (đã default off ở release).
flutter build web `
  --dart-define=API_BASE=$API_BASE `
  --tree-shake-icons `
  --release

if ($LASTEXITCODE -ne 0) {
  Write-Host "Build FAILED" -ForegroundColor Red
  exit 1
}

Write-Host "=== Wrangler deploy ===" -ForegroundColor Cyan
# --commit-dirty=true: skip warning về uncommitted changes (Sprint 7 2026-05-07).
wrangler pages deploy build/web --project-name=$PROJECT --branch=main --commit-dirty=true

if ($LASTEXITCODE -ne 0) {
  Write-Host "Deploy FAILED" -ForegroundColor Red
  exit 1
}

Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Production: https://ptit-contest-app.pages.dev"
