// SV-02 Forgot password — STEP 2: Reset với token + new password.
//
// Nhận email + token (pre-filled từ step 1 dev mode hoặc rỗng prod).
// User nhập new password + confirm → POST /auth/reset-password → success → quay về login.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme.dart';

class ForgotPasswordResetScreen extends ConsumerStatefulWidget {
  final String email;
  final String? prefilledToken;

  const ForgotPasswordResetScreen({
    super.key,
    required this.email,
    this.prefilledToken,
  });

  @override
  ConsumerState<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState
    extends ConsumerState<ForgotPasswordResetScreen> {
  late final TextEditingController _tokenCtrl;
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: widget.prefilledToken ?? '');
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/auth/reset-password', data: {
        'reset_token': _tokenCtrl.text.trim(),
        'new_password': _newPwdCtrl.text,
      });
      setState(() => _done = true);
    } catch (e) {
      setState(() => _error = FriendlyError.of(e));
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
          title: const Text('Reset mật khẩu'),
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
            child: _done ? _buildSuccess(context) : _buildForm(context),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.warnSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.vpn_key, color: context.warnOrange, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Reset mật khẩu cho\n${widget.email}',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          widget.prefilledToken != null
              ? '✓ Token đã auto-fill từ dev mode bên dưới'
              : 'Paste token từ email vào ô bên dưới',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              color: widget.prefilledToken != null ? context.successGreen : context.textMuted),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _tokenCtrl,
          decoration: const InputDecoration(
            labelText: 'Reset token *',
            hintText: 'Token nhận từ email',
            prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Cần nhập token' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _newPwdCtrl,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu mới *',
            helperText: 'Tối thiểu 6 ký tự',
            prefixIcon: Icon(Icons.lock_outline, size: 18),
          ),
          validator: (v) =>
              (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirmPwdCtrl,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Xác nhận mật khẩu mới *',
            prefixIcon: Icon(Icons.lock_outline, size: 18),
          ),
          validator: (v) => v != _newPwdCtrl.text ? 'Không khớp' : null,
          onFieldSubmitted: (_) => _reset(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: context.ptitRedSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Row(children: [
              const Icon(Icons.error_outline, size: 16, color: ptitRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ptitRed)),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _reset,
          icon: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 16),
          label: Text(_busy ? 'Đang đổi...' : 'Đổi mật khẩu'),
        ),
      ]),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.successSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: context.successGreen, size: 48),
        ),
        const SizedBox(height: 20),
        Text('Đổi mật khẩu thành công',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: context.successGreen)),
        const SizedBox(height: 8),
        Text(
          'Email: ${widget.email}\nĐăng nhập lại bằng mật khẩu mới.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textMuted, height: 1.5),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          icon: const Icon(Icons.login, size: 16),
          label: const Text('Quay về đăng nhập'),
          // Pop both Reset + Request screens, về login
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ]),
    );
  }
}
