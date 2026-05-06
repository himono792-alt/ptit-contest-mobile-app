// SV-02 Forgot password — STEP 1: Request reset.
//
// Nhập email → POST /auth/forgot-password → backend trả token (dev mode)
// → navigate sang ForgotPasswordResetScreen với token pre-filled.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import 'forgot_password_reset_screen.dart';

class ForgotPasswordRequestScreen extends ConsumerStatefulWidget {
  const ForgotPasswordRequestScreen({super.key});
  @override
  ConsumerState<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState
    extends ConsumerState<ForgotPasswordRequestScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _msg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio
          .post('/auth/forgot-password', data: {'email': email});
      final d = res.data as Map<String, dynamic>;
      final devToken = d['dev_reset_token'] as String?;
      if (!mounted) return;
      // Nav sang step 2 với token pre-filled (dev mode) hoặc rỗng (prod)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ForgotPasswordResetScreen(
            email: email,
            prefilledToken: devToken,
          ),
        ),
      );
    } on DioException catch (e) {
      setState(() => _msg = e.response?.data is Map
          ? '${e.response?.data['detail']}'
          : (e.message ?? 'Lỗi'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.appBg,
        appBar: AppBar(
          title: const Text('Quên mật khẩu'),
          leading: IconButton(
            // Sprint 3 a11y fix: tooltip cho back arrow IconButton
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: context.ptitRedSoft,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Icon(Icons.lock_reset,
                            color: ptitRed, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quên mật khẩu?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nhập email PTIT để nhận link reset mật khẩu.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textMuted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Email PTIT',
                        hintText: 'b22dccn001@ptit.edu.vn',
                        prefixIcon: Icon(Icons.mail_outline, size: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Cần nhập email';
                        if (!v.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                      onFieldSubmitted: (_) => _request(),
                    ),
                    if (_msg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: context.ptitRedSoft,
                            borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: ptitRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_msg!,
                                style: const TextStyle(
                                    fontSize: 12, color: ptitRed)),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _busy ? null : _request,
                      icon: _busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 16),
                      label: Text(_busy ? 'Đang gửi...' : 'Gửi yêu cầu reset'),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      // TextButton.icon đã có label 'Quay về đăng nhập' làm
                      // accessible name → không cần thêm tooltip (TextButton.icon
                      // KHÔNG support param tooltip).
                      child: TextButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 14),
                        label: const Text('Quay về đăng nhập'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
