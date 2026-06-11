# Design Audit — Flutter App PTIT Contest

**Ngày**: 2026-05-06
**Skill áp dụng**: `web-design-guidelines` (7 dimensions, severity-based)
**Phạm vi**: 33 file `.dart` trong `frontend/lib/features/` + 6 file widget shared trong `frontend/lib/core/widgets/`
**Baseline đối chiếu**: `frontend/lib/core/theme.dart`, `theme_dark.dart`, `app_colors.dart`

---

## TL;DR — Tình trạng tổng quan

| Mức | Số lượng | Đánh giá |
|---|---|---|
| Critical (chặn dark mode / phá theme) | **3 issues** | Cần fix trước khi demo dark mode |
| Major (drift rõ rệt, user nhận ra) | **5 issues** | Fix trong Phase 2 Sprint 2 |
| Minor (polish) | **6 issues** | Đưa vào backlog, fix dần |

**Verdict**: Theme system thiết kế đúng (tokens warm-leaning, dark mode hoàn chỉnh, helper `context.appBg/textPrimary/...`), nhưng **admin screens chưa migrate sang theme-aware tokens** — vẫn hard-code `Color(0xFFFAFAFA)` cho scaffold. Đây là di sản từ giai đoạn xây admin trước khi có theme-aware extension. Một sprint refactor 1-2 ngày sẽ giải quyết ~70% drift.

---

## CRITICAL — Phải fix trước

### C1. Admin scaffold hard-code `0xFFFAFAFA` (13 instances)

**Dimension**: Color
**Severity**: Critical — chặn hoàn toàn dark mode trên admin

**Chi tiết**: 13 file admin + 2 file student dùng `Color(0xFFFAFAFA)` cho `Scaffold.backgroundColor` thay vì `context.appBg`. Khi user bật dark mode, các screen này vẫn nền trắng → mismatch với app shell.

```
admin_shell.dart:303        admin_dashboard_screen.dart:36
admin_users_screen.dart:73   admin_contests_screen.dart:56
admin_shell.dart:303         master_data_screen.dart:40
review_moderation_screen.dart:90  configs_screen.dart:28
monitor_screen.dart:28       judge_screen.dart:28
audit_log_screen.dart:82     approval_queue_screen.dart:35
contest_admin_detail_screen.dart:129
submission_screen.dart:336 (student)
judge_screen.dart:362, approval_queue_screen.dart:167 (card-level)
```

**Fix**: Tìm-thay toàn bộ `const Color(0xFFFAFAFA)` → `context.appBg`. Bỏ `const` (vì context expression không phải compile-time const).

**Verify**: bật dark mode trong Profile → mọi admin screen phải đổi sang nền `appBgDark` (#1C1815).

### C2. Admin sidebar hard-code dark grays (admin_shell.dart)

**Dimension**: Color + Component consistency
**Severity**: Critical — sidebar không theme được

**Chi tiết**: `admin_shell.dart` dùng các giá trị Tailwind-Slate cho sidebar mà không qua theme:

```
admin_shell.dart:127  Color(0xFF1F2937)  bg sidebar dark
admin_shell.dart:135  Color(0xFF374151)  border
admin_shell.dart:163  Color(0xFF9CA3AF)  text muted
admin_shell.dart:192  Color(0xFFD1D5DB)  text active
admin_shell.dart:199  Color(0xFFD1D5DB)
admin_shell.dart:212  Color(0xFF374151)
admin_shell.dart:243  Color(0xFF9CA3AF)
admin_shell.dart:249  Color(0xFFD1D5DB)
admin_shell.dart:378  Color(0xFF1F2937)  drawer mobile
admin_shell.dart:407  Color(0xFF9CA3AF)
```

Toàn bộ sidebar bị "đóng băng" ở 1 màu, không adapt sang light theme nếu user thích.

**Fix**: 2 lựa chọn —
- (a) Cố tình giữ sidebar dark cả light/dark mode → di chuyển 4 màu này thành tokens trong `theme_dark.dart` (`sidebarBg`, `sidebarBorder`, `sidebarTextMuted`, `sidebarTextActive`) và document quyết định "sidebar luôn dark" trong code comment.
- (b) Theme-aware sidebar → bg dùng `cardBgDark` (dark mode) hoặc `Colors.white` + border `cardBorder` (light mode), text dùng `context.textMuted/Primary`.

Khuyến nghị **(a)** vì sidebar dark là design choice phổ biến cho admin UI; nhưng phải tokenize.

**Verify**: grep `admin_shell.dart` không còn raw `0xFF...` hex.

### C3. Năm grays nền phụ khác nhau cho cùng vai trò

**Dimension**: Color + Component consistency
**Severity**: Critical — design system vỡ

**Chi tiết**: 5 mã hex được dùng cho cùng vai trò "secondary background / row stripe / pill bg":

| Hex | Số file | Mục đích |
|---|---|---|
| `0xFFFAFAFA` | 13 | scaffold bg admin |
| `0xFFF9FAFB` | 5 | row bg trong DataTable (admin_users, admin_contests, master_data, configs, audit_log) |
| `0xFFF3F4F6` | 4 | pill bg (notifications, judge, contest_admin_detail x2) |
| `0xFFF1ECE5` | 3 | neutral stat bg (login, home, contest_list) |
| `0xFFF7F2EC` | 1 | pill bg (contest_list:333) |

5 màu này chỉ khác nhau 1-3 hex, mắt thường gần như không phân biệt được — nhưng tổng thể app cảm giác "lộn xộn" vì không bao giờ exactly match. Kèm theo: không cái nào theme-aware.

**Fix**: rút về 2 token —
- `surfaceMuted` → cho row stripe / scaffold (đề xuất `appBg` cho cả 2)
- `pillBg` → cho pill / chip (đề xuất `cardBorder` light + `cardBgDark` dark)

Định nghĩa 2 token mới trong `theme.dart` + `theme_dark.dart` + thêm vào `AppColors` extension.

**Verify**: grep `0xFFF[19A]` trả về 0 kết quả ngoài file theme.

---

## MAJOR — Drift rõ rệt, fix trong Phase 2 Sprint 2

### M1. Gradient `[ptitRed, 0xFFFF6B7E]` lặp 6 chỗ — chưa thành token

**Dimension**: Color
**Files**: `login_screen.dart:119`, `home_screen.dart:381`, `profile_screen.dart:43`, `contest_list_screen.dart:226`, `contest_detail_screen.dart:83`, `create_contest_dialog.dart:223`

**Chi tiết**: 6 file copy-paste cùng 1 gradient hero. Nếu cần đổi brand gradient (sau này, trong Phase 3 chẳng hạn), phải sửa 6 chỗ.

**Fix**: thêm `LinearGradient ptitGradientHero` vào `theme.dart`:
```dart
const LinearGradient ptitGradientHero = LinearGradient(
  colors: [ptitRed, Color(0xFFFF6B7E)],
);
```
Replace 6 instances.

### M2. 30+ TextStyle hard-code không qua `Theme.of(context).textTheme`

**Dimension**: Typography
**Severity**: Major

**Chi tiết**: theme.dart định nghĩa đầy đủ `textTheme` với 12 styles (bodyLarge/Medium/Small, titleLarge/Medium/Small, labelLarge/Medium/Small, headlineLarge/Medium/Small) nhưng nhiều screen vẫn:

```dart
TextStyle(fontSize: 11, color: context.textMuted)  // → labelSmall
TextStyle(fontSize: 13, color: context.textMuted, height: 1.5)  // → bodyMedium + height override
TextStyle(fontSize: 12)  // → labelMedium
```

**Files chính**:
- `monitor_screen.dart` (8 instances)
- `team_management_screen.dart` (8 instances)
- `my_registrations_screen.dart` (6 instances)
- `forgot_password_*` (3 instances)
- `review_moderation_screen.dart`, `login_screen.dart` (1-2 instances mỗi file)

**Fix**: thay `TextStyle(fontSize: 11, color: ...)` → `Theme.of(context).textTheme.labelSmall?.copyWith(color: ...)`. Giữ override khi cần thay đổi thuộc tính cụ thể.

**Edge cases**: `fontSize: 10` (3 chỗ trong `team_management_screen.dart`, `my_registrations_screen.dart`) — 10 không có trong type scale. Cân nhắc:
- Nâng lên 11 (labelSmall) → đồng bộ
- Hoặc thêm `labelTiny: 10/600` vào theme nếu thực sự cần size 10

### M3. Border radius 5/6/7/8/14/16 thay vì convention 10/12/20

**Dimension**: Component consistency
**Severity**: Major

**Chi tiết**: theme dùng 10 (snackBar), 12 (button/input), 20 (dialog). Nhưng screen code dùng:

| Radius | Số chỗ | Files mẫu |
|---|---|---|
| 8 | 14 | team_management, submission, register, notifications, home, login, admin_shell, judge, contest_admin_detail, forgot_password_reset |
| 14 | 4 | login_screen:121, home_screen:109/233/238 |
| 16 | 3 | contest_detail:85, forgot_password_reset:109, forgot_password_request:95 |
| 6 | 3 | approval_queue x2, admin_users:356 |
| 5 | 2 | monitor_screen:190/199 |
| 7 | 1 | admin_shell:142 |

Card cảm giác "không ổn định" vì mỗi nơi 1 radius.

**Fix**: gom về 2-3 giá trị —
- 10 cho card / pill / row stripe
- 12 cho button / input / interactive element (đã làm)
- 20 cho dialog / modal / hero card

Replace toàn bộ 8 → 10, 5/6/7 → 10, 14 → 12, 16 → 20.

### M4. `Colors.amber.shade600` thay vì `context.warnOrange`

**Dimension**: Color
**File**: `review_dialog.dart:137`

**Chi tiết**: Material `Colors.amber.shade600` (#FFB300) khác với `warnOrange` (#D97706) trong palette. User thấy 2 màu warning khác nhau giữa các dialog.

**Fix**: `Colors.amber.shade600` → `context.warnOrange`.

### M5. Loading indicator `Colors.white` cứng 8+ chỗ

**Dimension**: Component consistency + Interaction patterns
**Severity**: Major (chỉ visible khi user trong dark mode hoặc mạng chậm)

**Chi tiết**: `CircularProgressIndicator(color: Colors.white)` rải rác trong các button khi đang submit. Trên dark mode + button outline, spinner trắng vẫn OK; nhưng trong context khác (dialog dark, snackbar dark), trắng không phải lựa chọn đúng.

**Fix**: thay `Colors.white` → `Theme.of(context).colorScheme.onPrimary` (cho spinner trên filled button). Audit từng case.

---

## MINOR — Polish, đưa vào backlog

### m1. Off-scale spacing (10, 14, 18) — ~40 instances

**Dimension**: Spacing

10 không phải multiple của 4. 14 và 18 cũng off-scale.

**Phân loại**:
- Theme **đã** dùng `14h × 13v` cho input padding → 14 ở input là intentional
- 14 ở margin/padding ngoài input (admin_shell, student_shell line 251) → thay 14 → 16
- 10 (10+ chỗ): thay 10 → 8 hoặc 12 tùy ngữ cảnh
- 18 (admin_shell, admin_dashboard, review_moderation, admin_users): thay 18 → 16 hoặc 20

**Fix gradient strategy**: không cần fix toàn bộ một lần — sửa khi đụng vào file đó cho task khác.

### m2. `EdgeInsets.symmetric(vertical: 3)` và `vertical: 5/6`

**Dimension**: Spacing
**Files**: `team_management_screen.dart:356`, `cert_verify_screen.dart:241`, `login_screen.dart:385`, `my_registrations_screen.dart:71`

3, 5, 6 không trên scale 4. Thường xuất hiện trong micro-spacing (badge, pill nội bộ).

**Fix**: 3 → 4, 5 → 4 hoặc 8, 6 → 8.

### m3. Custom font `monospace` trong forgot_password_reset

**File**: `forgot_password_reset_screen.dart:139`
**Dimension**: Typography

`TextStyle(fontFamily: 'monospace', fontSize: 11)` — phá Plus Jakarta Sans. Nếu cần monospace cho OTP/code, ít nhất nên dùng `GoogleFonts.jetBrainsMono` để có fallback đẹp.

**Fix**: `GoogleFonts.jetBrainsMono(fontSize: 11)` hoặc xóa override này nếu không thực sự cần.

### m4. Pill background `0xFFF3F4F6` không theme-aware

**Files**: `notifications_screen.dart:262`, `judge_screen.dart:384`, `contest_admin_detail_screen.dart:213/219`
**Dimension**: Color

Đã gộp vào C3 nhưng vẫn để ở minor section vì impact thấp hơn (chỉ pill nội bộ, không phải scaffold).

### m5. Color drift cho gradient `0xFFFBBF24` / `0xFF60A5FA` / `0xFF94A3B8` trong contest_list

**File**: `contest_list_screen.dart:228-236`
**Dimension**: Color

Các contest type pills dùng gradient amber/blue/slate — không nằm trong palette. Nếu intent là phân biệt 3 loại contest qua màu thì cần thêm tokens `contestTypeIndividual/Team/Public` thay vì raw hex.

**Fix**: định nghĩa semantic tokens cho contest type colors trong theme.

### m6. Date format hardcoded ở nhiều chỗ

**Dimension**: Consistency (không thuộc 7 dimension chính, nhưng đáng lưu ý)

DateTime format string không qua `intl.DateFormat` thống nhất. Khi support đa ngôn ngữ thì sẽ phải fix.

**Fix**: tạo `core/formatters.dart` với `formatDate(dt)`, `formatDateTime(dt)`, `formatRelative(dt)` — gom về 1 nơi.

---

## By dimension — bảng tổng

| Dimension | Critical | Major | Minor | Tổng |
|---|---|---|---|---|
| Spacing | 0 | 0 | 2 | 2 |
| Typography | 0 | 1 | 1 | 2 |
| Color | 3 | 2 | 2 | 7 |
| Hierarchy | 0 | 0 | 0 | 0 |
| Component consistency | (gộp C2) | 2 | 0 | 2 |
| Interaction patterns | 0 | (gộp M5) | 0 | 0 |
| Responsive | 0 | 0 | 0 | 0* |

> \* Responsive **chưa audit sâu** — cần chạy app và resize window mới đánh giá được. File responsive_helper / breakpoints không tìm thấy trong `core/`. Đề xuất: tạo skill follow-up "audit responsive ở 360px / 768px / 1440px" trong sprint sau.

---

## Recommended fix order

Nếu muốn fix nhanh nhất với impact lớn nhất, làm theo thứ tự sau:

**Sprint refactor (1-2 ngày)**:

1. **C1** — find-replace `Color(0xFFFAFAFA)` → `context.appBg` (15 chỗ, mechanical, ~30 phút)
2. **C3** — định nghĩa 2 tokens mới `surfaceMuted` + `pillBg`, replace 5 grays (~1 giờ)
3. **M1** — tokenize `ptitGradientHero`, replace 6 chỗ (~30 phút)
4. **C2** — tokenize sidebar colors (~1 giờ + design quyết định a/b)
5. **M3** — radius normalize (~30 phút)
6. **M4** — `Colors.amber.shade600` → `context.warnOrange` (~5 phút)

Sau Sprint refactor: chạy lại audit → expect Critical = 0, Major ≤ 2.

**Defer to backlog**:
- M2 (30+ TextStyle migration) — đụng nhiều file, dễ regression. Làm khi đụng vào file đó cho task khác (opportunistic).
- M5 (loading indicator color) — audit case-by-case khi gặp.
- Toàn bộ Minor (m1-m6) — không gấp.

---

## Verify checklist sau khi fix

- [ ] Bật dark mode trong Profile → 100% admin screens đổi sang `appBgDark`
- [ ] Grep `0xFF[FA-F][AF0-9A-F]{4}` trong `features/` chỉ trả về kết quả ở `theme.dart` / `theme_dark.dart` / `app_colors.dart`
- [ ] Mở mỗi screen Trong Flutter inspector → mọi `Padding` và `EdgeInsets` đều là multiple của 4 (chấp nhận 13/14 ở input)
- [ ] Mọi `BorderRadius.circular(...)` chỉ dùng 10 / 12 / 20
- [ ] Mọi `TextStyle(...)` không có `fontSize:` raw ngoài thư mục `core/theme*.dart`
- [ ] Re-run audit script (grep patterns ở Section "By dimension") → Critical = 0

---

## Phụ lục — Patterns dùng để re-audit

```bash
# Off-scale spacing (PowerShell):
Select-String -Path lib/features/**/*.dart -Pattern "EdgeInsets\.\w+\([^)]*\b(3|5|6|7|9|10|11|14|17|18|19|21|22|23|26|30)\b"

# Raw hex outside theme:
Select-String -Path lib/features/**/*.dart -Pattern "Color\(0xFF[0-9A-Fa-f]{6}\)"

# Hard-coded TextStyle (no theme.textTheme):
Select-String -Path lib/features/**/*.dart -Pattern "TextStyle\([^)]*fontSize:"

# Off-radius:
Select-String -Path lib/features/**/*.dart -Pattern "BorderRadius\.circular\((?!10|12|20)\d+\)"

# Material colors (Colors.x.shade):
Select-String -Path lib/features/**/*.dart -Pattern "Colors\.\w+\.(shade|with)"
```

---

## Notes về phương pháp audit

Audit này dùng **static analysis qua grep** — đối chiếu code với baseline `theme.dart`. Có 2 mặt giới hạn:

1. **Không thấy được rendered output** → các vấn đề về hierarchy thực tế (eye-flow, primary action prominence, mobile reflow) cần screenshot hoặc chạy app để đánh giá. Audit này tập trung vào "design system code drift" chứ chưa đánh giá "trải nghiệm mắt".
2. **False positive với 12, 16** — Explore agent flag nhầm 1-2 chỗ on-scale là off-scale. Mọi flag trong báo cáo này đã được verify lại bằng grep.

Để audit hoàn chỉnh trải nghiệm visual, đề xuất chạy follow-up audit với screenshot test (ảnh 360/768/1440px cho 5 screen quan trọng nhất: Login / Home SV / Contest List / Approval Queue BCN / Admin Dashboard) — skill `web-design-guidelines` sẽ critique trên ảnh thật.
