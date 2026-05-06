import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../theme.dart';

/// Phase 2 Sprint 2 Step 1c (2026-05-06): theme-aware Pill.
///
/// Trước đây factory `Pill.status` resolve color luôn lúc khởi tạo
/// → hard-code light tokens, dark mode không invert được.
///
/// Giờ factory chỉ encode "kind" (success/warn/info/danger/neutral),
/// còn resolve color thực sự sang `context.X` tokens tại `build()` time
/// → dark/light tự switch.
enum PillKind { neutral, success, warn, info, danger }

class Pill extends StatelessWidget {
  final String label;

  /// Theme-aware color category. Khi set, override `color`/`bg` explicit.
  final PillKind? kind;

  /// Explicit foreground (text + icon). Chỉ dùng khi `kind` = null.
  final Color? color;

  /// Explicit background. Chỉ dùng khi `kind` = null.
  final Color? bg;

  const Pill({
    super.key,
    required this.label,
    this.kind,
    this.color,
    this.bg,
  });

  /// Tạo Pill theo status string của BE.
  factory Pill.status(String status) {
    switch (status) {
      case 'REG_OPEN':
      case 'PUBLISHED':
      case 'APPROVED':
      case 'COMPLETED':
      case 'SUCCESS':
        return Pill(label: status, kind: PillKind.success);
      case 'ONGOING':
      case 'PENDING':
      case 'SUBMITTED':
      case 'PROPOSED':
      case 'LATE':
        return Pill(label: status, kind: PillKind.warn);
      case 'FINISHED':
      case 'CHECKED_IN':
        return Pill(label: status, kind: PillKind.info);
      case 'CANCELLED':
      case 'REJECTED':
      case 'LOCKED':
        return Pill(label: status, kind: PillKind.danger);
      default:
        return Pill(label: status, kind: PillKind.neutral);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve fg + bg theo kind tại build time (theme-aware).
    Color fg;
    Color? resolvedBg;
    switch (kind) {
      case PillKind.success:
        fg = context.successGreen;
        resolvedBg = context.successSoft;
        break;
      case PillKind.warn:
        fg = context.warnOrange;
        resolvedBg = context.warnSoft;
        break;
      case PillKind.info:
        fg = context.infoBlue;
        resolvedBg = context.infoSoft;
        break;
      case PillKind.danger:
        fg = ptitRed; // brand red — same in both themes
        resolvedBg = context.ptitRedSoft;
        break;
      case PillKind.neutral:
        fg = context.textMuted;
        resolvedBg = context.cardBorder.withValues(alpha: 0.6);
        break;
      case null:
        // Backward-compat: caller passed explicit color/bg.
        fg = color ?? context.textMuted;
        resolvedBg = bg;
        break;
    }
    final finalBg = bg ?? resolvedBg ?? fg.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: finalBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        // Sprint 4 fix C5 (2026-05-07): softWrap=false + maxLines=1 + overflow=visible
        // để badge KHÔNG wrap "FINISHE\nD" / "ONGOIN\nG" ở narrow column (admin
        // table 567px). Container width sẽ flex theo text natural width.
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
