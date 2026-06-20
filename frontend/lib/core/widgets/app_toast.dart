import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../errors/friendly_error.dart';
import '../spacing.dart';

/// Snackbar nhất quán: phân biệt success/error/info bằng màu + icon.
/// Thay thế mọi SnackBar trần rải rác (23 file). Nielsen H1 + H9.
class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _Kind.success);

  /// Success toast with an "Hoàn tác" action button.
  static void successWithUndo(
      BuildContext context, String message, VoidCallback onUndo) {
    final (icon, color) = (Icons.check_circle_outline, context.successGreen);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.cardBg,
      duration: const Duration(seconds: 5),
      content: Row(children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.textPrimary),
          ),
        ),
      ]),
      action: SnackBarAction(label: 'Hoàn tác', onPressed: onUndo),
    ));
  }

  static void info(BuildContext context, String message) =>
      _show(context, message, _Kind.info);

  /// Nhận Exception/DioException — tự map sang câu thân thiện qua FriendlyError.
  static void error(BuildContext context, Object error) =>
      _show(context, FriendlyError.of(error), _Kind.error);

  static void _show(BuildContext context, String msg, _Kind kind) {
    final (icon, color) = switch (kind) {
      _Kind.success => (Icons.check_circle_outline, context.successGreen),
      _Kind.error   => (Icons.error_outline, context.ptitRed),
      _Kind.info    => (Icons.info_outline, context.infoBlue),
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.cardBg,
      duration: Duration(seconds: kind == _Kind.error ? 5 : 3),
      content: Row(children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            msg,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textPrimary),
          ),
        ),
      ]),
    ));
  }
}

enum _Kind { success, error, info }
