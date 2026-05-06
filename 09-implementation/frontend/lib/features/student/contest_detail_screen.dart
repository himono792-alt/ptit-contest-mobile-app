import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/contest_detail.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';
import 'review_dialog.dart';

final contestDetailProvider =
    FutureProvider.autoDispose.family<ContestDetail, String>((ref, slug) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$slug');
  return ContestDetail.fromJson(res.data);
});

class ContestDetailScreen extends ConsumerWidget {
  final String slug;
  const ContestDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(contestDetailProvider(slug));
    return Scaffold(
      appBar: MTopBar(
        title: 'Chi tiết',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textMuted),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: context.textMuted, size: 20),
            tooltip: 'Sao chép link',
            onPressed: () async {
              final url =
                  'https://luxury-crostata-3c5c69.netlify.app/contests/$slug';
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã copy link: $url'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: asyncData.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: ptitRed)),
        error: (e, _) => Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: $e',
                    style: TextStyle(color: context.textMuted)))),
        data: (c) => _buildBody(context, c),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ContestDetail c) {
    final fmt = DateFormat('dd/MM/yyyy · HH:mm');
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // ============ Hero banner: gradient + title overlay ============
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ptitRed, Color(0xFFFF6B7E)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: shadowMd,
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.emoji_events,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(_statusVi(c.status),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                Text(
                  c.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ============ Quick meta row ============
          Wrap(spacing: 6, runSpacing: 6, children: [
            _MetaChip(
                icon: Icons.school_outlined,
                label: 'Khoa #${c.hostFacultyId ?? "?"}'),
            _MetaChip(
                icon: c.participationMode == 'TEAM'
                    ? Icons.groups_outlined
                    : Icons.person_outline,
                label: c.participationMode == 'TEAM' ? 'Đội' : 'Cá nhân'),
            _MetaChip(
                icon: c.deliveryMode == 'ONLINE'
                    ? Icons.cloud_outlined
                    : (c.deliveryMode == 'OFFLINE'
                        ? Icons.location_on_outlined
                        : Icons.sync_alt),
                label: _modeLabel(c.deliveryMode)),
            if (c.locationText != null && c.locationText!.isNotEmpty)
              _MetaChip(icon: Icons.place_outlined, label: c.locationText!),
          ]),
          const SizedBox(height: 16),

          // ============ Description ============
          if (c.description != null) ...[
            _SectionHeader(icon: Icons.info_outline, title: 'Mô tả'),
            const SizedBox(height: 8),
            MCard(
              child: Text(c.description!,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      height: 1.65,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
          ],

          // ============ Lịch trình ============
          _SectionHeader(icon: Icons.event_outlined, title: 'Lịch trình'),
          const SizedBox(height: 8),
          MCard(
            child: Column(children: [
              _kvRow(context, label: 'Bắt đầu', value: fmt.format(c.startAt)),
              _Divider(),
              _kvRow(context, label: 'Kết thúc', value: fmt.format(c.endAt)),
              if (c.registrationOpenAt != null) ...[
                _Divider(),
                _kvRow(context,
                    label: 'Mở đăng ký',
                    value: fmt.format(c.registrationOpenAt!),
                    accent: true),
              ],
              if (c.registrationCloseAt != null) ...[
                _Divider(),
                _kvRow(context,
                    label: 'Đóng đăng ký',
                    value: fmt.format(c.registrationCloseAt!)),
              ],
              if (c.maxEntries != null) ...[
                _Divider(),
                _kvRow(context, label: 'Số lượng', value: '${c.maxEntries} thí sinh'),
              ],
              if (c.isTeam) ...[
                _Divider(),
                _kvRow(context,
                    label: 'Quy mô đội',
                    value: '${c.teamMinMembers}–${c.teamMaxMembers} thành viên'),
              ],
            ]),
          ),
          const SizedBox(height: 8),

          // ============ Thể lệ ============
          if (c.rulesText != null) ...[
            _SectionHeader(icon: Icons.gavel_outlined, title: 'Thể lệ'),
            const SizedBox(height: 8),
            MCard(
              child: Text(c.rulesText!,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.65,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
          ],

          // ============ Giải thưởng ============
          if (c.awardText != null) ...[
            _SectionHeader(
                icon: Icons.workspace_premium_outlined, title: 'Giải thưởng'),
            const SizedBox(height: 8),
            MCard(
              backgroundColor: context.warnSoft.withValues(alpha: 0.4),
              child: Text(c.awardText!,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.65,
                      color: context.textPrimary,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
          ],

          if (c.isFinished) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.star_outline, size: 18),
              label: const Text('Đánh giá cuộc thi này'),
              onPressed: () => showReviewDialog(
                context,
                contestId: c.contestId,
                contestTitle: c.title,
              ),
            ),
          ],
        ],
      ),

      // ============ Sticky bottom CTA bar ============
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border(top: BorderSide(color: context.cardBorder)),
            boxShadow: shadowMd,
          ),
          child: SafeArea(
            top: false,
            child: c.isRegOpen
                ? FilledButton.icon(
                    icon: const Icon(Icons.app_registration, size: 18),
                    label: const Text('Đăng ký tham gia'),
                    onPressed: () => context.push(
                        '/contests/${c.slug}/register',
                        extra: c),
                  )
                : FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEDE7DF)),
                    child: Text('Không nhận đăng ký (${_statusVi(c.status)})',
                        style: TextStyle(color: context.textMuted)),
                  ),
          ),
        ),
      ),
    ]);
  }

  String _modeLabel(String m) =>
      m == 'ONLINE' ? 'Online' : (m == 'OFFLINE' ? 'Offline' : 'Hybrid');

  String _statusVi(String s) => switch (s) {
        'DRAFT' => 'Nháp',
        'PROPOSED' => 'Chờ duyệt',
        'PUBLISHED' => 'Đã công bố',
        'REG_OPEN' => 'Đang mở ĐK',
        'REG_CLOSED' => 'Đóng đăng ký',
        'ONGOING' => 'Đang diễn ra',
        'FINISHED' => 'Đã kết thúc',
        'CANCELLED' => 'Đã hủy',
        'REVISION_REQUESTED' => 'Sửa lại',
        _ => s,
      };
}

// ===================== Reusable widgets =====================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: ptitRed),
      const SizedBox(width: 6),
      Text(title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.2,
          )),
    ]);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: context.textMuted),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: context.textPrimary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(color: context.cardBorder, height: 16, thickness: 1);
}

Widget _kvRow(BuildContext context, {required String label, required String value, bool accent = false}) {
  return Row(children: [
    Expanded(
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: context.textMuted,
              fontWeight: FontWeight.w500)),
    ),
    Text(value,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: accent ? ptitRed : context.textPrimary,
        )),
  ]);
}
