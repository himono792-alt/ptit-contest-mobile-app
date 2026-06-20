/// Sprint 9 Group 1 (2026-05-07): Self-signup cho SV.
///
/// SV mới chưa có tài khoản → form full_name + email + password + confirm.
/// POST /auth/register → backend tạo user với role STUDENT mặc định.
/// Sau register thành công → chuyển sang /login với email pre-fill.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _showPass = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Mật khẩu nhập lại không khớp');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/auth/register', data: {
        'full_name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      });
      if (!mounted) return;
      AppToast.success(context, 'Tạo tài khoản thành công. Vui lòng đăng nhập.');
      // Quay về login để user nhập password mới đăng ký.
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = FriendlyError.of(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => context.go('/login'),
          tooltip: 'Quay lại đăng nhập',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.ptitRedSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_add_outlined,
                        color: ptitRed, size: 26),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Tạo tài khoản PTIT Contest',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đăng ký để tham gia các cuộc thi PTIT.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email PTIT',
                      prefixIcon: Icon(Icons.mail_outline, size: 18),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    enabled: !_busy,
                    obscureText: !_showPass,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        constraints: const BoxConstraints(
                            minWidth: 44, minHeight: 44),
                        icon: Icon(
                          _showPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _showPass = !_showPass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Bắt buộc';
                      if (v.length < 6) return 'Tối thiểu 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmCtrl,
                    enabled: !_busy,
                    obscureText: !_showPass,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      prefixIcon: Icon(Icons.lock_outline, size: 18),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: TextStyle(
                            color: context.cs.error, fontSize: 12)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Đăng ký'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : () => context.go('/login'),
                    child: const Text('Đã có tài khoản? Đăng nhập'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
