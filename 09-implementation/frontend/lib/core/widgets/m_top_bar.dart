import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../theme.dart';

class MTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  const MTopBar({super.key, required this.title, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        // Phase 2 Sprint 2 Step 1d (2026-05-06): theme-aware bg
        // → dark mode dùng cardBgDark (#25211D) thay vì Colors.white.
        color: context.cardBg,
        border: Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (leading != null) leading! else const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: context.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (actions != null) ...actions!,
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
