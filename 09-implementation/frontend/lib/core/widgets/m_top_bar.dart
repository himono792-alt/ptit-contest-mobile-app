import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: cardBorder)),
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
                  color: textPrimary,
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
