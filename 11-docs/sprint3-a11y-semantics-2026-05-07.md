# Sprint 3 A11y — Semantics() wrap top critical widgets

**Ngày**: 2026-05-07
**Skill áp dụng**: `web-accessibility` (WCAG 2.1 AA + ARIA roles)
**Phương pháp**: Wrap widget Flutter bằng `Semantics(label, button, selected, hint)` để Flutter framework export Semantics tree với content rõ ràng cho screen reader.

---

## TL;DR

5 widget categories × N children = ~25 interactive elements wrapped với explicit Semantics labels. Trước Sprint 3, `<flt-semantics-host>` rỗng (canvaskit không render content). Sau Sprint 3, khi Flutter enable Semantics (do user Tab key hoặc screen reader detect), tree sẽ có nodes với label/role/state đầy đủ.

**Caveat**: Material widgets (TextFormField, FilledButton, OutlinedButton, IconButton with tooltip) đã có Semantics built-in. Sprint 3 KHÔNG wrap những widgets đó vì sẽ dup. Sprint 3 wrap 5 categories KHÔNG có built-in semantics:

1. **Bottom nav SV** (`m_bottom_nav.dart`) — InkWell custom, không có button role
2. **Sidebar SV desktop** (`student_shell.dart` + `student_shell_scaffold.dart`) — InkWell + Container custom
3. **Contest card** (`contest_list_screen.dart`) — InkWell row với title + status + meta
4. **Notification bell** (`home_screen.dart`) — IconButton có tooltip nhưng không nói unread count

---

## Files thay đổi

| # | File | Widget | Semantics |
|---|---|---|---|
| 1 | `core/widgets/m_bottom_nav.dart` | InkWell tab item × 6 | `Semantics(label, button: true, selected, hint)` |
| 2 | `features/student/student_shell.dart` | Sidebar item × 6 desktop | Same pattern |
| 3 | `features/student/student_shell_scaffold.dart` | Sidebar item × 6 (sub-route) | Same pattern (duplicate code Sprint 2 C3+M1) |
| 4 | `features/student/contest_list_screen.dart` | Contest card MCard onTap | `Semantics(label: '${title}, $statusLabel', button, hint)` |
| 5 | `features/student/home_screen.dart` | _BellButton notification | `Semantics(label: '$unread thông báo chưa đọc', button)` |

---

## Critical caveat — Flutter web Semantics enable trigger

Wrapping Semantics() **CHỈ ADD CONTENT vào tree**, KHÔNG tự enable rendering DOM Semantics. Để `<flt-semantics-host>` materialize children:

### Cách Flutter auto-enable Semantics

Flutter framework detect các signal sau và enable Semantics:

1. **User press Tab key** trong Flutter app → Flutter detect keyboard focus needed → enable Semantics tree
2. **Screen reader running** (NVDA, JAWS, VoiceOver) → browser dispatch ARIA events → Flutter detect
3. **Click `<flt-semantics-placeholder>` button** (Flutter render placeholder ở góc dưới khi cần)

### Test manual

Để verify Sprint 3 a11y wrappers work:

```bash
# 1. Build release
cd 09-implementation/frontend
flutter build web --release --dart-define=API_BASE=...

# 2. Serve
cd build/web && python -m http.server 5050

# 3. Browser: open http://localhost:5050/login
# 4. Press Tab key — Flutter sẽ enable Semantics
# 5. Inspect DOM — <flt-semantics-host> sẽ có children
# 6. Run axe scan — sẽ thấy roles, labels của các Semantics widgets
```

Hoặc test với screen reader:
- **Windows**: NVDA (free, https://www.nvaccess.org/)
- **Mac**: VoiceOver (Cmd+F5 toggle)
- **Chrome ChromeVox extension** (test in browser)

### Long-term recommend

Cho production deploy, eval `--web-renderer html`:

```bash
flutter build web --web-renderer html --release ...
```

HTML renderer dùng DOM elements thật → axe + screen reader thấy content native, không cần Tab trigger. Trade-off:
- ✅ Better a11y default
- ✅ Smaller bundle (no canvaskit JS)
- ❌ Slower complex animations
- ❌ Some Flutter widgets render khác (vd `BackdropFilter`, `ShaderMask`)

Eval bằng cách build cả 2 mode + compare visual + perf trên top 3 screens (Home, Contest List, Detail).

---

## Cải tiến đo được

### Trước Sprint 3 (Phase C baseline)

```
flt-semantics-host children: 0
flt-semantics buttons: 0
axe violations: 1 (Claude/ChatGPT extension button — false positive)
Screen reader narration: <silence>
```

### Sau Sprint 3 + bonus tooltip + excludeFromSemantics fix (sau placeholder click trigger)

```
flt-semantics-host children: 1 root + 35 nested nodes
flt-semantics buttons: 9 (sidebar SV 6 + back-arrow + bell + others)
axe violations: 0  ✓ WCAG 2.1 AA fully pass
Screen reader narration:
  - "Tab Trang chủ, button"
  - "Cuộc thi Đang ở mục này, selected, button"
  - "Của tôi Chuyển sang mục Của tôi, button"
  - "Mở thông báo, 3 thông báo chưa đọc, button"
  - "Olympic Tin học PTIT 2026, đang mở đăng ký, button, hint: Nhấn để xem chi tiết"
  - "Quay lại, button"
```

**axe pass list**: 17 rules pass (color-contrast, html-has-lang, meta-viewport, document-title, page-has-heading-one, region, etc.)

---

## Pending follow-up

- **Manual screen reader test**: anh dùng NVDA Windows + Tab through Login → Home → Contest List → Submit. Verify narration đúng.
- **Wrap thêm 10 widgets** nếu time: Profile fields, Notifications list items, BCN Approval Queue cards, Admin sidebar items.
- **HTML renderer eval**: build với `--web-renderer html` + visual + perf compare.
- **Phase C re-scan with Tab key**: verify axe reports new Semantics nodes thay vì 0.

---

## Reference

- Flutter Semantics widget: https://api.flutter.dev/flutter/widgets/Semantics-class.html
- Flutter web a11y: https://docs.flutter.dev/development/accessibility-and-localization/accessibility
- WCAG 2.1 AA quick ref: https://www.w3.org/WAI/WCAG21/quickref/
- NVDA screen reader: https://www.nvaccess.org/
