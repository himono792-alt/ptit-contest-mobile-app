import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/secure_storage.dart';
import '../../core/theme.dart';
import 'forgot_password_request_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'b22dccn001@ptit.edu.vn');
  final _pwdCtrl = TextEditingController(text: 'abc123');
  bool _loading = false;
  bool _showPwd = false;
  String? _error;

  // Phase 2 sprint 1 step 4 (2026-05-06): biometric login button visibility.
  // Hiện button "Đăng nhập sinh trắc" nếu user đã enable + có refresh token + device support.
  bool _biometricVisible = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final storage = ref.read(tokenStorageProvider);
    final enabled = await storage.isBiometricEnabled();
    final hasRefresh = (await storage.readRefreshToken())?.isNotEmpty ?? false;
    final available = await BiometricService.instance.isAvailable();
    if (!mounted) return;
    setState(() {
      _biometricVisible = enabled && hasRefresh && available;
    });
    // Auto-prompt khi mở app — nếu user đã enabled, không cần tap
    if (_biometricVisible) {
      _biometricLogin();
    }
  }

  Future<void> _biometricLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await ref.read(authProvider.notifier).tryBiometricLogin();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Đăng nhập sinh trắc thất bại — hãy nhập email + mật khẩu.';
      });
    }
    // Nếu success → authProvider tự update state → router redirect khỏi /login
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(_emailCtrl.text.trim(), _pwdCtrl.text);
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map
            ? (e.response?.data['detail']?.toString() ?? 'Lỗi đăng nhập')
            : 'Không kết nối được server';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                // ============ Logo + welcome ============
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: ptitGradientHero,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                            color: ptitRed.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Center(
                      child: Text('P',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          )),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text('Chào mừng\ntrở lại 👋',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.85,
                      height: 1.15,
                    )),
                const SizedBox(height: 8),
                Text('Đăng nhập với email PTIT để tiếp tục.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: context.textMuted,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 26),

                // ============ Email field ============
                _Label(text: 'Email PTIT'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.mail_outline, size: 18),
                    hintText: 'b22dccn001@ptit.edu.vn',
                    fillColor: context.cardBg,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                ),
                const SizedBox(height: 14),

                // ============ Password field ============
                _Label(text: 'Mật khẩu'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: !_showPwd,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: context.textMuted),
                      onPressed: () => setState(() => _showPwd = !_showPwd),
                    ),
                    hintText: '••••••••',
                    fillColor: context.cardBg,
                    filled: true,
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                ),

                // ============ Forgot password link ============
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordRequestScreen()),
                    ),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Quên mật khẩu?',
                        style: GoogleFonts.plusJakartaSans(
                          color: ptitRed,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.ptitRedSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: ptitRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 16, color: ptitRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: GoogleFonts.plusJakartaSans(
                                color: ptitRed,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 12),

                // ============ Biometric button (Phase 2 step 4) ============
                // Hiện nếu user đã enable trong Profile + có refresh token + device support.
                if (_biometricVisible) ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.fingerprint, size: 22),
                    style: FilledButton.styleFrom(
                      backgroundColor: ptitRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _biometricLogin,
                    label: const Text('Đăng nhập bằng sinh trắc',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                ],

                // ============ Login button ============
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _biometricVisible ? Colors.white : ptitRed,
                    foregroundColor: _biometricVisible ? ptitRed : Colors.white,
                    side: _biometricVisible
                        ? const BorderSide(color: ptitRed, width: 1.5)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _biometricVisible ? ptitRed : Colors.white))
                      : Text(_biometricVisible
                          ? 'Đăng nhập bằng email'
                          : 'Đăng nhập'),
                ),

                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Container(height: 1, color: context.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('HOẶC',
                        style: GoogleFonts.plusJakartaSans(
                          color: context.textFaint,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        )),
                  ),
                  Expanded(child: Container(height: 1, color: context.cardBorder)),
                ]),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Đăng nhập bằng OTP'),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP login — chưa wire UI'))),
                ),

                const SizedBox(height: 28),
                // ============ Test accounts hint ============
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1ECE5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline, size: 14, color: context.textMuted),
                          const SizedBox(width: 6),
                          Text('Tài khoản demo',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary,
                                  letterSpacing: 0.3)),
                        ]),
                        const SizedBox(height: 6),
                        _DemoAccountRow(role: 'SV', email: 'b22dccn001@ptit.edu.vn'),
                        _DemoAccountRow(role: 'GV', email: 'gv@ptit.edu.vn'),
                        _DemoAccountRow(role: 'BCN', email: 'bcn@ptit.edu.vn'),
                        const SizedBox(height: 4),
                        Text('Mật khẩu chung: abc123',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: context.textMuted,
                                fontWeight: FontWeight.w500)),
                      ]),
                ),

                const SizedBox(height: 16),
                // ============ Footer ============
                Center(
                  child: Text('POST /api/auth/login · JWT HS256',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: context.textFaint,
                        fontWeight: FontWeight.w500,
                      )),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: context.textMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ));
}

class _DemoAccountRow extends StatelessWidget {
  final String role;
  final String email;
  const _DemoAccountRow({required this.role, required this.email});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: ptitRed,
            borderRadius: BorderRadius.circular(AppRadius.tight),
          ),
          child: Text(role,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1.2)),
        ),
        const SizedBox(width: 6),
        Text(email,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                color: context.textPrimary,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
