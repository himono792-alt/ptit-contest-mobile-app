import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/models/contest_detail.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import 'team_management_screen.dart';

class RegisterContestScreen extends ConsumerStatefulWidget {
  final ContestDetail contest;
  const RegisterContestScreen({super.key, required this.contest});

  @override
  ConsumerState<RegisterContestScreen> createState() =>
      _RegisterContestScreenState();
}

class _RegisterContestScreenState extends ConsumerState<RegisterContestScreen> {
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToTeamFlow() async {
    final c = widget.contest;
    // Navigate sang TeamManagementScreen với filter contestId.
    // Nếu user chọn 1 team và đăng ký thành công, screen sẽ pop với team_id.
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => TeamManagementScreen(
          filterContestId: c.contestId,
          filterContestTitle: c.title,
        ),
      ),
    );
    if (result != null && mounted) {
      // Đã đăng ký xong từ TeamManagementScreen, redirect về home
      context.go('/');
    }
  }

  Future<void> _submit() async {
    final c = widget.contest;
    if (c.isTeam) {
      // TEAM mode → chuyển sang team management flow
      _goToTeamFlow();
      return;
    }
    await _register(force: false);
  }

  Future<void> _register({required bool force}) async {
    final c = widget.contest;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post(
        '/contests/${c.contestId}/register/individual',
        queryParameters: force ? {'force': true} : null,
        data: {'note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text},
      );
      if (!mounted) return;
      AppToast.success(context, 'Đăng ký thành công, chờ BTC duyệt');
      context.go('/'); // back to list
    } on DioException catch (e) {
      // Option B — 409 SCHEDULE_CONFLICT: cảnh báo mềm, cho phép đăng ký tiếp.
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail']
          : null;
      if (e.response?.statusCode == 409 &&
          detail is Map &&
          detail['code'] == 'SCHEDULE_CONFLICT') {
        if (mounted) setState(() => _loading = false);
        final proceed = await _showConflictDialog(detail);
        if (proceed == true) {
          await _register(force: true); // SV cố tình đăng ký dù trùng lịch
        }
        return;
      }
      setState(() => _error = FriendlyError.of(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Dialog cảnh báo trùng lịch. Trả true nếu SV vẫn muốn đăng ký.
  Future<bool?> _showConflictDialog(Map detail) {
    final conflicts = (detail['conflicts'] as List?) ?? const [];
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: context.warnOrange),
        title: const Text('Trùng lịch cuộc thi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Cuộc thi này trùng lịch với cuộc thi bạn đã đăng ký:'),
            const SizedBox(height: 10),
            ...conflicts.map((c) {
              final m = c as Map;
              final start = (m['start_at'] as String?)?.split('T').first ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('•  '),
                  Expanded(
                    child: Text('${m['title'] ?? '?'}'
                        '${start.isNotEmpty ? '  ($start)' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 10),
            Text('Bạn vẫn muốn đăng ký cuộc thi này chứ?',
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.warnOrange),
            child: const Text('Vẫn đăng ký'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contest;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: MTopBar(
          title: 'Đăng ký tham gia',
          leading: IconButton(
            // Sprint 3 a11y fix: tooltip cho back arrow IconButton
            tooltip: 'Quay lại',
            icon: Icon(Icons.arrow_back, color: context.textMuted),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cuộc thi',
                        style: TextStyle(color: context.textMuted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(c.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${c.participationMode} · ${c.deliveryMode}',
                        style: TextStyle(color: context.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Ghi chú đăng ký (tùy chọn)',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
              const SizedBox(height: 6),
              Semantics(
                label: 'Ghi chú đăng ký',
                hint: 'Tùy chọn — lý do tham gia hoặc kinh nghiệm',
                textField: true,
                multiline: true,
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                      hintText: 'VD: Lý do tham gia, kinh nghiệm...'),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.warnSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 16, color: context.warnOrange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đăng ký sẽ ở trạng thái PENDING chờ Ban Tổ chức phê duyệt.',
                      style: TextStyle(fontSize: 12, color: context.warnOrange),
                    ),
                  ),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: context.ptitRedSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Row(children: [
                    const Icon(Icons.error_outline, size: 16, color: ptitRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: ptitRed, fontSize: 12)),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              Semantics(
                label: c.isTeam
                    ? 'Tiếp tục chọn hoặc tạo team'
                    : 'Gửi đăng ký tham gia cuộc thi',
                button: true,
                enabled: !_loading,
                hint: c.isTeam
                    ? 'Mở màn hình quản lý team'
                    : 'Đăng ký sẽ ở trạng thái chờ Ban Tổ chức phê duyệt',
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(c.isTeam ? Icons.groups : Icons.send, size: 16),
                  label: Text(c.isTeam
                      ? 'Tiếp tục — Chọn / Tạo team'
                      : (_loading ? 'Đang gửi...' : 'Gửi đăng ký')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
