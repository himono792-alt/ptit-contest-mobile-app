// SV-02 — Cập nhật thông tin cá nhân (form đầy đủ theo mẫu PTIT student card).
//
// 10+ field: full_name, phone, dob, gender, citizen_id, place_of_birth,
// address, ethnicity, religion, nationality, secondary_email.
//
// PATCH /api/me với JSON các field. dob serialized YYYY-MM-DD.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _citizenCtrl;
  late final TextEditingController _placeBirthCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _ethnicityCtrl;
  late final TextEditingController _religionCtrl;
  late final TextEditingController _nationalityCtrl;
  late final TextEditingController _secondaryEmailCtrl;
  DateTime? _dob;
  String? _gender;
  bool _busy = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).value!;
    _nameCtrl = TextEditingController(text: u.fullName);
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
    _citizenCtrl = TextEditingController(text: u.citizenId ?? '');
    _placeBirthCtrl = TextEditingController(text: u.placeOfBirth ?? '');
    _addressCtrl = TextEditingController(text: u.address ?? '');
    _ethnicityCtrl = TextEditingController(text: u.ethnicity ?? 'Kinh');
    _religionCtrl = TextEditingController(text: u.religion ?? 'Không');
    _nationalityCtrl = TextEditingController(text: u.nationality ?? 'Việt Nam');
    _secondaryEmailCtrl = TextEditingController(text: u.secondaryEmail ?? '');
    _dob = u.dob;
    _gender = u.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _citizenCtrl.dispose();
    _placeBirthCtrl.dispose();
    _addressCtrl.dispose();
    _ethnicityCtrl.dispose();
    _religionCtrl.dispose();
    _nationalityCtrl.dispose();
    _secondaryEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2003, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
    );
    if (d != null) setState(() => _dob = d);
  }

  String _trim(TextEditingController c) => c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'full_name': _trim(_nameCtrl),
        if (_trim(_phoneCtrl).isNotEmpty) 'phone': _trim(_phoneCtrl),
        if (_dob != null) 'dob': DateFormat('yyyy-MM-dd').format(_dob!),
        if (_gender != null) 'gender': _gender,
        if (_trim(_citizenCtrl).isNotEmpty) 'citizen_id': _trim(_citizenCtrl),
        if (_trim(_placeBirthCtrl).isNotEmpty)
          'place_of_birth': _trim(_placeBirthCtrl),
        if (_trim(_addressCtrl).isNotEmpty) 'address': _trim(_addressCtrl),
        if (_trim(_ethnicityCtrl).isNotEmpty)
          'ethnicity': _trim(_ethnicityCtrl),
        if (_trim(_religionCtrl).isNotEmpty) 'religion': _trim(_religionCtrl),
        if (_trim(_nationalityCtrl).isNotEmpty)
          'nationality': _trim(_nationalityCtrl),
        if (_trim(_secondaryEmailCtrl).isNotEmpty)
          'secondary_email': _trim(_secondaryEmailCtrl),
      };
      await api.dio.patch('/me', data: body);
      ref.invalidate(authProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Đã lưu thông tin'), backgroundColor: context.successGreen),
      );
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? '${e.response?.data['detail']}'
          : (e.message ?? 'Lỗi');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(authProvider).value!;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.appBg,
        appBar: AppBar(
          title: const Text('Cập nhật thông tin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            TextButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ptitRed))
                  : const Icon(Icons.save_outlined,
                      size: 16, color: ptitRed),
              label: Text(_busy ? 'Đang lưu...' : 'Lưu',
                  style: const TextStyle(color: ptitRed)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info read-only (email + role)
                    _section(context, 'Thông tin hệ thống (không sửa được)'),
                    _readonlyRow(context, 'Email PTIT', u.email),
                    _readonlyRow(context, 'User ID', '#${u.userId}'),
                    _readonlyRow(context, 'Vai trò', u.roles.join(', ')),
                    _readonlyRow(context, 'Trạng thái', u.status),

                    const SizedBox(height: 18),
                    _section(context, 'Thông tin cá nhân'),
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: Icon(Icons.badge_outlined, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Tối thiểu 2 ký tự'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDob,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Ngày sinh',
                              prefixIcon: Icon(Icons.cake_outlined, size: 18),
                            ),
                            child: Text(
                              _dob == null
                                  ? 'Chưa chọn'
                                  : DateFormat('dd/MM/yyyy').format(_dob!),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Giới tính',
                            prefixIcon: Icon(Icons.wc, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                            DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                            DropdownMenuItem(
                                value: 'Khác', child: Text('Khác')),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _citizenCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Số CMND/CCCD',
                        hintText: '12 số',
                        prefixIcon: Icon(Icons.credit_card, size: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final clean = v.replaceAll(RegExp(r'\s'), '');
                        if (!RegExp(r'^\d{9,12}$').hasMatch(clean)) {
                          return 'CMND 9 số hoặc CCCD 12 số';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _placeBirthCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nơi sinh',
                        hintText: 'vd: Tp. Hồ Chí Minh',
                        prefixIcon: Icon(Icons.location_city, size: 18),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _section(context, 'Liên hệ'),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        hintText: '0xxxxxxxxx',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final clean = v.replaceAll(RegExp(r'[\s-]'), '');
                        if (!RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(clean)) {
                          return 'SĐT VN không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _secondaryEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email cá nhân',
                        hintText: 'gmail / yahoo / outlook ...',
                        prefixIcon: Icon(Icons.alternate_email, size: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!v.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ thường trú',
                        hintText: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh',
                        prefixIcon: Icon(Icons.home_outlined, size: 18),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _section(context, 'Quốc tịch · Dân tộc · Tôn giáo'),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nationalityCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Quốc tịch',
                            prefixIcon: Icon(Icons.flag_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _ethnicityCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Dân tộc',
                            prefixIcon: Icon(Icons.people_outline, size: 18),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _religionCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Tôn giáo',
                        hintText: 'vd: Không / Phật giáo / Công giáo ...',
                        prefixIcon: Icon(Icons.temple_buddhist_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: _busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save, size: 16),
                      label: Text(_busy ? 'Đang lưu...' : 'Lưu thông tin'),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.textMuted,
                letterSpacing: 0.6)),
      );

  Widget _readonlyRow(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 100,
            child: Text(k,
                style: TextStyle(fontSize: 11, color: context.textMuted)),
          ),
          Expanded(
            child: Text(v,
                style: TextStyle(
                    fontSize: 13,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}
