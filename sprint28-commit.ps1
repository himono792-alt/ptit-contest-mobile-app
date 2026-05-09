# Sprint 28 commit + push (3 commits chronological)
# Run từ E:\PARA\10-projects\12-cnpm-project (repo root)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "=== Sprint 28 commit + push ===" -ForegroundColor Cyan

# Clean up phantom git lock if any
if (Test-Path ".git\index.lock") {
    Write-Host "[cleanup] Removing phantom .git\index.lock" -ForegroundColor Yellow
    Remove-Item ".git\index.lock" -Force
}

$frontend = "09-implementation\frontend"
$loginScreen = "$frontend\lib\features\auth\login_screen.dart"
$backupFile = "$loginScreen.sprint28.bak"

# Sanity check
if (-not (Test-Path $backupFile)) {
    Write-Error "Missing backup: $backupFile. Cannot proceed."
    exit 1
}

# ============== Commit 1: Sprint 26 m_shimmer ==============
Write-Host "`n[1/3] Sprint 26 - Skeleton polish" -ForegroundColor Green
git add "$frontend\lib\core\widgets\m_shimmer.dart"

$msg26 = @'
feat(skeleton): theme-aware shimmer + stagger fade (Sprint 26)

- Theme-aware base/highlight (light E9ECEF/F6F7F9, dark 2A2724/3D3936)
- Period 1500 to 1200ms, stagger 80ms wave fade-in
- MediaQuery.disableAnimations fallback static pulse
- Bar radius 6, removed border noise
- Match modern apps (LinkedIn/Notion)

Deploy: 1e0c61a8
'@
git commit -m $msg26
if ($LASTEXITCODE -ne 0) { Write-Error "Sprint 26 commit failed"; exit 1 }

# ============== Commit 2: Sprint 27 login_screen ==============
Write-Host "`n[2/3] Sprint 27 - Login polish (BrandQuoteRotator + autofill)" -ForegroundColor Green
git add $loginScreen

$msg27 = @'
feat(login): branding quote rotator + role tab autofill (Sprint 27)

- Replace 4 fake stats with _BrandQuoteRotator (6 inspirational quotes)
- Authors: Lenin, Than Nhan Trung, Mandela, Franklin, Gandhi, B.B.King
- Auto-cycle 6s + indicator dots + fade transition
- _RoleTabs.onChanged auto-fill test creds for SV/GV/BCN/Admin tabs
- Removed _BrandStat helper class

Deploy: 97950086
'@
git commit -m $msg27
if ($LASTEXITCODE -ne 0) { Write-Error "Sprint 27 commit failed"; exit 1 }

# ============== Restore Sprint 28 portions to login_screen ==============
Write-Host "`n[restore] Sprint 28 portions" -ForegroundColor Yellow
Copy-Item $backupFile $loginScreen -Force

# ============== Commit 3: Sprint 28 ==============
Write-Host "`n[3/3] Sprint 28 - Split-outward animation + 4 nav hotfixes + lint chores" -ForegroundColor Green
git add -A

$msg28 = @'
fix(nav): split-outward animation + 4 navigation hotfixes (Sprint 28)

LOGIN SPLIT-OUTWARD ANIMATION (login_screen.dart):
- 750ms easeInOutCubic: 2 panels Transform.translate symmetric +/-w/2
- Mobile <900: fade-out + slide-up 10pct fallback
- Reveal placeholder logo PTIT + spinner match splash
- Bypass authProvider.login -> authService.login + ref.invalidate
- A11y: MediaQuery.disableAnimations skip animation

4 NAV HOTFIXES:
- #1 admin_shell.dart didUpdateWidget reset _initialApplied khi initialTab doi
- #2 build() fallback Dashboard khi initialTab=null (browser back)
- #3 router.dart allow-list 7 slug GV/BCN
  (gv-calendar/results/stats/export, bcn-cert-templates/stats/report-bgh)
- #4 router.dart splash preserve URL via ?to=encoded (F5 reload + deeplink)

LINT CHORES (13 files):
- unused imports, naming conventions, BuildContext.mounted
- doc comments, curly braces, library directive

E2E Chrome MCP 7/7 PASS. Deploy: 627e134a
'@
git commit -m $msg28
if ($LASTEXITCODE -ne 0) { Write-Error "Sprint 28 commit failed"; exit 1 }

# ============== Push main ==============
Write-Host "`n[push] origin main" -ForegroundColor Cyan
git push origin main
if ($LASTEXITCODE -ne 0) { Write-Error "Push failed"; exit 1 }

# ============== Cleanup ==============
Write-Host "`n[cleanup] Remove backup file" -ForegroundColor Yellow
Remove-Item $backupFile -Force

# ============== Verify ==============
Write-Host "`n=== Done! ===" -ForegroundColor Green
Write-Host "git log --oneline -5:" -ForegroundColor Cyan
git log --oneline -5
Write-Host "`ngit status:" -ForegroundColor Cyan
git status --short
