# Hướng phát triển UI/UX — PTIT Contest

Tài liệu phân tích thực trạng + đề xuất cải tiến UI/UX dựa trên audit codebase Flutter hiện tại (v1.0, 2026-05-06).

---

## 1. Thực trạng UI hiện tại

### 1.1 Design system đã có

- **Color palette PTIT brand**: `#C8102E` (red), warm-leaning bg `#FAF8F5`, ink scale `#1C1815` → `#A39B92`.
- **Typography**: Plus Jakarta Sans + JetBrains Mono mono, letter-spacing -0.02em (Linear/Notion feel).
- **Components**: MCard (radius 14, shadow-sm), Pill (status badge), MTopBar, MBottomNav.
- **Layout responsive**: SV mobile-first 400px frame; admin sidebar 240px. Breakpoint 768/900px chuyển mobile/desktop.
- **Theme**: Material 3, FilledButton red brand, OutlinedButton border `cardBorder`.

### 1.2 Điểm mạnh

| Điểm | Chi tiết |
|---|---|
| Brand consistency | Màu đỏ PTIT xuyên suốt, gradient hero banner, soft shadow Linear-feel. |
| Typography polish | Plus Jakarta Sans + tracking tighter làm UI "premium" hơn Material default. |
| Status hierarchy | Pill colors khớp semantic (PROPOSED orange, PUBLISHED green, REJECTED red). |
| Mobile-first SV | Bottom nav 6 tabs, MobileFrame trên web giúp dev test mobile nhanh. |
| Empty state có icon + msg | Không bao giờ hiển thị màn trắng — luôn có hint cho user. |
| Loading state | CircularProgressIndicator màu brand đỏ. |

### 1.3 Điểm yếu hiện tại (cần fix)

| # | Vấn đề | Impact | Effort |
|---|---|---|---|
| 1 | Không có dark mode | Chói mắt khi dùng tối | M |
| 2 | Không có i18n (EN) | SV quốc tế kẹt | L |
| 3 | Loading dùng CircularProgressIndicator đơn lẻ | Cảm giác chậm | S |
| 4 | Empty state chỉ Icon + text | Thiếu personality | S |
| 5 | Animation transition giữa tabs cứng | Chuyển tab thô | S |
| 6 | Bottom nav 6 tabs SV chật trên màn 4.7" | Label cắt | S |
| 7 | Form dài 11 fields (EditProfile) | Mobile scroll mệt | M |
| 8 | Contest detail SV hero không parallax | Static feel | S |
| 9 | Admin sidebar không có search | Tìm chức năng khó | S |
| 10 | Notifications không deep-link | Tap chỉ mark-read | M |
| 11 | Submission không hỗ trợ upload file | Phải dùng URL ngoài | L |
| 12 | Cert verify không có camera scan | Phải paste tay | M |
| 13 | Bell badge không animate | Người dùng bỏ sót | XS |
| 14 | Toast/SnackBar đơn điệu | Không có icon | XS |
| 15 | Dialog confirm không undo | Sai là mất | M |

---

## 2. Hướng cải tiến — phân theo trục

### 2.1 Trục VISUAL (3 đề xuất ưu tiên)

#### V1. Dark mode (P1, effort M)

**Vì sao**: SV thường dùng app buổi tối (sau giờ học). Theme sáng `#FAF8F5` chói màn AMOLED.

**Cách làm**:
- Tạo `theme_dark.dart` với inverted colors:
  - `appBg: #1C1815` (warm dark)
  - `cardBorder: #2D2A26`
  - `textPrimary: #FAF8F5`
  - `textMuted: #A39B92`
- Giữ `ptitRed: #C8102E` (brand không đổi)
- Switch trong Profile → "Giao diện" dropdown (Sáng / Tối / Theo hệ thống)
- Persist qua SharedPreferences

**Effort**: 2-3 ngày (test mọi screen).

#### V2. Loading skeleton (P1, effort S)

**Vì sao**: `CircularProgressIndicator` đơn lẻ giữa màn trắng → cảm giác app chậm. Skeleton mô phỏng layout chuẩn (như Facebook / LinkedIn) cho perceived performance tốt hơn.

**Cách làm**:
- Package `shimmer: ^3.0.0`
- Tạo `MCardSkeleton`, `MListSkeleton`, `MAvatarSkeleton`
- Replace mọi `CircularProgressIndicator(color: ptitRed)` trong SV screens
- Admin có thể giữ progress vì user mong đợi data table

**Effort**: 1 ngày.

#### V3. Empty state với illustration (P2, effort S)

**Vì sao**: Empty state hiện chỉ icon outline + 1 dòng text → vô vị. Illustration làm app "đầy đủ" hơn.

**Cách làm**:
- 6 illustration SVG cho empty cases: no contests, no entries, no results, no notifications, no certificates, no reviews.
- Free source: undraw.co, Storyset, Lottie animations
- Wrap component `EmptyView({illustration, title, subtitle, ctaButton})`

**Effort**: 0.5-1 ngày.

### 2.2 Trục INTERACTION (5 đề xuất)

#### I1. Smooth tab transition (P2, effort S)

**Hiện tại**: Bottom nav tap → IndexedStack switch tức thì, không animation. Cảm giác cứng.

**Cách làm**:
- Wrap tab content với `AnimatedSwitcher(duration: 220ms, transitionBuilder: FadeTransition)`.
- Hoặc dùng `PageView` với `physics: NeverScrollableScrollPhysics()` + `_pageController.animateToPage`.

**Effort**: 0.5 ngày.

#### I2. Pull-to-refresh consistent (P1, effort XS)

**Hiện tại**: Một số screens có `RefreshIndicator`, một số không (vd: `notifications_screen`, `audit_log_screen`).

**Cách làm**: Audit + thêm `RefreshIndicator(color: ptitRed)` cho mọi list screen.

**Effort**: 0.5 ngày.

#### I3. Optimistic UI (P2, effort M)

**Hiện tại**: Action (mark-read, approve entry) phải đợi server response → 200-500ms delay.

**Cách làm**:
- Update local state ngay lập tức
- Send API call background
- Rollback nếu fail (hiếm khi)
- Vd: tap "Mark all read" → badge → 0 ngay, sau đó POST

**Effort**: 1 ngày (cần cẩn thận với edge case).

#### I4. Undo bằng SnackBar (P1, effort S)

**Hiện tại**: Hủy đăng ký, ẩn review, xóa user → confirm dialog → action permanent.

**Cách làm**:
- Sau action thành công, show SnackBar với action "Hoàn tác" trong 5 giây.
- Backend cần endpoint reverse (vd: `POST /entries/{id}/unhide` hoặc undo cancellation).
- Hoặc client-side: lưu state cũ + reverse trong 5s window.

**Effort**: 1 ngày.

#### I5. Animated bell badge (P3, effort XS)

**Hiện tại**: Badge đỏ cứng. User không để ý.

**Cách làm**: Thêm `AnimatedScale(scale: hasUnread ? 1.0 : 0.0, duration: 200ms)` cho badge xuất hiện. Hoặc shake animation khi notification mới đến.

**Effort**: 1 giờ.

### 2.3 Trục INFORMATION ARCHITECTURE (4 đề xuất)

#### IA1. Bottom nav 6 → 5 + FAB (P2, effort S)

**Vì sao**: 6 tabs trên iPhone SE 4.7" làm label bị cắt ("Trang chủ" → "Trang ch...").

**Cách làm**:
- Bottom nav 5 tabs: Trang chủ / Cuộc thi / Của tôi / Kết quả / Tôi
- FAB "🔔" ở góc phải nổi → Notifications (badge count vẫn hiện)
- Hoặc gộp Thông báo vào tab "Tôi" với section "Thông báo gần đây"

**Effort**: 0.5 ngày.

#### IA2. Admin sidebar có search (P1, effort S)

**Vì sao**: 9-10 sidebar items, scroll mệt khi tìm. Nhất là Admin có quyền hết.

**Cách làm**: 
- TextField search ở đầu sidebar
- Filter sidebar items real-time theo keyword
- Phím tắt `Ctrl+K` (Cmd+K Mac) — như VS Code Command Palette

**Effort**: 0.5 ngày.

#### IA3. Drawer mobile admin có submenu group (P2, effort S)

**Vì sao**: 9-10 items list dài trên drawer mobile.

**Cách làm**: Group items theo phase:
```
🏠 Tổng quan
   Dashboard
🎓 Tổ chức
   Cuộc thi
   Phê duyệt
   Giám sát
   Chấm bài
👥 Quản trị (Admin only)
   Quản lý user
   Khoa/Ngành
   Bình luận
⚙️ Hệ thống (Admin only)
   Cấu hình
   Audit log
```

**Effort**: 0.5 ngày.

#### IA4. Edit Profile chia wizard 3 step (P2, effort M)

**Vì sao**: Form 11 fields trên mobile dài, scroll mệt, sai field nào không biết.

**Cách làm**:
- Step 1: Cá nhân (họ tên, DOB, giới tính, CCCD, nơi sinh)
- Step 2: Liên hệ (SĐT, email cá nhân, địa chỉ)
- Step 3: Quốc tịch · Dân tộc · Tôn giáo
- Progress indicator trên cùng
- Nút "Lưu nháp" giữa step (autosave SharedPreferences)
- Nút "Bỏ qua" cho step không bắt buộc

**Effort**: 1 ngày.

### 2.4 Trục MOBILE-SPECIFIC (5 đề xuất)

#### M1. Swipe action trên list item (P2, effort M)

**Vì sao**: Mobile native dùng swipe quen thuộc (Gmail, iMessage).

**Cách làm**:
- Của tôi tab: swipe left entry → "Hủy đăng ký" (red action)
- Notifications: swipe left → mark read; swipe right → delete
- Package `flutter_slidable: ^3.1.0`

**Effort**: 1 ngày.

#### M2. Haptic feedback (P3, effort XS)

**Vì sao**: Action quan trọng (approve, cancel, đăng ký thành công) cần phản hồi xúc giác.

**Cách làm**: `HapticFeedback.mediumImpact()` cho action confirm, `HapticFeedback.lightImpact()` cho tap nav.

**Effort**: 1 giờ.

#### M3. Bottom sheet thay vì dialog (P2, effort S)

**Vì sao**: Dialog ở giữa màn không native với mobile. Bottom sheet trượt từ dưới lên là pattern iOS/Android chuẩn.

**Cách làm**:
- Replace `showDialog` bằng `showModalBottomSheet`
- Áp dụng cho: ReviewDialog, ConfirmDialog, ChangePasswordDialog
- Ngoại lệ: AlertDialog nhỏ giữ nguyên

**Effort**: 1 ngày.

#### M4. Persistent session (no re-login) (P1, effort M)

**Vì sao**: JWT expire 8h → user mở app sáng thấy login lại → bực.

**Cách làm**:
- Refresh token (đã bàn ở doc Hạn chế)
- Auto-refresh trong background khi access token hết hạn
- Biometric login (FaceID/TouchID) khi mở app — package `local_auth: ^2.3.0`

**Effort**: 2-3 ngày.

#### M5. Notification deep-link (P1, effort M)

**Vì sao**: Tap noti chỉ mark-read là phí trải nghiệm.

**Cách làm**:
- Backend trả thêm `target_route` (vd: `/contests/5`, `/me/results`) trong NotificationOut.
- Frontend tap → `context.push(target_route)`.
- Push notification (FCM) deep-link khi tap noti từ system tray.

**Effort**: 2 ngày.

### 2.5 Trục WEB-SPECIFIC (4 đề xuất)

#### W1. Keyboard shortcuts (P2, effort S)

**Vì sao**: Power user (admin, GV) dùng web sẽ thích.

**Cách làm**:
- `Ctrl+K`: command palette
- `g + d`: go to dashboard
- `g + c`: go to cuộc thi
- `g + p`: go to phê duyệt
- `n`: new (contest / template / user tùy context)
- `?`: show shortcut help

Package `shortcuts` Flutter native + register actions.

**Effort**: 1 ngày.

#### W2. Bulk operations (P1, effort M)

**Vì sao**: Admin moderation review hiện chỉ ẩn 1 review/lần. Khi spam ồ ạt phải tap N lần.

**Cách làm**:
- Checkbox đầu mỗi row
- Toolbar fixed top khi có chọn: "Ẩn N review" / "Hiện N review" / "Xóa N review"
- Áp dụng: review moderation, user management (lock/unlock bulk), contests (bulk publish)

**Effort**: 2 ngày.

#### W3. Inline edit cells (P2, effort M)

**Vì sao**: Admin cần update award_title cho contest result hiện phải mở dialog → save → close. Inline click cell → edit → blur save sẽ nhanh hơn 5x.

**Cách làm**:
- Component `EditableCell` wrap text với onClick → switch sang TextField
- Áp dụng: contest results award_title, user phone, faculty name, criterion weight

**Effort**: 1.5 ngày.

#### W4. Drag & drop (P3, effort M)

**Vì sao**: Reorder rounds, criteria trong rubric, contest_organizers — hiện phải nhập thứ tự bằng số.

**Cách làm**:
- Package `flutter_reorderable_list` hoặc `ReorderableListView` native
- Backend cần endpoint bulk update display_order

**Effort**: 1.5 ngày.

### 2.6 Trục ACCESSIBILITY (3 đề xuất)

#### A1. Screen reader support (P2, effort M)

**Vì sao**: WCAG 2.1 yêu cầu semantic labels cho mọi action.

**Cách làm**:
- Wrap interactive widgets với `Semantics(label: 'Đăng ký cuộc thi', button: true, ...)`.
- Test với TalkBack (Android) / VoiceOver (iOS).
- Icon-only buttons có `tooltip` (đã làm 1 phần).

**Effort**: 2 ngày.

#### A2. Color contrast WCAG AA (P1, effort S)

**Vì sao**: `textFaint: #A39B92` trên `appBg: #FAF8F5` chỉ đạt contrast ratio 2.4 — fail WCAG AA (yêu cầu ≥4.5).

**Cách làm**:
- Run tool kiểm tra contrast: https://webaim.org/resources/contrastchecker/
- Tăng `textFaint` lên `#7A6F65` (hiện đang là `textMuted`) — đạt 4.7
- Kiểm tra mọi pair (text + bg) trong theme.dart

**Effort**: 0.5 ngày.

#### A3. Tap target ≥48dp (P1, effort S)

**Vì sao**: Material guidelines yêu cầu touch target tối thiểu 48dp. Nhiều icon button hiện 24-32dp → khó tap chính xác.

**Cách làm**:
- Replace `IconButton(iconSize: 18)` với padding compensate để hit area = 48dp
- Hoặc dùng `InkWell` wrap với `borderRadius` + min size 48dp

**Effort**: 0.5 ngày.

### 2.7 Trục PERFORMANCE (3 đề xuất)

#### P1. Image lazy load + WebP (P2, effort S)

**Vì sao**: Avatar URL, banner_url contest có thể nặng nếu là PNG/JPG full-res.

**Cách làm**:
- Backend: convert upload thành WebP (Pillow Python)
- Frontend: `cached_network_image` với `placeholder` skeleton
- Lazy load: `IntersectionObserver` web hoặc `VisibilityDetector` Flutter

**Effort**: 1 ngày.

#### P2. Reduce bundle size Flutter web (P2, effort S)

**Vì sao**: main.dart.js hiện 2.94 MB → 3G slow.

**Cách làm**:
- `flutter build web --tree-shake-icons --release`
- Bỏ google_fonts package, dùng @font-face local trong index.html
- Lazy load route widgets với `deferred-components`

**Effort**: 1 ngày.

#### P3. Cache list data với Riverpod keepAlive (P2, effort XS)

**Vì sao**: Mọi `FutureProvider.autoDispose` re-fetch khi navigate qua-lại tabs.

**Cách làm**:
- `FutureProvider.autoDispose` → bỏ `autoDispose` cho data ít thay đổi (faculties, master data, contests list)
- Hoặc dùng `KeepAliveLink` để giữ cache 5 phút

**Effort**: 1 giờ.

---

## 3. Mockup screen-level cải tiến cụ thể

### 3.1 Home (SV)

**Hiện tại**: Avatar tap → tab Tôi · Bell · Search bar · 3 stat cards · Featured contests list.

**Đề xuất**:
- Hero greeting card sáng (gradient soft) chứa: "Chào buổi sáng, A 🌅" / "Bạn có 2 cuộc thi đang mở đăng ký"
- Quick actions row: "Đăng ký nhanh" / "Submit bài" / "Xem cert" — 3 button icon lớn
- Recommendation: AI suggest contest dựa trên history (collaborative filtering)
- Calendar widget: lịch contest tuần này (timeline)

### 3.2 Contest Detail (SV)

**Hiện tại**: Hero gradient + sections + sticky CTA.

**Đề xuất**:
- Parallax scroll hero banner
- Sticky tab bar "Tổng quan / Quy chế / Giải / Lịch / Reviews" khi scroll
- Stats section: số người đăng ký, top 3 winner năm trước (nếu là cuộc thi định kỳ)
- Countdown timer animated khi REG_OPEN sắp đóng
- Share button → bottom sheet với 4 option (FB, Telegram, Email, Copy link)

### 3.3 Admin Dashboard

**Hiện tại**: 4 stat cards + Welcome card.

**Đề xuất**:
- Stat cards có sparkline chart (7 ngày gần nhất) — package `fl_chart`
- "Cần làm hôm nay" card: list TODOs (10 entries chờ duyệt, 3 contest sắp ONGOING, 2 BCN approval pending)
- Activity feed: 10 audit log gần nhất (live update)
- Quick actions bar: "Tạo contest mới" / "Duyệt entries" / "Compute results"

### 3.4 Admin Contest Detail (6 tabs)

**Hiện tại**: 6 tab cùng level → user không biết phase nào next.

**Đề xuất**:
- Convert tabs → **Stepper** workflow:
  1. Tổng quan (chỉnh thông tin)
  2. Vòng & Rubric (setup)
  3. Đăng ký (duyệt SV)
  4. Chấm điểm (assign + score)
  5. Kết quả (compute + publish)
  6. Chứng nhận (issue)
- Mỗi step có check icon nếu xong, lock nếu chưa đến lượt
- Progress bar trên cùng
- Thay vì TabBarView, dùng AnimatedSwitcher với SlideTransition

### 3.5 EditProfile

**Hiện tại**: Form dài 11 fields trong 1 trang.

**Đề xuất**:
- Wizard 3 step (xem IA4 ở trên)
- Avatar upload với crop (package `image_cropper`)
- Verified badge cho SV PTIT (✓ blue) cạnh tên

### 3.6 Notifications

**Hiện tại**: List card với title + body + time + mark read.

**Đề xuất**:
- Group theo ngày (Hôm nay / Hôm qua / Tuần này / Cũ hơn)
- Icon theo loại: 📋 entry approved, 📊 result published, 📜 cert issued, 💬 review reply
- Swipe action mark read / delete (xem M1)
- Filter chip: Tất cả / Chưa đọc / Cuộc thi / Hệ thống
- Search trong notifications
- Pull-to-refresh

### 3.7 Cert Verify

**Hiện tại**: Input mã + Verify → result card.

**Đề xuất**:
- 2 mode tab: "Quét QR" (camera) / "Nhập mã" (paste)
- Quét QR dùng `mobile_scanner` package
- Result card có animation slide từ dưới lên
- Nút "Lưu vào ảnh" (download cert HTML render → screenshot lưu Photos)

### 3.8 Forgot Password

**Hiện tại**: 2 screen tách, step 1 → step 2.

**Đề xuất**:
- Step 1: thêm illustration "padlock" lớn
- Auto-focus input email
- Step 2: progress dots (1 ━━ 2)
- Success page: confetti animation (package `confetti`)

---

## 4. Roadmap UI/UX 3 sprint (1 sprint = 2 tuần)

### Sprint 1 — Foundation

**Mục tiêu**: Polish core UX, fix accessibility, prepare for dark mode.

| Task | Effort |
|---|---|
| A2. Color contrast WCAG AA | 0.5 |
| A3. Tap target ≥48dp | 0.5 |
| V2. Loading skeleton (shimmer) | 1 |
| V3. Empty state illustrations (6 variants) | 1 |
| I2. Pull-to-refresh consistent | 0.5 |
| I4. Undo SnackBar (3 critical actions) | 1 |
| W2. Bulk operations (review moderation + users) | 2 |
| **Total** | **6.5 ngày** |

### Sprint 2 — Mobile native feel

**Mục tiêu**: Mobile experience as native as possible.

| Task | Effort |
|---|---|
| V1. Dark mode | 2.5 |
| M1. Swipe actions (slidable) | 1 |
| M2. Haptic feedback | 0.2 |
| M3. Bottom sheet replacements | 1 |
| I1. Smooth tab transition | 0.5 |
| I3. Optimistic UI (mark-read, approve entry) | 1 |
| IA1. Bottom nav 5 tabs + FAB | 0.5 |
| **Total** | **6.7 ngày** |

### Sprint 3 — Advanced & web power-user

**Mục tiêu**: Power features for admin/GV web + AI suggestions.

| Task | Effort |
|---|---|
| W1. Keyboard shortcuts + Cmd+K palette | 1 |
| W3. Inline edit cells (3 screens) | 1.5 |
| IA2. Admin sidebar search | 0.5 |
| IA3. Drawer submenu groups | 0.5 |
| IA4. EditProfile wizard 3 step | 1 |
| 3.4 Contest admin Stepper conversion | 2 |
| 3.7 Cert verify QR scan | 1 |
| **Total** | **7.5 ngày** |

**Tổng 3 sprint**: ~21 ngày = 4-5 tuần với 1 dev full-time.

---

## 5. Inspiration references

| Pattern | App tham khảo |
|---|---|
| Dark mode warm | Notion, Linear |
| Empty state illustration | Slack, Notion |
| Skeleton loading | LinkedIn, Facebook |
| Bottom sheet UX | Apple Music, Discord |
| Optimistic UI | Twitter (X) |
| Command palette Cmd+K | Linear, GitHub, VS Code |
| Activity feed | GitHub home, Trello |
| Stepper workflow | Stripe Dashboard, Shopify Checkout |
| Calendar contests | Google Calendar, Notion Calendar |
| Smart search (full-text) | Notion search, GitHub global search |

---

## 6. Tools đề xuất cho dev/designer

| Tool | Dùng để |
|---|---|
| **Figma** | Mockup redesign, share với team |
| **Storybook** | Document component library (MCard, Pill, etc.) |
| **Maestro** | E2E test mobile UX flow |
| **Playwright** | E2E test web |
| **Lighthouse** | Audit performance + accessibility web |
| **Flutter Inspector** | Debug widget tree, layout |
| **Sentry** | Track UI errors thực tế từ user |
| **Hotjar** | Heatmap web — biết user click chỗ nào |

---

## 7. Kết luận

UI hiện tại **đạt mức MVP polished** với brand consistency tốt, typography premium, responsive 2 chiều. Tuy nhiên còn **15 điểm yếu cụ thể** chia thành 7 trục cải tiến.

**Khuyến nghị**: Làm Sprint 1 trước (foundation) để fix accessibility + perceived performance — 6.5 ngày. Hai sprint sau optional tùy resource.

**Ưu tiên cao nhất** (P1):
1. Color contrast WCAG AA (0.5 ngày, fix lỗi accessibility nghiêm trọng)
2. Loading skeleton (1 ngày, perceived perf)
3. Dark mode (2.5 ngày, user demand cao)
4. Refresh token + persistent session (2 ngày, fix log-out bực bội)

Sau 3 sprint, app sẽ đạt mức **production-ready với UX cao** — có thể compete với app commercial như Notion, Linear, Discord ở mặt UI.

---

**Ngày**: 2026-05-06
**Tác giả**: Nhóm CNPM PTIT
