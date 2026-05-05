import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import 'cert_verify_screen.dart';

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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ptitRed, Color(0xFFFF6B7E)],
                  ),
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
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.4)),
              const SizedBox(height: 3),
              Text(user.email,
                  style: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
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
                          color: ptitRedSoft,
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

          // Menu list
          MCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _menuTile(Icons.edit_outlined, 'Cập nhật thông tin', () => _editProfileDialog(context, ref)),
              const Divider(height: 1, color: cardBorder),
              _menuTile(Icons.lock_outline, 'Đổi mật khẩu', () => _changePasswordDialog(context, ref)),
              const Divider(height: 1, color: cardBorder),
              _menuTile(Icons.qr_code_scanner_outlined, 'Xác thực chứng nhận',
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CertVerifyScreen()))),
              const Divider(height: 1, color: cardBorder),
              _menuTile(Icons.info_outline, 'Về ứng dụng', () {}, subtitle: 'PTIT Contest v0.1.0'),
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
            style: OutlinedButton.styleFrom(side: const BorderSide(color: ptitRedSoft)),
            onPressed: () => _deleteAccountDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {String? subtitle}) =>
      ListTile(
        leading: Icon(icon, color: textMuted, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: textMuted)) : null,
        trailing: const Icon(Icons.chevron_right, color: textMuted, size: 18),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        dense: true,
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
                  const SnackBar(content: Text('Đã cập nhật'), backgroundColor: successGreen));
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
                  const SnackBar(content: Text('Đổi mật khẩu OK'), backgroundColor: successGreen));
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
          const Text(
            'Tài khoản sẽ bị soft-delete (status = INACTIVE).\n'
            'Tất cả dữ liệu (đăng ký, kết quả, chứng nhận) vẫn giữ trong DB.\n'
            'Bạn không thể đăng nhập lại trừ khi admin reactivate.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.5),
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
