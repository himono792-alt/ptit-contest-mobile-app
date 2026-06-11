// Sprint 19 fix flicker (2026-05-08): splash screen hiển thị trong khi
// `authProvider.build()` đang fetch /auth/me. Trước đây flicker StudentShell
// trên Android vài ms vì:
//   - App boot → router redirect callback chạy với `auth.isLoading == true`
//   - Code cũ `if (auth.isLoading) return null` → route mặc định `/` render
//   - Vài ms sau auth resolve → redirect /login
//
// Fix: trong khi loading → redirect /splash; khi resolve → SplashScreen tự
// observe auth state và navigate đúng landing (qua router redirect tự động).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/theme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.appBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: ptitGradientHero,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                      color: ptitRed.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Center(
                child: Text('P',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2)),
              ),
            ),
            const SizedBox(height: 22),
            Text('PTIT Contest',
                style: GoogleFonts.plusJakartaSans(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text('Đang khởi động…',
                style: GoogleFonts.plusJakartaSans(
                    color: context.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: ptitRed, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
