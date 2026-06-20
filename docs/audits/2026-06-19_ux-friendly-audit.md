# Nghiên cứu tối ưu giao diện thân thiện — PTIT Contest

> Ngày: 2026-06-19 · Phạm vi: 4 actor (SV / GV-BTC / BCN / Admin) · Nền tảng: Flutter web + mobile
> Phương pháp: audit grounded trong code `frontend/lib/features/**` theo 10 heuristics của Jakob Nielsen, đối chiếu lịch sử Sprint 16–28.
> Tài liệu gồm 3 phần: **A. Audit chấm điểm** · **B. Micro-copy & empty-state paste-ready** · **C. Backlog sprint có ước lượng**

---

## Tóm tắt điều hành

Dự án đã có nền tảng UI tốt hơn mặt bằng đồ án: design tokens (484), dark mode toàn diện, skeleton theme-aware, leaderboard podium, timeline visual, sidebar collapse. Phần "thân thiện" còn yếu **không nằm ở thẩm mỹ mà ở 3 điểm chạm cảm xúc**:

1. **Empty states trống rỗng** — `EmptyView` chỉ xuất hiện ở 7/~40 màn và *không một màn nào* gắn nút CTA (`action:`), dù chính widget đã thiết kế sẵn slot này. User mới gặp "màn trắng" thay vì được dẫn đường.
2. **Feedback không nhất quán & không phân biệt thành công/lỗi** — 23 file dùng `SnackBar(content: Text(...))` trần, không màu, không icon. Không phân biệt được "xong rồi" với "hỏng rồi" bằng thị giác.
3. **Ngôn ngữ lỗi lộ kỹ thuật** — lỗi hiển thị raw `$msg`, `$e`, `DioException.message`, `${detail}`. User thấy "Lỗi: DioException [bad response]" thay vì câu người hiểu.

Ba việc này tác động cảm nhận "thân thiện" mạnh hơn mọi hiệu ứng đồ họa, và chi phí thấp vì đa số là sửa tập trung tại widget dùng chung.

**Điểm tổng quan độ thân thiện hiện tại: 6.8 / 10** (chi tiết theo heuristic ở Phần A).

---

# A. Audit chấm điểm theo Nielsen heuristics

Thang điểm mỗi heuristic: 1 (kém) – 5 (tốt). Mỗi mục nêu bằng chứng từ code.

## A.1 Tổng quan 10 heuristics

| # | Heuristic | Điểm | Nhận định ngắn |
|---|-----------|:----:|----------------|
| 1 | Visibility of system status | 4/5 | Loading tốt (shimmer/spinner phủ rộng), nhưng feedback sau hành động (snackbar) không phân biệt success/error bằng màu. |
| 2 | Match real world | 4/5 | Tiếng Việt đúng nghiệp vụ, nhưng thông báo lỗi rò thuật ngữ kỹ thuật (DioException, detail null). |
| 3 | User control & freedom | 3/5 | Có confirm dialog (14 màn) nhưng thiếu Undo; hành động phá hủy thiếu "vùng nguy hiểm" tách biệt. |
| 4 | Consistency & standards | 4/5 | Tokens + EmptyView + Pill chuẩn hóa tốt; nhưng loading lẫn lộn shimmer vs spinner, snackbar mỗi nơi một kiểu. |
| 5 | Error prevention | 3/5 | Validate cơ bản có, nhưng nút submit không disable theo điều kiện + thiếu tooltip "vì sao chưa bấm được". |
| 6 | Recognition over recall | 4/5 | Sidebar grouped, breadcrumb, badge count tốt; form dài (tạo cuộc thi) bắt nhớ nhiều trường cùng lúc. |
| 7 | Flexibility & efficiency | 3/5 | Có ⌘K hint, bulk approve; thiếu phím tắt chấm điểm, thiếu lưu nháp form. |
| 8 | Aesthetic & minimalist | 4/5 | Dashboard rich đẹp; vài màn admin nhồi nhiều số liệu cùng cấp ưu tiên. |
| 9 | Help users with errors | 2/5 | **Yếu nhất.** Lỗi kỹ thuật, không gợi ý cách sửa, không phân màu. |
| 10 | Help & documentation | 3/5 | WorkflowGuide (BTC) là điểm sáng; thiếu onboarding lần đầu cho SV, thiếu tooltip ngữ cảnh. |

**Hai điểm yếu hệ thống cần ưu tiên: #9 (help with errors) và #5 (error prevention).**

## A.2 Sinh viên (SV) — đối tượng đông nhất

Màn: home, contest_list, contest_detail, register, submission, leaderboard, my_registrations, my_results, my_certificates, my_calendar, notifications, profile, edit_profile, team_management.

Điểm mạnh: countdown timer, leaderboard podium + highlight "BẠN", progress bar 5-stage, notifications time-bucket, certificate cards 🥇🥈🥉 — đều thân thiện và tạo cảm xúc tốt.

Vấn đề:

- **[Major] Empty state không CTA.** `contest_list_screen.dart:163` dùng `EmptyView` nhưng không nút. SV chưa đăng ký gì ở `my_registrations` / `my_results` / `my_certificates` thấy màn trống không lối đi → nên có nút "Khám phá cuộc thi đang mở".
- **[Major] Nộp bài thiếu xác nhận rõ.** `submission_screen.dart` dùng SnackBar trần — SV không chắc đã nộp thành công, dễ nộp lại nhiều lần. Cần dialog xác nhận trước + toast success rõ ràng sau.
- **[Minor] Onboarding lần đầu vắng.** Có `features/onboarding/` nhưng SV mới không được dẫn "đi đâu trước". Home nên có 1 dòng gợi ý cá nhân hóa ("Sắp hết hạn nộp: X — còn 2 ngày").
- **[Minor] Trạng thái hồ sơ/đăng ký.** Cần badge màu + icon rõ 3 trạng thái Đã duyệt / Chờ / Từ chối ngay trong danh sách.

Điểm actor: **7.5/10**

## A.3 GV / BTC

Màn: admin_dashboard (rich), admin_contests, create_contest_dialog, judge_screen, gv_extra_screens, contest_admin_detail.

Điểm mạnh: `_BTCDashboardRich` (stat cards trend, 2-col cuộc thi/lịch), WorkflowGuide — đúng hướng giảm tải.

Vấn đề:

- **[Major] Form tạo cuộc thi tải nhận thức cao.** `create_contest_dialog.dart` nhiều trường một lần. Nên chia stepper + lưu nháp + autofocus trường đầu.
- **[Major] Chấm bài thiếu hiệu suất.** `judge_screen.dart` thiếu phím tắt điểm + điều hướng bài kế tiếp; thiếu lưu tự động.
- **[Minor] Submit cuộc thi cho BCN** (`admin_contests_screen.dart:308`) báo bằng SnackBar trần, không nêu "bước tiếp theo: chờ BCN duyệt QĐ1".

Điểm actor: **6.5/10**

## A.4 BCN

Màn: approval_queue, monitor, bcn_extra_screens, BcnCertTemplatesScreen, _BCNDashboardRich.

Điểm mạnh: Queue ưu tiên SLA color-coded, donut hiệu suất, badge live count sidebar — nghiệp vụ rõ.

Vấn đề:

- **[Major] Bulk approve thiếu tóm tắt hậu quả.** Cần dialog "Duyệt N cuộc thi? Hành động này gửi thông báo tới SV." trước khi chạy.
- **[Major] Từ chối thiếu lý do bắt buộc + template.** Bắt buộc nhập lý do, kèm 3–4 mẫu chọn nhanh để không gõ lại.
- **[Minor] Empty queue** (`approval_queue_screen.dart:492`) dùng EmptyView nhưng nên thêm subtitle trấn an "Tất cả đề xuất đã xử lý xong 🎉".

Điểm actor: **7/10**

## A.5 Admin

Màn: admin_users, configs, master_data, audit_log, anomaly_reports, review_moderation, monitor.

Điểm mạnh: SystemHealth + AuditTail, audit log đầy đủ.

Vấn đề:

- **[Major] Hành động phá hủy không tách "vùng nguy hiểm".** Xóa tài khoản / backfill nằm cạnh nút thường (`admin_users_screen.dart`, `configs_screen.dart`). Nên tách Danger Zone + confirm gõ-xác-nhận cho thao tác không hồi phục.
- **[Major] Lỗi lộ kỹ thuật nặng nhất ở admin.** `admin_dashboard_screen.dart:610` ghép thẳng `DioException.response.data['detail']` ra UI.
- **[Minor] Thiếu Undo** cho thao tác đảo được (đổi role) — hiện chỉ confirm.

Điểm actor: **6/10**

---

# B. Micro-copy & empty-state paste-ready

Mục tiêu: sửa tập trung tại widget dùng chung để lan tỏa toàn app, thay vì sửa rải rác 23 file.

## B.1 Helper feedback nhất quán — `AppToast`

Tạo file mới `frontend/lib/core/widgets/app_toast.dart`. Thay mọi `ScaffoldMessenger...showSnackBar(SnackBar(content: Text(...)))` bằng `AppToast.success(context, '...')` / `AppToast.error(context, e)`.

```dart
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../errors/friendly_error.dart';

/// Snackbar thống nhất: phân biệt success/error/info bằng màu + icon.
/// Thay thế mọi SnackBar trần rải rác (23 file). Visibility of system status (H1).
class AppToast {
  static void success(BuildContext context, String message) =>
      _show(context, message, _Kind.success);

  static void info(BuildContext context, String message) =>
      _show(context, message, _Kind.info);

  /// Nhận message string HOẶC object lỗi (Exception/DioException) — tự map sang
  /// câu thân thiện qua FriendlyError. Help users recognize/recover (H9).
  static void error(BuildContext context, Object error) =>
      _show(context, FriendlyError.of(error), _Kind.error);

  static void _show(BuildContext context, String msg, _Kind kind) {
    final (icon, color) = switch (kind) {
      _Kind.success => (Icons.check_circle_outline, context.successGreen),
      _Kind.error => (Icons.error_outline, context.ptitRed),
      _Kind.info => (Icons.info_outline, context.textMuted),
    };
    final m = ScaffoldMessenger.of(context);
    m.clearSnackBars();
    m.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.cardColor,
      duration: Duration(seconds: kind == _Kind.error ? 5 : 3),
      content: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: TextStyle(color: context.textPrimary))),
      ]),
    ));
  }
}

enum _Kind { success, error, info }
```

> Lưu ý: dùng getter có sẵn `context.successGreen` (đã có trong `app_colors.dart`, cùng `successSoft`). Các token `ptitRed`, `cardColor`, `textPrimary`, `textMuted` cũng sẵn có.

## B.2 Bộ chuyển lỗi kỹ thuật → câu thân thiện — `FriendlyError`

Tạo `frontend/lib/core/errors/friendly_error.dart`. Tập trung mọi logic "đọc DioException" về 1 nơi (hiện đang lặp ở `admin_dashboard_screen.dart:610`, `admin_contests_screen.dart:428`, `anomaly_reports_screen.dart:283`...).

```dart
import 'package:dio/dio.dart';

/// Map lỗi kỹ thuật → tiếng Việt thân thiện, có gợi ý hành động.
class FriendlyError {
  static String of(Object error) {
    if (error is DioException) return _dio(error);
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  static String _dio(DioException e) {
    // Ưu tiên message nghiệp vụ từ backend nếu là câu tiếng Việt rõ nghĩa.
    final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
    final status = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Kết nối quá chậm. Kiểm tra mạng rồi thử lại.';
      case DioExceptionType.connectionError:
        return 'Không kết nối được máy chủ. Kiểm tra mạng hoặc thử lại sau.';
      default:
        break;
    }
    return switch (status) {
      400 => detail is String ? detail : 'Dữ liệu chưa hợp lệ. Kiểm tra lại các trường.',
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy nội dung. Có thể đã bị xóa hoặc di chuyển.',
      409 => detail is String ? detail : 'Thao tác bị trùng hoặc xung đột trạng thái.',
      422 => detail is String ? detail : 'Dữ liệu chưa đúng định dạng yêu cầu.',
      >= 500 => 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau ít phút.',
      _ => detail is String ? detail : 'Có lỗi xảy ra. Vui lòng thử lại.',
    };
  }
}
```

Trước/sau (admin_dashboard_screen.dart:610–612):

```dart
// TRƯỚC — lộ kỹ thuật:
final msg = ... (error as DioException).response?.data['detail'] ... ;
return MCard(child: Text('Lỗi: $msg', style: const TextStyle(color: ptitRed)));

// SAU — thân thiện + tái dùng:
return MCard(child: Text(FriendlyError.of(error),
    style: const TextStyle(color: ptitRed)));
```

## B.3 Empty states có CTA — mẫu theo từng màn

`EmptyView` đã hỗ trợ `action:` sẵn nhưng chưa màn nào dùng. Bộ mẫu dán thẳng:

```dart
// SV — my_registrations rỗng
EmptyView(
  icon: Icons.how_to_reg_outlined,
  title: 'Bạn chưa đăng ký cuộc thi nào',
  subtitle: 'Khám phá các cuộc thi đang mở và ghi danh ngay hôm nay.',
  action: FilledButton.icon(
    icon: const Icon(Icons.search),
    label: const Text('Khám phá cuộc thi'),
    onPressed: () => _goToContestsTab(), // điều hướng tới tab Cuộc thi (student_shell dùng tab index)
  ),
)

// SV — my_certificates rỗng
EmptyView(
  icon: Icons.workspace_premium_outlined,
  title: 'Chưa có chứng nhận nào',
  subtitle: 'Hoàn thành và đạt giải một cuộc thi để nhận chứng nhận đầu tiên.',
)

// SV — my_results rỗng
EmptyView(
  icon: Icons.emoji_events_outlined,
  title: 'Chưa có kết quả',
  subtitle: 'Kết quả sẽ xuất hiện sau khi cuộc thi bạn tham gia được chấm xong.',
)

// BTC — admin_contests rỗng
EmptyView(
  icon: Icons.emoji_events_outlined,
  title: 'Chưa có cuộc thi nào',
  subtitle: 'Tạo cuộc thi đầu tiên để bắt đầu tổ chức.',
  action: FilledButton.icon(
    icon: const Icon(Icons.add),
    label: const Text('Tạo cuộc thi'),
    onPressed: _openCreateDialog,
  ),
)

// BCN — approval_queue rỗng (trấn an, không phải lỗi)
const EmptyView(
  icon: Icons.task_alt,
  title: 'Tất cả đề xuất đã được xử lý 🎉',
  subtitle: 'Không còn cuộc thi nào chờ duyệt. Quay lại sau nhé.',
)

// Notifications rỗng
const EmptyView(
  icon: Icons.notifications_none,
  title: 'Chưa có thông báo',
  subtitle: 'Các cập nhật về cuộc thi và bài nộp sẽ hiện ở đây.',
)
```

## B.4 Xác nhận hành động — bộ micro-copy chuẩn

```text
Nộp bài (SV):
  Tiêu đề: "Xác nhận nộp bài?"
  Nội dung: "Sau khi nộp, bạn vẫn có thể nộp lại bản mới trước hạn. Tiếp tục?"
  Nút: [Hủy] [Nộp bài]
  Toast sau: AppToast.success(context, 'Đã nộp bài thành công. BTC sẽ chấm sau khi vòng kết thúc.')

Bulk approve (BCN):
  Tiêu đề: "Duyệt {N} cuộc thi?"
  Nội dung: "Hệ thống sẽ gửi thông báo tới ban tổ chức các cuộc thi này. Không thể hoàn tác."
  Nút: [Xem lại] [Duyệt tất cả]

Từ chối (BCN):
  Bắt buộc ô "Lý do từ chối" + chip mẫu:
    "Thiếu thông tin thể lệ" · "Sai thời gian" · "Trùng cuộc thi khác" · "Chưa gán khoa"
  Toast: AppToast.info(context, 'Đã gửi yêu cầu chỉnh sửa tới ban tổ chức.')

Xóa tài khoản (Admin) — không hồi phục:
  Tiêu đề: "Xóa tài khoản {email}?"
  Nội dung: "Hành động này KHÔNG THỂ hoàn tác. Gõ 'XOA' để xác nhận."
  Ô nhập xác nhận + nút [Xóa] chỉ bật khi gõ đúng.
```

## B.5 Bảng tra cứu micro-copy lỗi thường gặp

| Tình huống | Trước (kỹ thuật) | Sau (thân thiện) |
|---|---|---|
| host_faculty_id null | "Lỗi: host_faculty_id null" | "Cuộc thi chưa được gán khoa. Liên hệ BCN để xử lý." |
| Cert 404 | "Lỗi: 404 Not Found" | "Chứng nhận không tồn tại hoặc đã bị thu hồi." |
| Mạng lỗi | "DioException [connectionError]" | "Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại." |
| 401 | "Lỗi: 401" | "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại." |
| Validate form | "422 Unprocessable" | "Vui lòng kiểm tra lại: {tên trường} chưa hợp lệ." |
| Quá hạn nộp | "403" | "Đã quá hạn nộp bài cho vòng này." |

---

# C. Backlog sprint có ước lượng công sức

Ước lượng theo giờ cho 1 lập trình viên quen codebase. P0 = nền tảng phải làm trước (các P khác dựa vào).

## C.1 Sprint 29 — Nền tảng feedback (ưu tiên cao nhất)

| ID | Việc | Heuristic | Ước lượng | Tiêu chí done |
|----|------|:---------:|:---------:|---------------|
| F1 | Tạo `FriendlyError` (B.2) | H9, H2 | 2h | Map đủ 400/401/403/404/409/422/5xx + timeout/connection |
| F2 | Tạo `AppToast` + `successColor` token (B.1) | H1 | 2h | Success/error/info có màu+icon; light & dark OK |
| F3 | Thay 23 file SnackBar → AppToast | H1, H4 | 4h | `grep "SnackBar(" features` = 0 chỗ trần |
| F4 | Thay các chỗ đọc DioException raw → FriendlyError | H9 | 2h | Không còn `response.data['detail']` lộ ra UI |

Tổng: **~1.5 ngày**. ROI cao nhất, rủi ro thấp (tập trung tại widget chung).

## C.2 Sprint 30 — Empty states & onboarding

| ID | Việc | Heuristic | Ước lượng | Tiêu chí done |
|----|------|:---------:|:---------:|---------------|
| E1 | Gắn CTA cho 6 empty state SV/BTC/BCN (B.3) | H10 | 4h | Mỗi list rỗng có icon + câu + nút điều hướng phù hợp |
| E2 | Phủ EmptyView cho các màn còn thiếu (~10 màn) | H4 | 3h | Không còn màn rỗng "trắng tinh" |
| E3 | Gợi ý cá nhân hóa ở SV Home ("sắp hết hạn") | H1, H10 | 4h | Hiện deadline gần nhất + nút đi tới |
| E4 | Onboarding 3 bước lần đầu cho SV | H10 | 6h | Hiện 1 lần, lưu cờ SharedPreferences |

Tổng: **~2 ngày**.

## C.3 Sprint 31 — Error prevention & control

| ID | Việc | Heuristic | Ước lượng | Tiêu chí done |
|----|------|:---------:|:---------:|---------------|
| P1 | Dialog xác nhận nộp bài + toast success (B.4) | H3, H5 | 2h | SV thấy rõ trước/sau khi nộp |
| P2 | Bulk approve dialog tóm tắt hậu quả (BCN) | H5 | 2h | Hiện số lượng + cảnh báo trước khi chạy |
| P3 | Từ chối bắt buộc lý do + chip mẫu (BCN) | H5, H7 | 3h | Không gửi được khi rỗng; có 4 mẫu nhanh |
| P4 | Danger Zone + gõ-xác-nhận cho xóa tài khoản (Admin) | H3, H5 | 3h | Nút phá hủy tách riêng, confirm gõ "XOA" |
| P5 | Disable nút submit theo điều kiện + tooltip lý do | H5 | 3h | Form tạo cuộc thi: nút mờ + tooltip khi thiếu trường |

Tổng: **~2 ngày**.

## C.4 Sprint 32 — Hiệu suất & polish (P2/P3)

| ID | Việc | Heuristic | Ước lượng |
|----|------|:---------:|:---------:|
| Q1 | Stepper + lưu nháp form tạo cuộc thi | H6 | 6h |
| Q2 | Phím tắt chấm điểm + "bài kế tiếp" (judge) | H7 | 4h |
| Q3 | Undo cho đổi role (Admin) | H3 | 3h |
| Q4 | Badge màu+icon trạng thái đăng ký (SV list) | H6 | 2h |
| Q5 | Tooltip ngữ cảnh các icon-only button | H10 | 3h |

Tổng: **~2.5 ngày**.

## C.5 Lộ trình & ROI

```
Sprint 29 (feedback)   ██████  ROI ★★★★★  rủi ro thấp  → làm trước
Sprint 30 (empty/onboard) ████  ROI ★★★★   rủi ro thấp
Sprint 31 (prevention)  ████   ROI ★★★★   rủi ro vừa
Sprint 32 (polish)      ███    ROI ★★★    rủi ro vừa
```

Tổng toàn bộ: **~8 ngày công**. Nếu chỉ làm Sprint 29 + E1/E3 (nửa Sprint 30) đã nâng cảm nhận thân thiện rõ rệt trong ~2.5 ngày.

---

## Phụ lục — file tham chiếu

- Empty state: `frontend/lib/core/widgets/empty_view.dart` (đã có slot `action:`)
- Snackbar trần (23 file): xem `grep -rn "SnackBar(" frontend/lib/features`
- Lỗi raw DioException: `admin_dashboard_screen.dart:610`, `admin_contests_screen.dart:428`, `anomaly_reports_screen.dart:283`
- Confirm dialog hiện có (14 file): `grep -rln "AlertDialog\|showDialog" frontend/lib/features`
- Design tokens: `frontend/lib/core/app_colors.dart`

> Ghi chú: audit grounded trong source code (authoritative cho mức tuân thủ heuristic). Để bổ sung screenshot từng màn theo trạng thái thật (loading/empty/error), cần chạy stack Docker local rồi rà bằng Chrome — có thể làm như bước follow-up.
