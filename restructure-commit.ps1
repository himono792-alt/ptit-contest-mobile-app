# restructure-commit.ps1 -- commit tai cau truc product-first 2026-06-11 (ASCII only)
# Chay tu PowerShell tai root repo:  .\restructure-commit.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# 0. Don tan du (non-fatal): folder rong dang bi session Cowork giu handle --
# git KHONG track folder rong nen skip van commit duoc; xoa sau khi dong session.
try {
    if (Test-Path 09-implementation) { Remove-Item 09-implementation -Recurse -Force -ErrorAction Stop }
} catch { Write-Host "WARN: 09-implementation dang bi khoa -- bo qua, xoa sau khi dong session Cowork" }
try {
    if (Test-Path cleanup-commit.ps1) { Remove-Item cleanup-commit.ps1 -Force -ErrorAction Stop }
} catch { Write-Host "WARN: khong xoa duoc cleanup-commit.ps1 -- bo qua" }

# 1. Xoa stale index.lock neu co
if (Test-Path .git\index.lock) {
    if (-not (Get-Process git -ErrorAction SilentlyContinue)) {
        Remove-Item .git\index.lock -Force
        Write-Host "Removed stale .git\index.lock"
    } else { Write-Host "git dang chay -- thoat"; exit 1 }
}

# 2. Submodule path moi (docs/design/design-system/skills/ui-ux-pro-max-skill)
git submodule sync

# 3. Stage + tom tat
git add -A
$total = (git status --porcelain | Measure-Object -Line).Lines
Write-Host "--- Tong thay doi: $total dong status ---"

# 4. Commit
$msg = @"
refactor: tai cau truc repo product-first

- backend/ frontend/ docker-compose.yml len root -> clone xong 'docker compose up -d' ngay
- Tai lieu hoc thuat vao docs/ (requirements/research/architecture/design/deliverables/audits/sprints/roadmap)
- 08-database -> database/, 99-archive -> archive/
- Sua refs path trong 17 file (README x3, CLAUDE.md, CONTRIBUTING x2, SETUP, scripts, runbook, checklist, .gitmodules)
- README: mermaid architecture + tech stack cap nhat theo Docker local
"@
git commit -m $msg

Write-Host ""
Write-Host "DONE. Tiep theo:"
Write-Host "  1. git push origin main"
Write-Host "  2. GitHub -> Settings -> rename repo thanh: ptit-contest (tu redirect URL cu)"
Write-Host "  3. (tuy chon, cho sach) git remote set-url origin https://github.com/<user>/ptit-contest.git"
Write-Host "  4. docker compose up -d --build   (chay tai root, verify stack len binh thuong)"
Write-Host "  5. Xoa script nay: Remove-Item restructure-commit.ps1"
