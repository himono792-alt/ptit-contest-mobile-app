// Sprint 19 (2026-05-08) S19-3: Mobile onboarding 3 slides theo design.
// Hiện lần đầu user mở app — sau đó persist `onboarding_completed` flag để
// skip cho các lần mở sau.
//
// Slides:
//   1. Khám phá hàng chục cuộc thi mỗi học kỳ (trophy icon)
//   2. Đăng ký nhanh chỉ với vài chạm (register icon)
//   3. Theo dõi kết quả & nhận chứng nhận (cert icon)
//
// CTA: "Bỏ qua" top-right + dots indicator + "Tiếp tục"/"Bắt đầu" bottom button
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/theme.dart';

const String kOnboardingCompletedKey = 'onboarding.completed';

/// Sprint 19 S19-3: global flag để router redirect sync. main() sẽ load
/// trước runApp; OnboardingScreen sẽ set true khi user complete.
final ValueNotifier<bool> onboardingCompletedFlag = ValueNotifier<bool>(false);

/// Helper: check if onboarding đã hoàn thành (gọi từ router/main).
Future<bool> isOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kOnboardingCompletedKey) ?? false;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _index = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.emoji_events_outlined,
      title: 'Khám phá hàng chục\ncuộc thi mỗi học kỳ',
      description:
          'Lập trình, học thuật, sáng tạo — tất cả tại một nơi, đăng ký chỉ với vài chạm.',
    ),
    _SlideData(
      icon: Icons.app_registration_rounded,
      title: 'Đăng ký nhanh chóng\ndễ dàng',
      description:
          'Chọn cuộc thi, điền thông tin và nhận xác nhận từ Ban tổ chức trong vài giờ.',
    ),
    _SlideData(
      icon: Icons.workspace_premium_outlined,
      title: 'Theo dõi kết quả\n& nhận chứng nhận',
      description:
          'Bảng xếp hạng live, kết quả công bố cùng chứng nhận điện tử có QR xác thực.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingCompletedKey, true);
    onboardingCompletedFlag.value = true; // Sprint 19: sync flag cho router
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: context.appBg,
      body: SafeArea(
        child: Column(children: [
          // Skip button top-right
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text('Bỏ qua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textMuted,
                    )),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _Slide(data: _slides[i]),
            ),
          ),
          // Dots indicator
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? ptitRed : context.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ),
          // Continue / Start button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: ptitRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(isLast ? 'Bắt đầu' : 'Tiếp tục',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String description;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration: large icon trong rounded card với bg subtle
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: context.ptitRedSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: ptitGradientHero,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(data.icon, size: 64, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.6,
                height: 1.2,
              )),
          const SizedBox(height: 12),
          Text(data.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: context.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.55,
              )),
        ],
      ),
    );
  }
}
