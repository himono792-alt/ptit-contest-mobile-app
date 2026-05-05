import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/contest_detail.dart';
import '../../core/theme.dart';

class RegisterContestScreen extends ConsumerStatefulWidget {
  final ContestDetail contest;
  const RegisterContestScreen({super.key, required this.contest});

  @override
  ConsumerState<RegisterContestScreen> createState() => _RegisterContestScreenState();
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
        // For team mode, would need to create team first or pick existing — simplified: error
        setState(() {
          _error = 'Cuộc thi team — cần tạo team trước (TODO: team UI)';
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
          backgroundColor: Colors.green,
        ),
      );
      context.go('/'); // back to list, ContestDetail invalidated
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map ? '${e.response?.data['detail']}' : e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contest;
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tham gia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cuộc thi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${c.participationMode} · ${c.deliveryMode}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ghi chú đăng ký (tùy chọn)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'VD: Lý do tham gia...'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '⚠️ Đăng ký sẽ ở trạng thái PENDING chờ Ban Tổ chức phê duyệt.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ptitRedSoft, borderRadius: BorderRadius.circular(6)),
                child: Text(_error!, style: const TextStyle(color: ptitRed, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Gửi đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
