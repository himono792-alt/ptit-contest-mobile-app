import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';

class CertVerifyScreen extends ConsumerStatefulWidget {
  const CertVerifyScreen({super.key});
  @override
  ConsumerState<CertVerifyScreen> createState() => _CertVerifyScreenState();
}

class _CertVerifyScreenState extends ConsumerState<CertVerifyScreen> {
  final _codeCtrl = TextEditingController();
  Map<String, dynamic>? _result;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = 'Cần nhập mã QR';
        _result = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      // /verify/{qr_code} là public endpoint, không cần auth nhưng dùng dio chung vẫn OK
      final res = await api.dio.get('/verify/$code');
      setState(() => _result = res.data as Map<String, dynamic>);
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
          : '$e';
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MTopBar(
        title: 'Xác thực chứng nhận',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMuted),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.qr_code_scanner,
                            size: 18, color: ptitRed),
                        SizedBox(width: 8),
                        Text('Nhập mã QR chứng nhận',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _codeCtrl,
                        decoration: const InputDecoration(
                          hintText: 'PTIT-CERT-xxxxxxxx-yyyy',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _verify(),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _verify,
                          icon: _busy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.search, size: 18),
                          label: const Text('Xác thực'),
                          style: FilledButton.styleFrom(
                              backgroundColor: ptitRed),
                        ),
                      ),
                    ]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                MCard(
                  borderColor: ptitRed,
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: ptitRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: ptitRed, fontSize: 12)),
                    ),
                  ]),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 8),
                _ResultCard(data: _result!),
              ],
            ]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final valid = data['valid'] == true;
    final fmt = DateFormat('dd/MM/yyyy');
    return MCard(
      borderColor: valid ? successGreen : ptitRed,
      backgroundColor: valid
          ? successSoft.withValues(alpha: 0.4)
          : ptitRedSoft.withValues(alpha: 0.4),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                valid ? Icons.verified : Icons.cancel,
                color: valid ? successGreen : ptitRed,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  valid
                      ? 'Chứng nhận hợp lệ'
                      : 'Chứng nhận KHÔNG hợp lệ',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: valid ? successGreen : ptitRed),
                ),
              ),
              Pill(
                label: data['status'] ?? '—',
                color: valid ? successGreen : ptitRed,
                bg: valid ? successSoft : ptitRedSoft,
              ),
            ]),
            if (!valid && data['reason'] != null) ...[
              const SizedBox(height: 8),
              Text(data['reason'],
                  style: const TextStyle(fontSize: 12, color: ptitRed)),
            ],
            if (valid) ...[
              const SizedBox(height: 12),
              _kv('Sinh viên', data['student_name']),
              _kv('Mã SV', data['student_code']),
              _kv('Cuộc thi', data['contest_title']),
              if (data['award_title'] != null)
                _kv('Giải thưởng', data['award_title']),
              if (data['issued_at'] != null)
                _kv('Ngày cấp',
                    fmt.format(DateTime.parse(data['issued_at']))),
              _kv('Mã QR',
                  data['qr_code'] ?? '', mono: true),
            ],
          ]),
    );
  }

  Widget _kv(String k, dynamic v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 90,
            child: Text(k,
                style: const TextStyle(fontSize: 11, color: textMuted)),
          ),
          Expanded(
            child: SelectableText('${v ?? "—"}',
                style: TextStyle(
                  fontSize: 12,
                  color: textPrimary,
                  fontFamily: mono ? 'monospace' : null,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ]),
      );
}
