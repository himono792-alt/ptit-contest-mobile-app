# Flutter Web Renderer Evaluation — Canvaskit vs HTML

**Ngày**: 2026-05-07
**Flutter SDK**: 3.27.1 (stable channel, Dart 3.6.0)
**Phương pháp**: Build cả 2 modes + serve song song port 5050 (canvaskit) + 5051 (html). Compare network, DOM, a11y, keyboard.
**Mục tiêu**: Quyết định long-term renderer cho production. Fix Phase C META a11y issue.

---

## TL;DR

**Khuyến nghị**: **GIỮ NGUYÊN canvaskit** + đầu tư Sprint 5 wrap thêm Semantics() widgets. Lý do chính: Flutter 3.27.1 đã **deprecate HTML renderer**, sẽ bị **remove ở Flutter 3.29** (~Q1 2025). Switch HTML là dead-end path.

Tuy nhiên HTML mode có **practical UX wins** đáng note:
- ✅ Tab keyboard nav work ngay không cần placeholder click trigger
- ✅ Native `<input>` element ngay từ page load (canvaskit lazy create)
- ✅ Password manager autofill instant
- ✅ ~6.5 MB nhẹ hơn first-paint network (skip canvaskit.wasm fetch)

→ Document trong báo cáo Chương 5 hạn chế: "Flutter framework đang chuyển hướng canvaskit-only, a11y limitation cần workaround Semantics() wrappers (đã làm Sprint 3)".

---

## Build comparison

### Bundle size on disk

| File | Canvaskit | HTML | Diff |
|---|---:|---:|---:|
| Total folder | 24,944,050 B (24.94 MB) | 25,007,953 B (25.00 MB) | +0.06 MB |
| `main.dart.js` | 3,314,275 B (3.16 MB) | 3,378,184 B (3.22 MB) | +0.06 MB |
| `canvaskit/canvaskit.wasm` | 6,777,064 B (6.78 MB) | 6,777,064 B (vẫn bundle) | 0 |

**Insight**: Cả 2 builds gần bằng nhau on disk vì Flutter HTML mode VẪN bundle canvaskit assets như fallback. Diff thực sự ở **runtime download**.

### Build command + warnings

```bash
flutter build web --web-renderer html --release ...
> The HTML Renderer is deprecated. Do not use "--web-renderer=html".
> See: https://docs.flutter.dev/to/web-html-renderer-deprecation
> ✓ Built build/web (36.3s)
```

→ Confirmed deprecation. Build vẫn pass nhưng warning rõ ràng.

---

## Runtime network comparison (first page load)

| Resource | Canvaskit | HTML |
|---|---|---|
| `flutter_bootstrap.js` | ✓ 5050 | ✓ 5051 |
| `main.dart.js` | ✓ 3.16 MB local | ✓ 3.22 MB local |
| `canvaskit.wasm` | ✓ 5.4 MB từ gstatic CDN | ✗ KHÔNG fetch |
| `canvaskit.js` | ✓ 90 KB từ gstatic CDN | ✗ KHÔNG fetch |
| Google Fonts (7 .ttf) | ✓ ~250 KB | ✓ ~250 KB |
| Material Icons | ✓ 20 KB | ✓ 20 KB |
| Total first-paint network | **~10 MB** | **~3.5 MB** |

→ HTML mode **save ~6.5 MB** network mỗi first load. Quan trọng cho mobile 3G/4G yếu hoặc slow wifi.

---

## DOM structure comparison (login screen)

### Canvaskit

```html
<flutter-view>
  <flt-glass-pane>
    <!-- canvas elements positioned absolute, render via Skia → WebGL -->
    <flt-semantics-host></flt-semantics-host>  <!-- empty until trigger -->
    <flt-text-editing-host></flt-text-editing-host>  <!-- empty until focus -->
  </flt-glass-pane>
</flutter-view>
```

- 0 native `<button>`, `<input>`, `<a>` on page load
- Tab key dính `flt-glass-pane`, KHÔNG nhảy được

### HTML

```html
<flutter-view>
  <flt-glass-pane>
    <!-- divs positioned + CSS transforms -->
    <input type="text" autocomplete="email">      <!-- email field NATIVE -->
    <input type="password" autocomplete="current-password">  <!-- password NATIVE -->
    <flt-semantics-host></flt-semantics-host>  <!-- inactive but DOM exists -->
  </flt-glass-pane>
</flutter-view>
```

- **2 native `<input>` elements** từ page load
- Tab → email INPUT → password INPUT → submit button
- Browser autocomplete + password manager work

---

## A11y comparison (axe-core scan Login 1440)

### Canvaskit (after placeholder click trigger)

| Metric | Value |
|---|---|
| `flt-semantics-host` children | 1 root + 22 nested |
| `flt-semantics[role="button"]` | 1 |
| Native `<input>` | 0 (until focus) |
| axe violations | 1 (button-name = Claude ext FP) |
| Tab without trigger | ❌ Stuck in glass-pane |

### HTML (after placeholder click trigger)

| Metric | Value |
|---|---|
| `flt-semantics-host` children | 1 root + 16 nested |
| `flt-semantics[role="button"]` | 4 |
| Native `<input>` | 2 (email + password) |
| axe violations | 2 (`aria-command-name`, `label` — input thiếu `<label for>`) |
| Tab without trigger | ✅ Email → Password → Submit |

→ HTML có **MORE** axe violations (2 vs 1) vì axe thấy nhiều DOM elements hơn để kiểm tra. **Trade-off**: nhiều violations visible nhưng chính xác hơn cho a11y testing.

→ HTML có **better default keyboard a11y** mà không cần Semantics() workaround.

---

## Keyboard navigation test (Tab × 3)

### Canvaskit

```
Click body → Tab → activeElement = FLT-GLASS-PANE
Tab → FLT-GLASS-PANE (stuck)
Need: click <flt-semantics-placeholder> button manually first
After trigger: Tab → FLT-SEMANTICS (button role)
```

### HTML

```
Click body → Tab → activeElement = INPUT type=text (email) ✓
Tab → INPUT type=password ✓
Tab → FLT-SEMANTICS role=button (Đăng nhập) ✓
```

→ HTML mode keyboard navigation **work out-of-the-box**. Canvaskit cần manual semantics trigger.

---

## Visual rendering quality

Cả 2 modes render gần như identical cho Login + Home + Contest List + Profile screens. Em screenshot 4 screens × 2 viewports không thấy diff đáng kể visual:
- Font rendering: canvaskit pixel-perfect, HTML browser font-smoothing (slight diff macOS Safari)
- BoxShadow: identical
- Gradient: identical
- Animation: cả 2 60fps trên i7 desktop modern

→ App PTIT Contest **không có widget complex** (BackdropFilter, ShaderMask, custom shader) → HTML rendering quality match canvaskit.

---

## Critical caveat: Flutter framework deprecation timeline

| Flutter version | HTML renderer status |
|---|---|
| ≤ 3.23 | Default option |
| 3.24-3.26 | Works, no warning |
| **3.27.1** (anh đang dùng) | ⚠️ Deprecated, build warns |
| 3.28 | Deprecated, last stable with HTML |
| **3.29** (Q1 2025) | ❌ **REMOVED** entirely, canvaskit-only |

Switching production sang HTML mode = **dead-end path**. Khi anh upgrade Flutter sau này, app sẽ **break** unless migrate back canvaskit.

---

## Decision matrix

| Aspect | Canvaskit (current) | HTML | Winner |
|---|---|---|---|
| Bundle size on disk | 24.94 MB | 25.00 MB | tie |
| First-paint network | ~10 MB | ~3.5 MB | **HTML** |
| Native input on load | 0 | 2 | **HTML** |
| Tab keyboard nav default | ❌ | ✅ | **HTML** |
| Password manager autofill | Lazy | Instant | **HTML** |
| axe violations Login | 1 (FP) | 2 | tie (HTML find more issues) |
| Semantics tree default | Empty until trigger | Empty until trigger | tie |
| Visual fidelity (PTIT app) | Pixel-perfect | Match (no complex widgets) | tie |
| Animation 60fps | ✅ | ✅ (PTIT app simple) | tie |
| Browser SEO indexing | ❌ Canvas opaque | ✅ DOM crawlable | **HTML** |
| **Long-term Flutter support** | ✅ | ❌ Removed 3.29 | **CANVASKIT** ⭐ |
| Development risk | Stable | Migration debt | **CANVASKIT** ⭐ |

→ **HTML wins 5/12 categories** for short-term UX/a11y.
→ **Canvaskit wins 2/12 categories** including the **biggest one (long-term support)**.

---

## Recommendation

### Primary: KEEP canvaskit (current production)

**Lý do**:
1. Flutter 3.29 sẽ remove HTML renderer (~Q1 2025, ~3 tháng nữa). Switch HTML giờ = phải migrate back trong vòng 6 tháng.
2. Frontend đã invest 5 widget categories Sprint 3 Semantics() wrappers — hiệu quả rõ rệt khi user triggers.
3. App simple (no BackdropFilter etc) → canvaskit rendering quality không kém HTML.
4. Production stability ưu tiên hơn potential a11y wins.

### Secondary: Sprint 5 Semantics() deep wrapping (post-defense)

Mở rộng Sprint 3 wraps thêm 30-50 widgets nữa:
- Form inputs với explicit `Semantics(textField: true, label: '...', hint: '...')`
- All buttons custom (InkWell + Container) với `Semantics(button: true, ...)`
- All navigation tabs/links với `Semantics(link: true, ...)`
- Add `MergeSemantics` để gộp nested interactive

Sau Sprint 5: Canvaskit a11y gần như tương đương HTML mode (chỉ cần placeholder click 1 lần, sau đó Tab nav full).

### Defer: Auto-detect mode

Flutter 3.27 default `--web-renderer auto` (mobile=html, desktop=canvaskit). Đã được Flutter team coi là legacy. Không recommend.

---

## Documentation cho báo cáo

Add vào báo cáo `2026-05-07_bao-cao-cnpm_v02.md` Chương 5.1.3 hoặc Chương 6.3:

> **Flutter web renderer evaluation (2026-05-07)**: Đã eval 2 modes canvaskit + HTML.
> Findings: HTML mode có advantages a11y/keyboard nav out-of-the-box + first-paint network nhẹ
> hơn ~6.5MB. Nhưng Flutter team deprecate HTML renderer ở 3.27 và remove ở 3.29 (Q1 2025) →
> switch HTML = dead-end path.
> Decision: Giữ canvaskit + Sprint 5 mở rộng Semantics() wrappers (Sprint 3 đã làm 5 categories).
> Detail: `11-docs/html-renderer-eval-2026-05-07.md`.

---

## Files

- `build/web-canvaskit/` — canvaskit build (~25 MB)
- `build/web-html/` — html build (~25 MB, can delete sau eval)
- `11-docs/html-renderer-eval-2026-05-07.md` — this document
