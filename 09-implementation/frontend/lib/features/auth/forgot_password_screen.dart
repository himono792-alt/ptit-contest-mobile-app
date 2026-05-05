// SV-02 Forgot password — 2 step inline:
//   1. Nhập email → POST /auth/forgot-password → backend trả token (dev mode)
//   2. Paste token + new password → POST /auth/reset-password → đổi xong → quay về login
//
// Production sẽ đổi step 1 thành "đã gửi email link", step 2 redirect từ link.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _busy = false;
  String? _step1Msg;
  String? _step2Error;
  bool _step2Done = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _step1Msg = '✗ Email không hợp lệ');
      return;
    }
    setState(() {
      _busy = true;
      _step1Msg = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/auth/forgot-password', data: {'email': email});
      final d = res.data as Map<String, dynamic>;
      // Dev mode: backend trả `dev_reset_token` để dán vào step 2
      final devToken = d['dev_reset_token'] as String?;
      if (devToken != null) {
        _tokenCtrl.text = devToken;
        setState(() => _step1Msg = '✓ Token đã tạo (dev mode auto-fill bên dưới)');
      } else {
        setState(() => _step1Msg =
            '✓ ${d['message'] ?? "Nếu email tồn tại, đã gửi link reset"}');
      }
    } on DioException catch (e) {
      setState(() => _step1Msg = '✗ ${_msg(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final token = _tokenCtrl.text.trim();
    final pwd = _newPwdCtrl.text;
    final confirm = _confirmPwdCtrl.text;
    if (token.isEmpty) {
      setState(() => _step2Error = 'Cần token reset');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _step2Error = 'Mật khẩu mới ≥ 6 ký tự');
      return;
    }
    if (pwd != confirm) {
      setState(() => _step2Error = 'Xác nhận mật khẩu không khớp');
      return;
    }
    setState(() {
      _busy = true;
      _step2Error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/auth/reset-password',
          data: {'reset_token': token, 'new_password': pwd});
      setState(() => _step2Done = true);
    } on DioException catch (e) {
      setState(() => _step2Error = _msg(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _msg(DioException e) =>
      e.response?.data is Map ? '${e.response?.data['detail']}' : (e.message ?? 'Lỗi');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: appBg,
        appBar: AppBar(
          title: const Text('Quên mật khẩu'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _step2Done ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('1. Nhập email PTIT',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
      const SizedBox(height: 8),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'b22dccn001@ptit.edu.vn',
          prefixIcon: Icon(Icons.mail_outline, size: 18),
        ),
      ),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _busy ? null : _requestReset,
        icon: _busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send, size: 16),
        label: const Text('Yêu cầu reset'),
      ),
      if (_step1Msg != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _step1Msg!.startsWith('✓') ? successSoft : ptitRedSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_step1Msg!,
              style: TextStyle(
                  fontSize: 12,
                  color: _step1Msg!.startsWith('✓') ? successGreen : ptitRed)),
        ),
      ],
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      const Text('2. Nhập token + mật khẩu mới',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
      const SizedBox(height: 8),
      TextField(
        controller: _tokenCtrl,
        decoration: const InputDecoration(
          labelText: 'Reset token *',
          hintText: 'Paste token từ email (hoặc auto-fill ở dev mode)',
          prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
        ),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _newPwdCtrl,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Mật khẩu mới (≥ 6 ký tự)',
          prefixIcon: Icon(Icons.lock_outline, size: 18),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _confirmPwdCtrl,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Xác nhận mật khẩu',
          prefixIcon: Icon(Icons.lock_outline, size: 18),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _busy ? null : _resetPassword,
        icon: const Icon(Icons.check, size: 16),
        label: const Text('Đổi mật khẩu'),
      ),
      if (_step2Error != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: ptitRedSoft, borderRadius: BorderRadius.circular(8)),
          child: Text('✗ $_step2Error',
              style: const TextStyle(fontSize: 12, color: ptitRed)),
        ),
      ],
    ]);
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        const Icon(Icons.check_circle_outline, size: 64, color: successGreen),
        const SizedBox(height: 16),
        const Text('Đổi mật khẩu thành công',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: successGreen)),
        const SizedBox(height: 8),
        const Text(
          'Bạn có thể đăng nhập bằng mật khẩu mới',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.login, size: 16),
          label: const Text('Quay về đăng nhập'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }
}
