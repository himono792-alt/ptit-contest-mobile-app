// Redesign 2026-06-20: nút (?) giải thích nghiệp vụ — dùng chung mọi màn.
// Cách dùng: HelpButton(id: 'gv_contests') trong actions của app bar / header.

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../help/help_content.dart';
import '../theme.dart';

class HelpButton extends StatelessWidget {
  final String id;
  final Color? color;
  final double size;
  const HelpButton({super.key, required this.id, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final info = kHelpContent[id];
    if (info == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Giải thích chức năng',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(Icons.help_outline,
          size: size, color: color ?? context.textMuted),
      onPressed: () => showHelpDialog(context, info),
    );
  }
}

Future<void> showHelpDialog(BuildContext context, HelpInfo info) {
  return showDialog(
    context: context,
    builder: (_) => _HelpDialog(info: info),
  );
}

class _HelpDialog extends StatelessWidget {
  final HelpInfo info;
  const _HelpDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề.
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: ptitRed.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.help_outline,
                      color: ptitRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(info.title,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: context.textPrimary)),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  icon: Icon(Icons.close, size: 20, color: context.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
              const SizedBox(height: 8),
              // Mở đầu.
              Text(info.intro,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: context.textMuted)),
              const SizedBox(height: 14),
              // Gạch đầu dòng.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in info.points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 10),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: ptitRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(p,
                                    style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: context.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ptitRed),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đã hiểu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
