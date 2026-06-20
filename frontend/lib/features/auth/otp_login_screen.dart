/// Sprint 9 Group 1 (2026-05-07): OTP passwordless login.
/// Sprint 19 S19-4 (2026-05-08): UI polish — 6-box OTP + countdown timer.
///
/// Flow 2 stage trong cùng 1 screen:
///   Stage 1 (request): nhập email → POST /auth/otp/request → toast "Đã gửi mã"
///   Stage 2 (verify): 6 box OTP riêng + countdown 5 phút → POST /auth/otp/verify
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _emailCtrl = TextEditingController();
  // Sprint 19 S19-4: 6 controller riêng cho 6 box OTP.
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _stage2 = false;
  bool _busy = false;
  String? _error;
  // Countdown
  Timer? _countdown;
  Duration _remaining = const Duration(minutes: 5);

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _countdown?.cancel();
    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  void _startCountdown() {
    _countdown?.cancel();
    setState(() => _remaining = const Duration(minutes: 5));
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining.inSeconds <= 0) {
          _remaining = Duration.zero;
          t.cancel();
        }
      });
    });
  }

  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Email không hợp lệ');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/auth/otp/request', data: {'email': email});
      if (!mounted) return;
      setState(() {
        _busy = false;
        _stage2 = true;
      });
      _startCountdown();
      // Auto-focus first box
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocusNodes.first.requestFocus();
      });
      AppToast.info(context, 'Đã gửi mã 6 số tới $email. Mã hết hạn sau 5 phút.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = FriendlyError.of(e);
      });
    }
  }

  Future<void> _resendOtp() async {
    // Clear current OTP và request lại
    for (final c in _otpCtrls) {
      c.clear();
    }
    setState(() => _error = null);
    await _requestOtp();
  }

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() => _error = 'Mã OTP gồm 6 chữ số');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/auth/otp/verify', data: {
        'email': _emailCtrl.text.trim(),
        'otp_code': code,
      });
      final token = res.data['access_token'] as String?;
      final refresh = res.data['refresh_token'] as String?;
      if (token == null) {
        throw Exception('Response thiếu access_token');
      }
      final storage = ref.read(tokenStorageProvider);
      await storage.saveToken(token);
      if (refresh != null) await storage.saveRefreshToken(refresh);
      ref.invalidate(authProvider);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = FriendlyError.of(e);
      });
    }
  }

  String _fmtRemaining() {
    final mm = _remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining.inSeconds <= 0;
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
        title: _stage2 ? const Text('Xác thực OTP') : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                  child: const Icon(Icons.mail_outline,
                      color: ptitRed, size: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  _stage2 ? 'Nhập mã 6 chữ số' : 'Đăng nhập bằng OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                if (_stage2)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 13,
                          color: context.textMuted,
                          height: 1.5),
                      children: [
                        const TextSpan(text: 'Đã gửi đến\n'),
                        TextSpan(
                            text: _emailCtrl.text,
                            style: const TextStyle(
                                color: ptitRed,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )
                else
                  Text(
                    'Nhập email PTIT — chúng tôi gửi mã 6 chữ số để xác thực.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textMuted,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 24),
                if (!_stage2)
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Email PTIT',
                      prefixIcon: Icon(Icons.mail_outline, size: 18),
                    ),
                    onSubmitted: (_) => _requestOtp(),
                  )
                else ...[
                  // Sprint 19 S19-4: 6 box OTP riêng + auto-focus next + paste support
                  _OtpBoxesRow(
                    controllers: _otpCtrls,
                    focusNodes: _otpFocusNodes,
                    enabled: !_busy && !expired,
                    onComplete: _verifyOtp,
                  ),
                  const SizedBox(height: 12),
                  // Countdown
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 12.5, color: context.textMuted),
                        children: [
                          const TextSpan(text: 'Mã hết hạn sau '),
                          TextSpan(
                              text: _fmtRemaining(),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: expired ? ptitRed : ptitRed,
                                  fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.cs.error, fontSize: 12)),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _busy ? null : (_stage2 ? _verifyOtp : _requestOtp),
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
                      : Text(_stage2 ? 'Xác thực' : 'Gửi mã'),
                ),
                if (_stage2) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Không nhận được mã? ',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: context.textMuted)),
                        TextButton(
                          onPressed: _busy ? null : _resendOtp,
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: const Size(0, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Gửi lại',
                              style: TextStyle(
                                  color: ptitRed,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _stage2 = false;
                              for (final c in _otpCtrls) {
                                c.clear();
                              }
                              _error = null;
                              _countdown?.cancel();
                            }),
                    child: const Text('Đổi email'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sprint 19 S19-4: 6 OTP box widget với auto-focus next + paste support.
/// - Mỗi box width 48 height 56
/// - Type 1 ký tự → auto focus box tiếp theo
/// - Backspace ở box rỗng → focus box trước
/// - Paste 6 ký tự → fill all + verify auto
class _OtpBoxesRow extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;
  final VoidCallback onComplete;

  const _OtpBoxesRow({
    required this.controllers,
    required this.focusNodes,
    required this.enabled,
    required this.onComplete,
  });

  @override
  State<_OtpBoxesRow> createState() => _OtpBoxesRowState();
}

class _OtpBoxesRowState extends State<_OtpBoxesRow> {
  void _onChanged(int idx, String value) {
    if (value.length > 1) {
      // Paste case: spread 6 char vào 6 box
      final chars = value.replaceAll(RegExp(r'\D'), '').split('');
      if (chars.length >= 6) {
        for (var i = 0; i < 6; i++) {
          widget.controllers[i].text = chars[i];
        }
        widget.focusNodes.last.unfocus();
        // Auto-verify khi paste đủ 6 số
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete();
        });
        return;
      }
      // Truncate to 1 char
      widget.controllers[idx].text = chars.isEmpty ? '' : chars.first;
      widget.controllers[idx].selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controllers[idx].text.length));
    }
    if (widget.controllers[idx].text.length == 1 && idx < 5) {
      widget.focusNodes[idx + 1].requestFocus();
    }
    // Auto-verify khi nhập xong box thứ 6
    if (idx == 5 && widget.controllers[5].text.isNotEmpty) {
      final allFilled = widget.controllers.every((c) => c.text.isNotEmpty);
      if (allFilled) {
        widget.focusNodes[5].unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onComplete();
        });
      }
    }
  }

  void _onKey(int idx, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controllers[idx].text.isEmpty &&
        idx > 0) {
      widget.focusNodes[idx - 1].requestFocus();
      widget.controllers[idx - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 48,
            height: 56,
            child: KeyboardListener(
              focusNode: FocusNode(skipTraversal: true),
              onKeyEvent: (e) => _onKey(i, e),
              child: TextField(
                controller: widget.controllers[i],
                focusNode: widget.focusNodes[i],
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: context.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(color: context.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide(color: context.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: ptitRed, width: 2),
                  ),
                ),
                onChanged: (v) => _onChanged(i, v),
              ),
            ),
          ),
        );
      }),
    );
  }
}
