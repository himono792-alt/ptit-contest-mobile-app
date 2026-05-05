import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/contest_detail.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';

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

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final c = widget.contest;
      if (c.isTeam) {
        setState(() {
          _error =
              'Cuộc thi team — chức năng tạo team chưa implement trên mobile. Vui lòng dùng web.';
          _loading = false;
        });
        return;
      }
      await api.dio.post(
        '/contests/${c.contestId}/register/individual',
        data: {'note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký thành công, chờ BTC duyệt'),
          backgroundColor: successGreen,
        ),
      );
      context.go('/'); // back to list
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map
            ? '${e.response?.data['detail']}'
            : e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            icon: const Icon(Icons.arrow_back, color: textMuted),
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
                    const Text('Cuộc thi',
                        style: TextStyle(color: textMuted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(c.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${c.participationMode} · ${c.deliveryMode}',
                        style: const TextStyle(color: textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Ghi chú đăng ký (tùy chọn)',
                  style: TextStyle(fontSize: 12, color: textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                    hintText: 'VD: Lý do tham gia, kinh nghiệm...'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: warnSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: warnOrange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đăng ký sẽ ở trạng thái PENDING chờ Ban Tổ chức phê duyệt.',
                      style: TextStyle(fontSize: 12, color: warnOrange),
                    ),
                  ),
                ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: ptitRedSoft,
                      borderRadius: BorderRadius.circular(8)),
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
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Gửi đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
