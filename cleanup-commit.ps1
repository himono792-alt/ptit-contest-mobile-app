# cleanup-commit.ps1 -- commit dot don dep folder 2026-06-11 (ASCII only)
# Chay tu PowerShell tai root repo:  .\cleanup-commit.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# 1. Xoa index.lock cu (sandbox de lai) -- chi xoa khi khong co git dang chay
if (Test-Path .git\index.lock) {
    if (-not (Get-Process git -ErrorAction SilentlyContinue)) {
        Remove-Item .git\index.lock -Force
        Write-Host "Removed stale .git\index.lock"
    } else { Write-Host "git dang chay -- bo qua xoa lock"; exit 1 }
}

# 2. Sync submodule theo .gitmodules da fix path
git submodule sync

# 3. Stage toan bo (git tu detect rename, giu history)
git add -A

# 4. Tom tat truoc khi commit
git status --short | Select-Object -First 40
$total = (git status --porcelain | Measure-Object -Line).Lines
Write-Host ""
Write-Host "--- Tong so thay doi: $total ---"
Write-Host ""

# 5. Commit
$msg = @"
chore: don dep + tai cau truc folder du an

- Xoa 2 repo _tmp (1.7GB), build artifacts, 7 hotfix scripts, 5 folder rong
- 11-docs chia subfolder: deliverables/ audits/ sprints/ roadmap/
- Version cu (traceability v01-v02, sqlapp v01-v03, mockup v01, bao cao v01) -> 99-archive/
- Gop docs/ vao 11-docs/roadmap/, xoa folder docs/
- Fix .gitmodules path submodule: 11-docs/skills -> 06-design-system/skills
- Cap nhat link trong README x3 + frontend CLAUDE.md
"@
git commit -m $msg

Write-Host ""
Write-Host "DONE. Kiem tra roi push:  git push origin main"
