# design_lint.ps1
# Design system lint cho CNPM Flutter app.
# Scope: lib/features/**/*.dart (lib/core/ excluded — token definitions live there).
# Run:   pwsh tool/design_lint.ps1            (verbose default)
#        pwsh tool/design_lint.ps1 -Quiet     (count only, dùng cho CI)
# Exit:  0 = PASS (no violations), 1 = FAIL, 2 = setup error.

param([switch]$Quiet)

$Verbose = -not $Quiet
$ErrorActionPreference = 'Stop'

$ScriptRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$FrontendRoot = Split-Path -Parent $ScriptRoot
$FeaturesPath = Join-Path $FrontendRoot 'lib\features'

if (-not (Test-Path $FeaturesPath)) {
    Write-Error "lib/features not found at: $FeaturesPath"
    exit 2
}

$files = Get-ChildItem -Path $FeaturesPath -Filter '*.dart' -Recurse

Write-Host ""
Write-Host "============================================================"
Write-Host " DESIGN LINT - CNPM Flutter App"
Write-Host " Scope: lib/features/ ($($files.Count) files)"
Write-Host " Date:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "============================================================"

function Show-Result {
    param([string]$Name, [string]$Why, $Matches)
    $count = ($Matches | Measure-Object).Count
    Write-Host ""
    Write-Host "[$Name]" -ForegroundColor Cyan
    if ($count -eq 0) {
        Write-Host "  PASS - 0 violations" -ForegroundColor Green
    } else {
        Write-Host "  FAIL - $count violations" -ForegroundColor Yellow
        Write-Host "  Fix:  $Why" -ForegroundColor DarkGray
        if ($Verbose) {
            $shown = 0
            foreach ($line in $Matches) {
                if ($shown -ge 25) { break }
                $rel = $line.Path.Substring($FrontendRoot.Length + 1)
                Write-Host "    $rel`:$($line.LineNumber)" -ForegroundColor DarkGray
                $shown++
            }
            if ($count -gt 25) {
                Write-Host "    ... ($($count - 25) more lines hidden)" -ForegroundColor DarkGray
            }
        }
    }
    return $count
}

$total = 0

# 1. Raw hex Color(0xFF...) trong features/
$m = $files | Select-String -Pattern 'Color\(0xFF[0-9A-Fa-f]{6}\)'
$total += Show-Result `
    '1. Raw hex Color(0xFF...) in features/' `
    'Use context.appBg / textPrimary / cardBorder / ... extension (lib/core/app_colors.dart)' `
    $m

# 2. Off-scale EdgeInsets (not 4/8/12/16/24/32/48/64)
$m = $files | Select-String -Pattern 'EdgeInsets\.\w+\([^)]*\b(3|5|6|7|9|10|11|13|14|17|18|19|21|22|23|26|30)\b'
$total += Show-Result `
    '2. Off-scale EdgeInsets (not 4/8/12/16/24/32)' `
    'Use AppSpacing.s4 / s8 / s12 / s16 / s24 / s32 / s48 / s64' `
    $m

# 3. Off-system BorderRadius (not 10/12/20, pill 99/999 OK)
$rawRadius = $files | Select-String -Pattern 'BorderRadius\.circular\((\d+)\)'
$mRadius = $rawRadius | Where-Object {
    $_.Matches[0].Groups[1].Value -notin @('4', '10', '12', '20', '99', '999')
}
$total += Show-Result `
    '3. Off-system BorderRadius (not 4/10/12/20, pill 99/999 OK)' `
    'Use AppRadius.tight (4) / sm (10) / md (12) / lg (20) / pill (999)' `
    $mRadius

# 4. Hard-coded TextStyle(fontSize: ...)
$m = $files | Select-String -Pattern 'TextStyle\([^)]*fontSize:'
$total += Show-Result `
    '4. Hard-coded TextStyle(fontSize:)' `
    'Use Theme.of(context).textTheme.xxx?.copyWith(color: ...)' `
    $m

# 5. Material Colors.X.shadeNNN / withOpacity drift
$m = $files | Select-String -Pattern 'Colors\.\w+\.(shade\d+|withOpacity)'
$total += Show-Result `
    '5. Material Colors.X.shadeNNN / withOpacity drift' `
    'Use context.warnOrange / textMuted / app palette tokens, hoặc .withValues(alpha:)' `
    $m

Write-Host ""
Write-Host "============================================================"
if ($total -eq 0) {
    Write-Host " RESULT: PASS - 0 violations" -ForegroundColor Green
    Write-Host "============================================================"
    exit 0
} else {
    Write-Host " RESULT: FAIL - $total total violations" -ForegroundColor Yellow
    Write-Host "============================================================"
    exit 1
}
