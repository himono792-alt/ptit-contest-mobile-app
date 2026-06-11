// Sprint 23 Step 4 (2026-05-09): 3 BCN screens placeholder build thật.
// Tận dụng hodFacultyStatsProvider + system-summary.xlsx export.
// Mẫu chứng nhận: list config templates static (BE chưa wire).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/xlsx_export_helper.dart';
import 'admin_dashboard_screen.dart' show hodFacultyStatsProvider;

// Sprint 25 P2-C1 (2026-05-09): provider faculty cert templates
final facultyCertTemplatesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/admin/faculty-cert-templates');
    return (res.data as List?) ?? [];
  } catch (_) {
    return [];
  }
});

// ============== Screen 1: Mẫu chứng nhận ==============

class BcnCertTemplatesScreen extends ConsumerWidget {
  const BcnCertTemplatesScreen({super.key});

  Future<void> _openDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? template) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CertTemplateDialog(template: template),
    );
    if (result == true) {
      ref.invalidate(facultyCertTemplatesProvider);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref,
      Map<String, dynamic> template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa mẫu?'),
        content: Text('Xóa "${template['name']}" — không thể khôi phục.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ptitRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.dio
          .delete('/admin/faculty-cert-templates/${template['template_id']}');
      ref.invalidate(facultyCertTemplatesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa mẫu')));
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? '${e.response?.data['detail']}'
          : (e.message ?? '');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTemplates = ref.watch(facultyCertTemplatesProvider);
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _BCNScreenHeader(
          title: 'Mẫu chứng nhận',
          subtitle:
              'Quản lý template chứng nhận khoa — logo, chữ ký, layout. Duyệt mẫu trước khi GV cấp cho SV.',
        ),
        Expanded(
          child: asyncTemplates.when(
            loading: () => const MCardListSkeleton(count: 3, textLines: 2),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Text('Lỗi: $e',
                    style:
                        TextStyle(color: context.textMuted, fontSize: 12)),
              ),
            ),
            data: (templates) => ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                Row(children: [
                  Expanded(
                    child: Text('${templates.length} mẫu',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.textMuted,
                            letterSpacing: 0.4)),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tạo mẫu mới'),
                    style: FilledButton.styleFrom(
                        backgroundColor: ptitRed,
                        minimumSize: const Size(140, 40)),
                    onPressed: () => _openDialog(context, ref, null),
                  ),
                ]),
                const SizedBox(height: AppSpacing.s12),
                if (templates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s32),
                    child: Center(
                      child: Text(
                          'Chưa có mẫu nào.\nClick "Tạo mẫu mới" để thêm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: context.textMuted, fontSize: 13)),
                    ),
                  )
                else
                  ...templates.map<Widget>((t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                        child: _CertTemplateRow(
                          template: t as Map<String, dynamic>,
                          onEdit: () => _openDialog(context, ref, t),
                          onDelete: () => _delete(context, ref, t),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _CertTemplateRow extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CertTemplateRow({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = template['is_active'] == true;
    return MCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      margin: EdgeInsets.zero,
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active
                ? context.successSoft
                : context.cardBorder.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(Icons.workspace_premium_outlined,
              color: active ? context.successGreen : context.textMuted,
              size: 24),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text((template['name'] as String?) ?? '',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.2)),
                ),
                if (active)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.successSoft,
                      borderRadius: BorderRadius.circular(AppRadius.tight),
                    ),
                    child: Text('ACTIVE',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: context.successGreen,
                            letterSpacing: 0.6)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(
                  '${template['layout_description'] ?? ''} · ${template['signers'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.textMuted,
                      height: 1.4)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 18, color: context.textMuted),
          tooltip: 'Chỉnh sửa',
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: ptitRed),
          tooltip: 'Xóa',
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

class _CertTemplateDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? template;
  const _CertTemplateDialog({required this.template});

  @override
  ConsumerState<_CertTemplateDialog> createState() =>
      _CertTemplateDialogState();
}

class _CertTemplateDialogState extends ConsumerState<_CertTemplateDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _layoutCtrl;
  late final TextEditingController _signersCtrl;
  late bool _active;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameCtrl = TextEditingController(text: t?['name'] ?? '');
    _layoutCtrl = TextEditingController(text: t?['layout_description'] ?? '');
    _signersCtrl = TextEditingController(text: t?['signers'] ?? '');
    _active = t?['is_active'] == true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _layoutCtrl.dispose();
    _signersCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _layoutCtrl.text.trim().isEmpty ||
        _signersCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần nhập đủ tên, layout, signers')));
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = {
        'name': _nameCtrl.text.trim(),
        'layout_description': _layoutCtrl.text.trim(),
        'signers': _signersCtrl.text.trim(),
        'is_active': _active,
      };
      if (widget.template == null) {
        await api.dio.post('/admin/faculty-cert-templates', data: body);
      } else {
        await api.dio.patch(
            '/admin/faculty-cert-templates/${widget.template!['template_id']}',
            data: body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? '${e.response?.data['detail']}'
          : (e.message ?? '');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.template != null;
    return AlertDialog(
      title: Text(isEdit ? 'Chỉnh sửa mẫu' : 'Tạo mẫu mới'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên mẫu',
                  hintText: 'vd: Template chuẩn KCN',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _layoutCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Layout',
                  hintText: 'vd: A4 ngang · Logo PTIT trái + Khoa phải',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _signersCtrl,
                decoration: const InputDecoration(
                  labelText: 'Người ký',
                  hintText: 'vd: Trưởng khoa + Hiệu trưởng',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Đặt làm template active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ptitRed),
          onPressed: _busy ? null : _save,
          child: Text(isEdit ? 'Lưu' : 'Tạo'),
        ),
      ],
    );
  }
}

// ============== Screen 2: Thống kê khoa ==============

class BcnFacultyStatsScreen extends ConsumerWidget {
  const BcnFacultyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(hodFacultyStatsProvider);
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _BCNScreenHeader(
          title: 'Thống kê khoa',
          subtitle:
              'Tổng quan số liệu cuộc thi / SV / giải thưởng theo khoa.',
        ),
        Expanded(
          child: asyncStats.when(
            loading: () => const MCardListSkeleton(count: 3, textLines: 2),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Text('Lỗi: $e',
                    style:
                        TextStyle(color: context.textMuted, fontSize: 12)),
              ),
            ),
            data: (data) {
              if (data == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s32),
                    child: Text('Chưa có dữ liệu thống kê khoa',
                        style: TextStyle(
                            color: context.textMuted, fontSize: 13)),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  // Faculty overview card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE63946), Color(0xFFFF6B7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((data['faculty_name'] as String?) ?? 'Khoa',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4)),
                        const SizedBox(height: 4),
                        Text('Năm ${data['year'] ?? DateTime.now().year}',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.s12,
                    crossAxisSpacing: AppSpacing.s12,
                    childAspectRatio: 1.7,
                    children: [
                      _StatCell(
                          label: 'Tổng cuộc thi',
                          value: '${data['total_contests'] ?? 0}',
                          color: ptitRed),
                      _StatCell(
                          label: 'Đang diễn ra',
                          value: '${data['contests_ongoing'] ?? 0}',
                          color: context.successGreen),
                      _StatCell(
                          label: 'Đã kết thúc',
                          value: '${data['contests_finished'] ?? 0}',
                          color: context.infoBlue),
                      _StatCell(
                          label: 'DRAFT/Pending',
                          value:
                              '${data['contests_draft_or_pending'] ?? 0}',
                          color: context.warnOrange),
                      _StatCell(
                          label: 'SV unique',
                          value:
                              '${data['total_unique_students'] ?? 0}',
                          color: context.textPrimary),
                      _StatCell(
                          label: 'Tổng entries',
                          value: '${data['total_entries'] ?? 0}',
                          color: context.textPrimary),
                      _StatCell(
                          label: 'Giải thưởng',
                          value: '${data['total_awards'] ?? 0}',
                          color: ptitRed),
                      _StatCell(
                          label: 'Avg rating',
                          value: data['avg_rating'] != null
                              ? double.tryParse(
                                          data['avg_rating'].toString())
                                      ?.toStringAsFixed(2) ??
                                  '—'
                              : '—',
                          color: context.textPrimary),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.textMuted,
                  letterSpacing: 1.0)),
          const SizedBox(height: AppSpacing.s8),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.6,
                  height: 1)),
        ],
      ),
    );
  }
}

// ============== Screen 3: Báo cáo BGH ==============

class BcnReportBghScreen extends ConsumerWidget {
  const BcnReportBghScreen({super.key});

  Future<void> _exportSystemSummary(
      BuildContext context, WidgetRef ref) async {
    await exportXlsxFromEndpoint(
      context: context,
      dio: ref.read(apiClientProvider).dio,
      path: '/admin/reports/system-summary.xlsx',
      fallbackFilename:
          'bao-cao-bgh-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final monthFmt = DateFormat('MM/yyyy');
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _BCNScreenHeader(
          title: 'Báo cáo BGH',
          subtitle:
              'Báo cáo tháng/quý gửi Ban Giám hiệu — tổng hợp hoạt động khoa.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              // Reminder card
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: context.warnSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color:
                          context.warnOrange.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_outlined,
                      color: context.warnOrange, size: 20),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Báo cáo tháng ${monthFmt.format(today)}',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: context.warnOrange,
                                  letterSpacing: -0.2)),
                          const SizedBox(height: 2),
                          Text('Đến hạn nộp BGH: 10/05',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: context.warnOrange)),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: AppSpacing.s16),
              MCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                margin: EdgeInsets.zero,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Báo cáo Excel tổng hợp',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text(
                          '4 sheet: Tổng users / Tổng contests / Bài nộp / Metadata. Định dạng chuẩn BGH PTIT.',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: context.textMuted,
                              height: 1.5)),
                      const SizedBox(height: AppSpacing.s12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon:
                              const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Xuất báo cáo Excel'),
                          style: FilledButton.styleFrom(
                              backgroundColor: ptitRed,
                              minimumSize: const Size.fromHeight(44)),
                          onPressed: () =>
                              _exportSystemSummary(context, ref),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(height: AppSpacing.s12),
              MCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                margin: EdgeInsets.zero,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lịch báo cáo định kỳ',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.2)),
                      const SizedBox(height: AppSpacing.s8),
                      _ScheduleRow(
                          name: 'Báo cáo tháng',
                          dueDate: 'Ngày 10 mỗi tháng',
                          icon: Icons.calendar_today_outlined),
                      _ScheduleRow(
                          name: 'Báo cáo quý',
                          dueDate: 'Ngày 15 sau quý',
                          icon: Icons.event_available_outlined),
                      _ScheduleRow(
                          name: 'Báo cáo năm',
                          dueDate: 'Ngày 30/06 năm sau',
                          icon: Icons.event_note_outlined),
                    ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String name;
  final String dueDate;
  final IconData icon;
  const _ScheduleRow(
      {required this.name, required this.dueDate, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(children: [
        Icon(icon, size: 16, color: context.textMuted),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(name,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary)),
        ),
        Text(dueDate,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.textMuted)),
      ]),
    );
  }
}

// ============== Shared header ==============

class _BCNScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _BCNScreenHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isMobile) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s32, vertical: AppSpacing.s20),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BCN',
              style: TextStyle(color: context.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12.5,
                  color: context.textMuted,
                  height: 1.5)),
        ],
      ),
    );
  }
}
