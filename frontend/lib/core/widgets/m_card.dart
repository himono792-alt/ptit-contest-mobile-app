import 'package:flutter/material.dart';
import '../theme.dart';

/// Card matching mockup tokens.css:
///   - background white (bg-elev)
///   - radius r-md = 14px
///   - soft shadow (shadow-sm) thay vì border (border làm card "khô")
///   - padding 16
class MCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool flat;

  const MCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorder = borderColor != null;
    // Phase 2 Sprint 2 Step 1b (2026-05-06): đọc cardColor từ Theme.of()
    // → tự invert sang cardBgDark (#25211D) trong dark mode.
    // Caller có thể override qua backgroundColor prop.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultCardColor = isDark
        ? Theme.of(context).cardColor
        : Colors.white;
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultCardColor,
        border: hasBorder ? Border.all(color: borderColor!, width: 1) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: flat ? null : (hasBorder ? null : shadowSm),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
