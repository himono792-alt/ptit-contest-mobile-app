// Sprint 20+ Item 3 (2026-05-09) — Chứng nhận của tôi.
//
// Filter myResults where awardTitle != null. Hiển thị compact list chỉ các
// kết quả có giải thưởng / chứng nhận để SV scan + tải xuống nhanh.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import 'cert_verify_screen.dart';
import 'my_results_screen.dart';

class MyCertificatesScreen extends ConsumerWidget {
  const MyCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(myResultsProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Chứng nhận'),
      body: asyncResults.when(
        loading: () => const MCardListSkeleton(count: 3, textLines: 2),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Text('Không tải được chứng nhận',
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ),
        ),
        data: (results) {
          final certs = results
              .where((r) => (r.awardTitle ?? '').isNotEmpty)
              .toList()
            ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          if (certs.isEmpty) {
            return _emptyState(context);
          }
          return RefreshIndicator(
            color: ptitRed,
            onRefresh: () async => ref.invalidate(myResultsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s24),
              children: [
                _SummaryHeader(count: certs.length),
                const SizedBox(height: AppSpacing.s12),
                ...certs.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                      child: _CertCard(cert: c),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 64, color: context.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Chưa có chứng nhận.\nHoàn thành cuộc thi + đạt giải để được cấp chứng nhận.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int count;
  const _SummaryHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE63946), Color(0xFFFF6B7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.emoji_events,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count chứng nhận',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  )),
              const SizedBox(height: 2),
              Text('Sẵn sàng tải xuống · xác thực bằng QR',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}

class _CertCard extends StatelessWidget {
  final dynamic cert;
  const _CertCard({required this.cert});

  String _trophy(int? rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip ptitRedSoft
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s12),
            decoration: BoxDecoration(
              color: context.ptitRedSoft,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(children: [
              Text(_trophy(cert.rankNo), style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cert.awardTitle ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ptitRed,
                          letterSpacing: -0.3,
                          height: 1.2,
                        )),
                    const SizedBox(height: 3),
                    Text(cert.contestTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.textMuted,
                        )),
                  ],
                ),
              ),
            ]),
          ),
          // Body: meta + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _MetaChip(
                      label: 'Hạng',
                      value: '#${cert.rankNo ?? "—"}',
                      icon: Icons.emoji_events_outlined),
                  const SizedBox(width: AppSpacing.s8),
                  _MetaChip(
                      label: 'Điểm',
                      value: cert.finalScore?.toStringAsFixed(2) ?? '—',
                      icon: Icons.star_outline),
                  const SizedBox(width: AppSpacing.s8),
                  _MetaChip(
                      label: 'Cấp',
                      value: fmt.format(cert.publishedAt.toLocal()),
                      icon: Icons.calendar_today_outlined),
                ]),
                const SizedBox(height: AppSpacing.s12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('Xác thực / Tải về'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CertVerifyScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetaChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8, vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.tight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 11, color: context.textMuted),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: context.textMuted,
                    letterSpacing: 0.5,
                  )),
            ]),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.2,
                )),
          ],
        ),
      ),
    );
  }
}
