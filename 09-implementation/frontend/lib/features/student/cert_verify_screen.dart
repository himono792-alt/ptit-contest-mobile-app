import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';
import 'cert_open_stub.dart' if (dart.library.html) 'cert_open_web.dart';

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
          icon: Icon(Icons.arrow_back, color: context.textMuted),
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

  Future<void> _openOrCopyRender(BuildContext context) async {
    final qr = data['qr_code']?.toString() ?? '';
    if (qr.isEmpty) return;
    final url = '${AppConfig.api}/certificates/$qr/render';
    final opened = openCertUrl(url);
    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã mở chứng nhận trong tab mới — Ctrl+P để in/save PDF')),
      );
    } else {
      // Mobile fallback: copy URL
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã copy URL vào clipboard:\n$url'), duration: const Duration(seconds: 5)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = data['valid'] == true;
    final fmt = DateFormat('dd/MM/yyyy');
    return MCard(
      borderColor: valid ? context.successGreen : ptitRed,
      backgroundColor: valid
          ? context.successSoft.withValues(alpha: 0.4)
          : context.ptitRedSoft.withValues(alpha: 0.4),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                valid ? Icons.verified : Icons.cancel,
                color: valid ? context.successGreen : ptitRed,
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
                      color: valid ? context.successGreen : ptitRed),
                ),
              ),
              Pill(
                label: data['status'] ?? '—',
                color: valid ? context.successGreen : ptitRed,
                bg: valid ? context.successSoft : context.ptitRedSoft,
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openOrCopyRender(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(kIsWeb
                      ? 'Mở/in chứng nhận (HTML)'
                      : 'Copy URL chứng nhận'),
                  style: FilledButton.styleFrom(backgroundColor: ptitRed),
                ),
              ),
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
                style: TextStyle(fontSize: 11, color: context.textMuted)),
          ),
          Expanded(
            child: SelectableText('${v ?? "—"}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textPrimary,
                  fontFamily: mono ? 'monospace' : null,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ]),
      );
}
