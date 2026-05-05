import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import 'master_data_screen.dart' show facultiesProvider;

/// Show modal CreateContestDialog. Returns true nếu user đã tạo thành công.
Future<bool?> showCreateContestDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const CreateContestDialog(),
  );
}

class CreateContestDialog extends ConsumerStatefulWidget {
  const CreateContestDialog({super.key});

  @override
  ConsumerState<CreateContestDialog> createState() =>
      _CreateContestDialogState();
}

class _CreateContestDialogState extends ConsumerState<CreateContestDialog> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _slugCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _awardCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _maxEntriesCtrl = TextEditingController();
  final _teamMinCtrl = TextEditingController(text: '2');
  final _teamMaxCtrl = TextEditingController(text: '5');

  // State
  String _deliveryMode = 'HYBRID';
  String _participationMode = 'INDIVIDUAL';
  bool _requiresSubmission = false;
  bool _isPublic = true;
  int? _hostFacultyId;
  DateTime? _regOpenAt;
  DateTime? _regCloseAt;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _busy = false;
  /// True nếu user đã edit slug trực tiếp — khi đó dừng auto-fill từ title.
  bool _slugManuallyEdited = false;
  /// True = sau khi tạo, gọi luôn /submit-for-approval để BCN thấy ngay.
  bool _submitForApprovalAfterCreate = true;

  @override
  void initState() {
    super.initState();
    // Default times: bắt đầu sau 7 ngày, kết thúc sau 14 ngày, mở ĐK ngay, đóng ĐK trước start 1 ngày
    final now = DateTime.now();
    _regOpenAt = now;
    _regCloseAt = now.add(const Duration(days: 6));
    _startAt = now.add(const Duration(days: 7));
    _endAt = now.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rulesCtrl.dispose();
    _awardCtrl.dispose();
    _locationCtrl.dispose();
    _maxEntriesCtrl.dispose();
    _teamMinCtrl.dispose();
    _teamMaxCtrl.dispose();
    super.dispose();
  }

  /// Auto-generate slug từ title — map char-by-char để tránh edge case regex Unicode.
  String _generateSlug(String title) {
    const map = {
      'à':'a','á':'a','ả':'a','ã':'a','ạ':'a',
      'ă':'a','ằ':'a','ắ':'a','ẳ':'a','ẵ':'a','ặ':'a',
      'â':'a','ầ':'a','ấ':'a','ẩ':'a','ẫ':'a','ậ':'a',
      'è':'e','é':'e','ẻ':'e','ẽ':'e','ẹ':'e',
      'ê':'e','ề':'e','ế':'e','ể':'e','ễ':'e','ệ':'e',
      'ì':'i','í':'i','ỉ':'i','ĩ':'i','ị':'i',
      'ò':'o','ó':'o','ỏ':'o','õ':'o','ọ':'o',
      'ô':'o','ồ':'o','ố':'o','ổ':'o','ỗ':'o','ộ':'o',
      'ơ':'o','ờ':'o','ớ':'o','ở':'o','ỡ':'o','ợ':'o',
      'ù':'u','ú':'u','ủ':'u','ũ':'u','ụ':'u',
      'ư':'u','ừ':'u','ứ':'u','ử':'u','ữ':'u','ự':'u',
      'ỳ':'y','ý':'y','ỷ':'y','ỹ':'y','ỵ':'y',
      'đ':'d',
    };
    String s = title.toLowerCase();
    map.forEach((k, v) => s = s.replaceAll(k, v));
    // Strip mọi char không phải a-z, 0-9, space, dash
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    return s.trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  Future<void> _pickDateTime(
      BuildContext context, DateTime? initial, ValueChanged<DateTime> onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startAt == null || _endAt == null) {
      _snack('Phải chọn thời gian bắt đầu + kết thúc');
      return;
    }
    if (_endAt!.isBefore(_startAt!)) {
      _snack('Thời gian kết thúc phải sau thời gian bắt đầu');
      return;
    }

    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'slug': _slugCtrl.text.trim(),
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_rulesCtrl.text.isNotEmpty) 'rules_text': _rulesCtrl.text.trim(),
        if (_awardCtrl.text.isNotEmpty) 'award_text': _awardCtrl.text.trim(),
        'delivery_mode': _deliveryMode,
        'participation_mode': _participationMode,
        'requires_submission': _requiresSubmission,
        'is_public': _isPublic,
        'start_at': _startAt!.toUtc().toIso8601String(),
        'end_at': _endAt!.toUtc().toIso8601String(),
        if (_regOpenAt != null) 'registration_open_at': _regOpenAt!.toUtc().toIso8601String(),
        if (_regCloseAt != null) 'registration_close_at': _regCloseAt!.toUtc().toIso8601String(),
        if (_locationCtrl.text.isNotEmpty) 'location_text': _locationCtrl.text.trim(),
        if (_hostFacultyId != null) 'host_faculty_id': _hostFacultyId,
        if (_maxEntriesCtrl.text.isNotEmpty)
          'max_entries': int.tryParse(_maxEntriesCtrl.text),
      };
      if (_participationMode == 'TEAM') {
        body['team_min_members'] = int.tryParse(_teamMinCtrl.text) ?? 2;
        body['team_max_members'] = int.tryParse(_teamMaxCtrl.text) ?? 5;
      }

      final res = await api.dio.post('/contests', data: body);
      final newId = res.data['contest_id'];

      String successMsg = 'Đã tạo cuộc thi #$newId — status DRAFT';

      // Optional: submit ngay cho BCN duyệt
      if (_submitForApprovalAfterCreate) {
        try {
          await api.dio.post('/contests/$newId/submit-for-approval', data: {
            'note': 'Đề xuất tạo từ form Admin.',
          });
          successMsg = 'Đã tạo + submit cuộc thi #$newId — chờ BCN duyệt (PROPOSED)';
        } catch (e) {
          successMsg = 'Đã tạo #$newId nhưng submit-for-approval lỗi — vào detail submit lại sau';
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? '${e.response?.data['detail']}'
          : (e.message ?? 'Lỗi tạo contest');
      _snack('Lỗi: $msg');
    } catch (e) {
      _snack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final asyncFaculties = ref.watch(facultiesProvider);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: cardBorder)),
              ),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ptitRed, Color(0xFFFF6B7E)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tạo cuộc thi mới',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                        Text('Sau khi tạo, contest ở status DRAFT — submit để BCN duyệt.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: textMuted)),
                      ]),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _busy ? null : () => Navigator.pop(context, false),
                ),
              ]),
            ),

            // Body scrollable form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Thông tin cơ bản'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tên cuộc thi *',
                            hintText: 'VD: Hackathon Mùa thu 2026',
                          ),
                          onChanged: (v) {
                            // Auto-fill slug nếu user CHƯA chỉnh slug thủ công
                            if (!_slugManuallyEdited) {
                              _slugCtrl.text = _generateSlug(v);
                            }
                          },
                          validator: (v) => (v == null || v.trim().length < 3) ? 'Tối thiểu 3 ký tự' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _slugCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Slug (URL identifier) *',
                            hintText: 'hackathon-mua-thu-2026',
                            helperText: 'Chỉ chữ thường, số, dấu gạch ngang. Auto-fill từ tên.',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
                          ],
                          // Khi user gõ vào slug → đánh dấu manual edited để không bị title overwrite
                          onChanged: (_) => _slugManuallyEdited = true,
                          validator: (v) {
                            if (v == null || v.length < 3) return 'Tối thiểu 3 ký tự';
                            if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v)) return 'Chỉ a-z, 0-9, dấu -';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả ngắn',
                            hintText: 'Giới thiệu mục đích, đối tượng cuộc thi...',
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 22),
                        _SectionLabel('Hình thức & quy mô'),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _deliveryMode,
                              decoration: const InputDecoration(labelText: 'Hình thức tổ chức *'),
                              items: const [
                                DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                                DropdownMenuItem(value: 'OFFLINE', child: Text('Offline')),
                                DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                              ],
                              onChanged: (v) => setState(() => _deliveryMode = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _participationMode,
                              decoration: const InputDecoration(labelText: 'Tham gia *'),
                              items: const [
                                DropdownMenuItem(value: 'INDIVIDUAL', child: Text('Cá nhân')),
                                DropdownMenuItem(value: 'TEAM', child: Text('Đội')),
                              ],
                              onChanged: (v) => setState(() => _participationMode = v!),
                            ),
                          ),
                        ]),
                        if (_participationMode == 'TEAM') ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _teamMinCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Min thành viên/đội'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _teamMaxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Max thành viên/đội'),
                              ),
                            ),
                          ]),
                        ],
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maxEntriesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số entry tối đa',
                                hintText: 'Để trống = không giới hạn',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _locationCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Địa điểm',
                                hintText: 'Hội trường A1, Online Zoom...',
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 22),
                        _SectionLabel('Thời gian'),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _DateTimeField(label: 'Mở đăng ký', value: _regOpenAt, onPick: () => _pickDateTime(context, _regOpenAt, (v) => setState(() => _regOpenAt = v)))),
                          const SizedBox(width: 12),
                          Expanded(child: _DateTimeField(label: 'Đóng đăng ký', value: _regCloseAt, onPick: () => _pickDateTime(context, _regCloseAt, (v) => setState(() => _regCloseAt = v)))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _DateTimeField(label: 'Bắt đầu cuộc thi *', value: _startAt, required: true, onPick: () => _pickDateTime(context, _startAt, (v) => setState(() => _startAt = v)))),
                          const SizedBox(width: 12),
                          Expanded(child: _DateTimeField(label: 'Kết thúc cuộc thi *', value: _endAt, required: true, onPick: () => _pickDateTime(context, _endAt, (v) => setState(() => _endAt = v)))),
                        ]),

                        const SizedBox(height: 22),
                        _SectionLabel('Khoa chủ trì & cấu hình'),
                        const SizedBox(height: 10),
                        asyncFaculties.when(
                          loading: () => const LinearProgressIndicator(color: ptitRed),
                          error: (_, __) => Text('Không tải được khoa', style: GoogleFonts.plusJakartaSans(color: ptitRed)),
                          data: (list) => DropdownButtonFormField<int?>(
                            value: _hostFacultyId,
                            decoration: const InputDecoration(
                              labelText: 'Khoa chủ trì *',
                              helperText: 'Bắt buộc — BCN của khoa này sẽ phê duyệt đề xuất',
                              helperMaxLines: 2,
                            ),
                            items: list.map((f) {
                              final m = f as Map<String, dynamic>;
                              return DropdownMenuItem<int?>(
                                value: m['faculty_id'] as int,
                                child: Text('${m['faculty_code']} — ${m['faculty_name']}'),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _hostFacultyId = v),
                            validator: (v) => v == null ? 'Vui lòng chọn khoa chủ trì để BCN phê duyệt' : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Yêu cầu nộp bài'),
                          subtitle: const Text('Bật nếu cuộc thi có vòng nộp bài (vd hackathon, code contest)', style: TextStyle(fontSize: 11)),
                          value: _requiresSubmission,
                          onChanged: (v) => setState(() => _requiresSubmission = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Công khai'),
                          subtitle: const Text('Bật để SV xem được khi PUBLISHED. Tắt = chỉ admin/BTC thấy.', style: TextStyle(fontSize: 11)),
                          value: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Submit ngay cho BCN duyệt'),
                          subtitle: const Text('Bật = tự gọi /submit-for-approval sau khi tạo → BCN thấy trong tab Phê duyệt. Tắt = giữ status DRAFT.', style: TextStyle(fontSize: 11)),
                          value: _submitForApprovalAfterCreate,
                          activeColor: ptitRed,
                          onChanged: (v) => setState(() => _submitForApprovalAfterCreate = v),
                        ),

                        const SizedBox(height: 22),
                        _SectionLabel('Thể lệ & Giải thưởng (tùy chọn)'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _rulesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Thể lệ',
                            hintText: 'Quy định, cách tính điểm...',
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _awardCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Giải thưởng',
                            hintText: '🥇 Giải Nhất: 10tr\n🥈 Giải Nhì: 5tr...',
                          ),
                          maxLines: 4,
                        ),
                      ]),
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Tạo cuộc thi'),
                  style: FilledButton.styleFrom(
                      backgroundColor: ptitRed, minimumSize: const Size(160, 40)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: ptitRed,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final bool required;
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onPick,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy · HH:mm');
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? 'Chọn...' : fmt.format(value!),
          style: TextStyle(
            color: value == null ? textFaint : textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
