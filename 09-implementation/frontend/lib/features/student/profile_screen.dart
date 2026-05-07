import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import 'cert_verify_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: ptitRed)));
    }
    final initial = user.fullName.split(' ').last.substring(0, 1).toUpperCase();
    return Scaffold(
      appBar: const MTopBar(title: 'Tôi'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============ Avatar header card với gradient ============
          MCard(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
            child: Column(children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: ptitGradientHero,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: ptitRed.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1)),
                ),
              ),
              const SizedBox(height: 14),
              Text(user.fullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.4)),
              const SizedBox(height: 3),
              Text(user.email,
                  style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  for (final r in user.roles)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: context.ptitRedSoft,
                          borderRadius: BorderRadius.circular(99)),
                      child: Text(r,
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: ptitRed,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3)),
                    ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 8),

          // ============ Thông tin cá nhân (đọc) ============
          MCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.badge_outlined,
                        size: 16, color: ptitRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Thông tin cá nhân',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: ptitRed),
                      tooltip: 'Cập nhật thông tin',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen())),
                    ),
                  ]),
                  Divider(color: context.cardBorder, height: 16),
                  _infoRow(context, 'Ngày sinh',
                      user.dob != null
                          ? DateFormat('dd/MM/yyyy').format(user.dob!)
                          : '—'),
                  _infoRow(context, 'Giới tính', user.gender ?? '—'),
                  _infoRow(context, 'Số CMND/CCCD', user.citizenId ?? '—'),
                  _infoRow(context, 'Nơi sinh', user.placeOfBirth ?? '—'),
                  _infoRow(context, 'Quốc tịch', user.nationality ?? '—'),
                  _infoRow(context, 'Dân tộc', user.ethnicity ?? '—'),
                  _infoRow(context, 'Tôn giáo', user.religion ?? '—'),
                  _infoRow(context, 'SĐT', user.phone ?? '—'),
                  _infoRow(context, 'Email cá nhân', user.secondaryEmail ?? '—'),
                  _infoRow(context, 'Địa chỉ', user.address ?? '—'),
                ]),
          ),
          const SizedBox(height: 8),

          // Menu list
          MCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _menuTile(context, Icons.edit_outlined, 'Cập nhật thông tin',
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()))),
              Divider(height: 1, color: context.cardBorder),
              _menuTile(context, Icons.lock_outline, 'Đổi mật khẩu', () => _changePasswordDialog(context, ref)),
              Divider(height: 1, color: context.cardBorder),
              // Phase 2 sprint 1 step 4 (2026-05-06): biometric login toggle
              const _BiometricToggleTile(),
              Divider(height: 1, color: context.cardBorder),
              // Phase 2 sprint 2 step 1 (2026-05-06): theme mode (light/dark/system)
              const _ThemeModeTile(),
              Divider(height: 1, color: context.cardBorder),
              _menuTile(context, Icons.qr_code_scanner_outlined, 'Xác thực chứng nhận',
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CertVerifyScreen()))),
              Divider(height: 1, color: context.cardBorder),
              _menuTile(context, Icons.info_outline, 'Về ứng dụng', () {}, subtitle: 'PTIT Contest v0.1.0'),
            ]),
          ),

          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất'),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Đăng xuất?'),
                  content: const Text('Bạn sẽ về lại màn hình đăng nhập.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18, color: ptitRed),
            label: const Text('Xóa tài khoản', style: TextStyle(color: ptitRed)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: context.ptitRedSoft)),
            onPressed: () => _deleteAccountDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String k, String v) {
    final isPlaceholder = v == '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Text(k,
              style: TextStyle(fontSize: 11, color: context.textMuted)),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(
              fontSize: 12.5,
              color: isPlaceholder ? context.textFaint : context.textPrimary,
              fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {String? subtitle}) =>
      // Sprint 5 a11y: explicit button semantic + label + hint mở dialog/screen.
      Semantics(
        label: subtitle != null ? '$title, $subtitle' : title,
        button: true,
        hint: 'Mở dialog hoặc màn hình $title',
        child: ListTile(
          leading: Icon(icon, color: context.textMuted, size: 20),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 11, color: context.textMuted)) : null,
          trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 18),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          dense: true,
        ),
      );

  void _editProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).value!;
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cập nhật thông tin'),
      content: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: nameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Họ tên *'),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Tối thiểu 2 ký tự' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
                labelText: 'Số điện thoại', hintText: '0xxx xxx xxx'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // optional
              final clean = v.replaceAll(RegExp(r'[\s-]'), '');
              if (!RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(clean)) {
                return 'SĐT VN không hợp lệ (vd: 0912345678)';
              }
              return null;
            },
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              await ref.read(apiClientProvider).dio.patch('/me', data: {
                'full_name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
              });
              ref.invalidate(authProvider);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã cập nhật'), backgroundColor: context.successGreen));
            } on DioException catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${e.message}')));
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    ));
  }

  void _changePasswordDialog(BuildContext context, WidgetRef ref) {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: curCtrl,
            obscureText: true,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
            validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: newCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Mật khẩu mới (≥6 ký tự)'),
            validator: (v) {
              if (v == null || v.length < 6) return 'Tối thiểu 6 ký tự';
              if (v == curCtrl.text) return 'Mật khẩu mới phải khác mật khẩu cũ';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: confirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
            validator: (v) => v != newCtrl.text ? 'Không khớp' : null,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              await ref.read(apiClientProvider).dio.patch('/me/password', data: {
                'current_password': curCtrl.text, 'new_password': newCtrl.text,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đổi mật khẩu OK'), backgroundColor: context.successGreen));
            } on DioException catch (e) {
              if (!ctx.mounted) return;
              final msg = e.response?.data is Map ? '${e.response?.data['detail']}' : e.message;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$msg')));
            }
          },
          child: const Text('Đổi'),
        ),
      ],
    ));
  }

  void _deleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?', style: TextStyle(color: ptitRed)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Tài khoản sẽ bị soft-delete (status = INACTIVE).\n'
            'Tất cả dữ liệu (đăng ký, kết quả, chứng nhận) vẫn giữ trong DB.\n'
            'Bạn không thể đăng nhập lại trừ khi admin reactivate.',
            style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: confirmCtrl,
            decoration: const InputDecoration(
              labelText: 'Gõ "XÓA" để xác nhận',
              hintText: 'XÓA',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ptitRed),
            onPressed: () async {
              if (confirmCtrl.text.trim().toUpperCase() != 'XÓA') {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Cần gõ chính xác "XÓA"')),
                );
                return;
              }
              try {
                await ref.read(apiClientProvider).dio.delete('/me');
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tài khoản — tạm biệt!')),
                );
              } on DioException catch (e) {
                if (!ctx.mounted) return;
                final msg = e.response?.data is Map
                    ? '${e.response?.data['detail']}'
                    : e.message;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Lỗi xóa: $msg')),
                );
              }
            },
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}

/// Phase 2 sprint 1 step 4 (2026-05-06): toggle bật/tắt biometric login.
/// Hiện tile với Switch. Hide trên web (local_auth không support).
/// Khi bật: lưu flag vào secure storage. Lần sau mở app → auto-prompt biometric.
class _BiometricToggleTile extends ConsumerStatefulWidget {
  const _BiometricToggleTile();

  @override
  ConsumerState<_BiometricToggleTile> createState() =>
      _BiometricToggleTileState();
}

class _BiometricToggleTileState extends ConsumerState<_BiometricToggleTile> {
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled = await ref.read(tokenStorageProvider).isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    final storage = ref.read(tokenStorageProvider);
    if (value) {
      // Bật: prompt biometric 1 lần để confirm device hỗ trợ + user accept
      final ok = await BiometricService.instance.authenticate(
        reason: 'Xác nhận để bật đăng nhập sinh trắc',
      );
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác thực thất bại — chưa bật.')),
        );
        return;
      }
    }
    await storage.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _enabled = value);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value
          ? 'Đã bật đăng nhập sinh trắc'
          : 'Đã tắt đăng nhập sinh trắc'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        leading: Icon(Icons.fingerprint, color: ptitRed, size: 20),
        title: Text('Đăng nhập sinh trắc',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: ptitRed),
        ),
      );
    }

    if (!_available) {
      // Hide tile nếu device không support (web hoặc chưa setup biometric)
      return const SizedBox.shrink();
    }

    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint, color: ptitRed, size: 20),
      activeColor: ptitRed,
      title: const Text('Đăng nhập sinh trắc',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        _enabled
            ? 'Đã bật — mở khóa bằng FaceID/Vân tay'
            : 'Tắt — vẫn nhập email + mật khẩu',
        style: TextStyle(fontSize: 11, color: context.textMuted),
      ),
      value: _enabled,
      onChanged: _toggle,
    );
  }
}

/// Phase 2 sprint 2 step 1 (2026-05-06): tile chọn theme mode (Sáng/Tối/Theo hệ thống).
/// Hiện modal bottom sheet với 3 radio option. Switch live qua themeProvider.
class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined, color: ptitRed, size: 20),
      title: const Text('Giao diện',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(themeModeLabel(mode),
          style: TextStyle(fontSize: 11, color: context.textMuted)),
      trailing: Icon(Icons.chevron_right, size: 18, color: context.textMuted),
      onTap: () => _showPicker(context, ref, mode),
    );
  }

  Future<void> _showPicker(BuildContext context, WidgetRef ref, ThemeMode current) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Chọn giao diện',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: mode,
              groupValue: current,
              activeColor: ptitRed,
              title: Text(themeModeLabel(mode),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(_themeDescription(mode),
                  style: TextStyle(fontSize: 11, color: context.textMuted)),
              onChanged: (v) {
                if (v != null) {
                  ref.read(themeProvider.notifier).setMode(v);
                  Navigator.pop(ctx);
                }
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  String _themeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'Tự động theo cài đặt máy';
      case ThemeMode.light: return 'Sáng — phù hợp ban ngày';
      case ThemeMode.dark: return 'Tối — bảo vệ mắt buổi đêm';
    }
  }
}
