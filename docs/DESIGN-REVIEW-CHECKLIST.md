# DESIGN REVIEW CHECKLIST — CNPM PTIT Contest

> Mọi PR UI mới đều chạy qua checklist này. Critical fail → block PR. Major → fix trong sprint hiện tại. Minor → backlog.
> Reference: skills `web-design-guidelines`, `web-accessibility`, `frontend-design`, `ui-ux-pro-max`.

---

## 0. Pre-flight — chạy trước khi review code

```powershell
cd frontend
pwsh tool/design_lint.ps1
flutter analyze lib/features/
```

→ Nếu lint **FAIL** với violation MỚI (so với `tool/post-phase-a-2026-05-06.txt`): block PR cho đến khi fix.

---

## 1. Token usage (foundation)

- [ ] Mọi `Color(0xFF...)` chỉ xuất hiện trong `lib/core/theme*.dart` hoặc `app_colors.dart`. Trong `features/` dùng `context.appBg / textPrimary / textMuted / cardBorder / ...` từ `AppColors` extension.
- [ ] Mọi `BorderRadius.circular(N)` dùng `AppRadius.tight (4) / sm (10) / md (12) / lg (20) / pill (999)`. Không có literal số.
- [ ] Mọi `EdgeInsets` dùng `AppSpacing.s4 / s8 / s12 / s16 / s24 / s32 / s48 / s64`. Không có 3/5/6/7/9/10/11/13/14/17/18/19/...
- [ ] Mọi animation `Duration` dùng `AppDuration.fast (150) / base (250) / slow (400)`.
- [ ] Mọi `MediaQuery` width compare dùng `kBpSm/Md/Lg/Xl` hoặc helper `isMobile() / isCompact() / isWide()`.
- [ ] Brand gradient dùng `ptitGradientHero` (diagonal) hoặc `LinearGradient(colors: ptitGradientHeroColors)`.

## 2. Typography

- [ ] Mọi `TextStyle(fontSize: N, ...)` thay bằng `Theme.of(context).textTheme.X?.copyWith(...)` với:
  - 11 → `labelSmall` (w600)
  - 12 → `bodySmall` (w500) hoặc `labelMedium` (w600) tùy intent
  - 13 → `bodyMedium` (w500) hoặc `titleSmall` (w600) tùy intent
  - 14 → `labelLarge` (w600)
  - 15 → `bodyLarge` (w500) hoặc `titleMedium` (w700)
  - 18 → `headlineSmall` (w700)
  - 20 → `titleLarge` (w800)
- [ ] Heading H1 1 lần/page; H2 sections; H3 subsections. Không skip levels.
- [ ] Body line-length dưới 75 ký tự (max-width container hoặc constraint).
- [ ] Plus Jakarta Sans là default. Override `fontFamily` chỉ khi có lý do (vd: monospace cho OTP code — phải comment).

## 3. Color & contrast

- [ ] Mọi color dùng từ palette `theme.dart` / `AppColors` extension. Không hex floating.
- [ ] Semantic dùng đúng: `successGreen/successSoft` cho success; `warnOrange/warnSoft` cho warning; `infoBlue/infoSoft` cho info; `ptitRed/ptitRedSoft` cho brand/destructive.
- [ ] Text contrast ≥ 4.5:1 (body) hoặc 3:1 (large/UI). Test bằng axe DevTools hoặc WebAIM Contrast Checker.
- [ ] Không dùng color alone để convey meaning — pair với icon + text label.
- [ ] Test cả **light + dark mode** (toggle trong Profile screen) — mọi screen render đúng, không có raw hex bị "đóng băng".

## 4. Hierarchy

- [ ] **1 primary action** rõ ràng mỗi screen/panel. Multiple FilledButton cùng màu = vi phạm.
- [ ] Eye-flow F-pattern hoặc Z-pattern phù hợp content priority.
- [ ] Whitespace hierarchical — gap lớn giữa section, gap nhỏ trong group.
- [ ] CTA position: top-right header / end of content / sticky bottom mobile. Không lẫn lộn.

## 5. Component consistency

- [ ] Confirmation dialogs dùng cùng component (`AlertDialog` Material), cùng button placement.
- [ ] Loading states: dùng `MShimmer` (skeleton) cho list loading, `CircularProgressIndicator(color: ptitRed)` cho center loading. Trong filled button dùng `Colors.white` (= onPrimary cho red bg).
- [ ] Empty states: có icon + title + description + (optional) CTA. Không để màn trắng.
- [ ] Error states: có message + retry button (gọi ErrorView pattern hiện có).
- [ ] Reuse `MCard / MCardListSkeleton / MTopBar / Pill / PillKind` trước khi tạo mới.

## 6. Interaction patterns

- [ ] Hover/focus/active state có visible feedback (theme đã set sẵn cho FilledButton, OutlinedButton, TextButton).
- [ ] Animation duration đồng bộ — `AppDuration.fast` cho hover, `base` cho menu, `slow` cho page.
- [ ] Confirmation:
  - High-frequency + low-cost (như filter chip, toggle): **không confirm**.
  - Soft action (delete temp draft): **toast với undo**.
  - Hard action (cancel registration, delete contest): **AlertDialog hard-confirm**.
- [ ] Feedback timeliness: toast trong 100ms, loading indicator nếu work > 300ms.
- [ ] Destructive action guard nhất quán: button đỏ + dialog confirm + double-check text.

## 7. Responsive

- [ ] Test ở 360px / 768px / 1024px / 1440px (Chrome DevTools device toolbar).
- [ ] Không horizontal scroll dưới 360px width.
- [ ] Touch target ≥ 44×44 trên mobile (Flutter default `MaterialTapTargetSize.padded` đảm bảo điều này — không override `shrinkWrap` nếu không cần).
- [ ] Content priority preserved: thứ quan trọng nhất desktop = thứ quan trọng nhất mobile.
- [ ] Image responsive: dùng `BoxFit.contain` + constraints, không hard-code pixel size.

## 8. A11y baseline (WCAG 2.1 AA)

- [ ] Icon-only `IconButton` có `tooltip:` (hiển thị) HOẶC `Semantics(label:)` (screen reader).
- [ ] Form input có `TextFormField` với `decoration.labelText` + `validator` (error message).
- [ ] `autofillHints:` cho login fields (`email / password / oneTimeCode / name`).
- [ ] Focus visible — không `outline: none` mà không thay thế.
- [ ] Test keyboard-only: Tab order match visual order, không trap.
- [ ] Reduced motion: animation lớn wrap trong `MediaQuery.disableAnimationsOf(context)` check.
- [ ] Alt text cho `Image.network`/`Image.asset` qua `Semantics(label:)`.
- [ ] Color contrast pass (verify ở section #3).

---

## Severity policy

- **Critical** (block PR):
  - Compile error / runtime crash.
  - WCAG AA contrast fail.
  - Brand violation (sai logo, sai brand color).
  - Theme drift (raw hex outside `core/theme*.dart`).
  - Touch target < 44×44.
- **Major** (fix trong sprint):
  - Token violation (radius/spacing/duration literal).
  - TextStyle hard-code (size literal).
  - Inconsistent component variant.
  - Missing state (loading/empty/error).
- **Minor** (backlog):
  - Spacing off-scale 1-2 instances ở edge case.
  - Custom font không justified.
  - Polish hierarchy.

---

## Cách dùng checklist

1. **Reviewer**: paste link checklist này vào PR description → check từng box.
2. **Author**: chạy `pwsh tool/design_lint.ps1` trước khi push, paste output vào PR comment.
3. **Conflict resolution**: severity policy quyết định block/non-block.

Last updated: 2026-05-06 (Phase A complete, baseline 334 → 269 violations).
