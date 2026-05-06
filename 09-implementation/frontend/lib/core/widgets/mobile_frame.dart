import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../theme.dart';

/// Wrap content vào max-width 400px khi chạy web (mobile UX).
class MobileFrame extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const MobileFrame({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !enabled) return child;
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Container(
          width: 400,
          decoration: BoxDecoration(color: context.appBg),
          clipBehavior: Clip.hardEdge,
          child: child,
        ),
      ),
    );
  }
}
