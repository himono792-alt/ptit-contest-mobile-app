// Sprint 19 (2026-05-08): redesign theo design folder ảnh login web/mobile.
// - Web ≥768: 2-column layout (left branding banner gradient red + right form)
// - Mobile <768: stack vertical như cũ
// - Form: role tabs decorative + Ghi nhớ tôi + SSO disabled "Coming soon"
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/secure_storage.dart';
import '../../core/theme.dart';
import 'forgot_password_request_screen.dart';

/// Sprint 19 (2026-05-08): SharedPreferences key cho "Ghi nhớ tôi".
const _kRememberMeKey = 'login.remember_me';
const _kRememberedEmailKey = 'login.remembered_email';

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
  bool _rememberMe = false;
  // Sprint 19: role tab decorative — không filter login API (login tự detect role).
  // Chỉ thay đổi hint email + label cho UX rõ ràng.
  int _selectedRoleTab = 0; // 0=SV, 1=GV/BTC, 2=BCN, 3=Admin

  // Phase 2 sprint 1 step 4 (2026-05-06): biometric login button visibility.
  bool _biometricVisible = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool(_kRememberMeKey) ?? false;
    final email = prefs.getString(_kRememberedEmailKey);
    if (!mounted) return;
    setState(() {
      _rememberMe = remembered;
      if (remembered && email != null && email.isNotEmpty) {
        _emailCtrl.text = email;
      }
    });
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberMeKey, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_kRememberedEmailKey, _emailCtrl.text.trim());
    } else {
      await prefs.remove(_kRememberedEmailKey);
    }
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
      // Sprint 19: persist Ghi nhớ tôi BEFORE login (nếu fail vẫn nhớ email)
      await _saveRememberMe();
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
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 900;
            if (isWide) {
              return Row(children: [
                Expanded(flex: 5, child: _buildBrandingPanel(context)),
                Expanded(flex: 5, child: _buildFormPanel(context, scrollable: true)),
              ]);
            }
            return _buildFormPanel(context, scrollable: true);
          },
        ),
      ),
    );
  }

  /// Sprint 19 S19-1: branding panel left side cho web ≥900.
  /// Gradient red + logo + headline + description + 4 stats hard-coded.
  Widget _buildBrandingPanel(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ptitGradientHero),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + brand
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text('P',
                    style: GoogleFonts.plusJakartaSans(
                        color: ptitRed,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
              ),
            ),
            const SizedBox(width: 12),
            Text('PTIT Contest',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ]),
          // Headline + description
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hệ thống quản lý\ncuộc thi của\nHọc viện CNBCVT',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.15)),
              const SizedBox(height: 16),
              Text(
                  'Đăng nhập bằng tài khoản nội bộ. Hệ thống phân quyền theo vai trò: Sinh viên, Giảng viên / BTC, Ban Chủ nhiệm khoa, Ban Quản trị.',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.6)),
              const SizedBox(height: 36),
              // 4 stats grid
              Row(children: const [
                Expanded(child: _BrandStat(value: '1,847', label: 'TÀI KHOẢN')),
                Expanded(child: _BrandStat(value: '42', label: 'CUỘC THI')),
                Expanded(child: _BrandStat(value: '12', label: 'KHOA')),
                Expanded(child: _BrandStat(value: '99.9%', label: 'UPTIME')),
              ]),
            ],
          ),
          // Footer build version
          Text('© 2026 PTIT · v1.0.0 · build #2026.05.08',
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Form panel right side. Bao gồm role tabs + email/pwd + remember + SSO.
  Widget _buildFormPanel(BuildContext context, {bool scrollable = false}) {
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          // Logo + welcome — chỉ show ở mobile (web đã có ở branding panel)
          if (MediaQuery.of(context).size.width < 900) ...[
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
                          letterSpacing: -1)),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          Text('Đăng nhập',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.85,
                height: 1.15,
              )),
          const SizedBox(height: 6),
          Text('Sử dụng tài khoản PTIT để truy cập.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: context.textMuted,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 22),

          // Sprint 19 S19-2: Role tabs decorative
          _RoleTabs(
            selected: _selectedRoleTab,
            onChanged: (i) => setState(() => _selectedRoleTab = i),
          ),
          const SizedBox(height: 18),

          // Email field
          _Label(text: _selectedRoleTab == 1 || _selectedRoleTab == 2 || _selectedRoleTab == 3
              ? 'Email PTIT / Mã cán bộ'
              : 'Email PTIT'),
          const SizedBox(height: 6),
          Semantics(
            label: 'Email PTIT',
            hint: 'Nhập email kết thúc bằng @ptit.edu.vn',
            textField: true,
            child: TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail_outline, size: 18),
                hintText: _hintForRole(_selectedRoleTab),
                fillColor: context.cardBg,
                filled: true,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
            ),
          ),
          const SizedBox(height: 14),

          // Password field
          _Label(text: 'Mật khẩu'),
          const SizedBox(height: 6),
          Semantics(
            label: 'Mật khẩu',
            hint: 'Tối thiểu 6 ký tự',
            textField: true,
            obscured: true,
            child: TextFormField(
              controller: _pwdCtrl,
              obscureText: !_showPwd,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  tooltip: _showPwd ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
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
          ),

          // Sprint 19 S19-2: Ghi nhớ tôi + Quên mật khẩu cùng row
          const SizedBox(height: 10),
          Row(children: [
            // Checkbox ghi nhớ
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                activeColor: ptitRed,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Text('Ghi nhớ tôi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            const Spacer(),
            Semantics(
              label: 'Quên mật khẩu',
              button: true,
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
          ]),

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

          // Biometric button
          if (_biometricVisible) ...[
            Semantics(
              label: 'Đăng nhập bằng sinh trắc',
              button: true,
              hint: 'Sử dụng FaceID hoặc vân tay',
              enabled: !_loading,
              child: FilledButton.icon(
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
            ),
            const SizedBox(height: 10),
          ],

          // Login button
          Semantics(
            label: 'Đăng nhập',
            button: true,
            hint: 'Đăng nhập với email và mật khẩu',
            enabled: !_loading,
            child: FilledButton(
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
          // Sprint 19 S19-2: SSO button disabled (Coming soon)
          Tooltip(
            message: 'Tích hợp SSO PTIT — sẽ sớm có',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.account_balance_outlined, size: 18),
              label: const Text('Đăng nhập SSO PTIT  ·  Coming soon'),
              onPressed: null, // disabled
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: context.cardBorder),
                foregroundColor: context.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Đăng nhập bằng OTP',
            button: true,
            hint: 'Nhận mã xác thực 6 chữ số qua email',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.message_outlined, size: 18),
              label: const Text('Đăng nhập bằng OTP'),
              onPressed: () => context.go('/otp-login'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
                'Đăng nhập phân quyền tự động theo vai trò tài khoản.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: context.textMuted,
                    fontWeight: FontWeight.w500)),
          ),

          const SizedBox(height: 24),
          // Test accounts hint (debug only)
          if (!kReleaseMode) ...[
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
            Center(
              child: Text('POST /api/auth/login · JWT HS256',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: context.textFaint,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );

    if (!scrollable) return form;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: form,
        ),
      ),
    );
  }

  String _hintForRole(int idx) {
    switch (idx) {
      case 0:
        return 'b22dccn001@ptit.edu.vn';
      case 1:
        return 'gv@ptit.edu.vn';
      case 2:
        return 'bcn@ptit.edu.vn';
      case 3:
        return 'admin@ptit.edu.vn';
      default:
        return 'email@ptit.edu.vn';
    }
  }
}

/// Sprint 19 S19-2: 4 chip role tabs decorative.
/// KHÔNG filter login API — chỉ thay đổi hint email + visual cue.
class _RoleTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _RoleTabs({required this.selected, required this.onChanged});

  static const _labels = ['Sinh viên', 'GV / BTC', 'BCN khoa', 'Quản trị'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.tight),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == i ? ptitRed : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppRadius.tight - 2),
                  ),
                  child: Center(
                    child: Text(_labels[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected == i
                              ? Colors.white
                              : context.textMuted,
                        )),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sprint 19 S19-1: stat khối trắng-trên-đỏ trong branding panel.
class _BrandStat extends StatelessWidget {
  final String value;
  final String label;
  const _BrandStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      ],
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
