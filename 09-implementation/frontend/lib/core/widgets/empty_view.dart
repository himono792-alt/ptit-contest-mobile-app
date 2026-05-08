/// Sprint 8 P0 #1 (2026-05-07): EmptyView shared cho 28 screen.
///
/// Vi phạm `web-design-guidelines` dim 5 (component consistency): trước đây
/// mỗi screen tự roll Icon+Text khác biệt — admin_users dùng Center(Text) trống,
/// approval_queue dùng Column[Icon 56, Text 13], v.v.. Đồng bộ thành 1 widget
/// để zero drift + dễ thêm CTA pattern (vd: "Tạo cuộc thi" button cho admin
/// contest list trống).
///
/// Usage:
/// ```dart
/// const EmptyView(
///   icon: Icons.inbox_outlined,
///   title: 'Không có đề xuất nào đang chờ duyệt',
/// )
/// ```
///
/// With action:
/// ```dart
/// EmptyView(
///   icon: Icons.emoji_events_outlined,
///   title: 'Chưa có cuộc thi nào',
///   subtitle: 'Tạo cuộc thi đầu tiên để bắt đầu',
///   action: FilledButton.icon(
///     icon: const Icon(Icons.add),
///     label: const Text('Tạo cuộc thi'),
///     onPressed: () => ...,
///   ),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import '../app_colors.dart';

class EmptyView extends StatelessWidget {
  /// Icon hiển thị phía trên title. Mặc định `inbox_outlined`.
  /// Chọn icon phù hợp ngữ cảnh: `emoji_events_outlined` (cuộc thi),
  /// `notifications_none` (thông báo), `description_outlined` (bài nộp), v.v.
  final IconData icon;

  /// Tiêu đề chính. Bắt buộc, súc tích.
  final String title;

  /// Phụ đề giải thích thêm. Optional.
  final String? subtitle;

  /// Nút CTA tùy chọn. Khuyến nghị FilledButton hoặc OutlinedButton.
  final Widget? action;

  /// Kích thước icon. Sprint 18 (2026-05-08): default 72 thay vì 56 + bg circle
  /// theo design guidelines (illustration size). Override iconSize:56 để giữ
  /// pattern cũ nếu cần.
  final double iconSize;

  /// Sprint 18 S18-3: hiển thị icon trong subtle bg circle để rich hơn.
  /// Mặc định true; tắt nếu cần plain icon (vd compact list inline).
  final bool decoratedIcon;

  const EmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 72,
    this.decoratedIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = decoratedIcon
        ? Container(
            width: iconSize + 28,
            height: iconSize + 28,
            decoration: BoxDecoration(
              color: context.ptitRedSoft.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: iconSize * 0.7, color: context.textMuted),
          )
        : Icon(icon, size: iconSize, color: context.textMuted);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textMuted,
                  height: 1.5,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

