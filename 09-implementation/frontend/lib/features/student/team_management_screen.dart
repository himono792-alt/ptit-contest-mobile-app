// SV-06 Team Management — list teams SV thuộc + create + add member.
//
// Endpoints:
//   GET /me/teams                          → list teams
//   POST /contests/{id}/teams              → create team (SV gọi = leader)
//   POST /teams/{id}/members               → add member by student_code
//   POST /contests/{id}/register/team      → register team for contest
//
// Reachable từ register_screen khi contest TEAM mode hoặc menu "Tôi → Team của tôi".

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';

final myTeamsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/teams');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class TeamManagementScreen extends ConsumerWidget {
  /// Nếu mở từ register flow của contest cụ thể, truyền contestId để hiện nút "Tạo team mới cho contest này".
  final int? filterContestId;
  final String? filterContestTitle;

  const TeamManagementScreen({
    super.key,
    this.filterContestId,
    this.filterContestTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTeams = ref.watch(myTeamsProvider);

    return Scaffold(
      appBar: MTopBar(
        title: filterContestId != null
            ? 'Chọn / tạo team'
            : 'Team của tôi',
        leading: IconButton(
          // Sprint 3 a11y fix: tooltip cho back arrow IconButton
          tooltip: 'Quay lại',
          icon: Icon(Icons.arrow_back, color: context.textMuted),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: asyncTeams.when(
        // Sprint 13 Batch B (2026-05-08): skeleton thay spinner cho team list.
        loading: () => const MCardListSkeleton(count: 3),
        error: (e, _) {
          final msg = e is DioException
              ? (e.response?.data is Map
                  ? '${e.response?.data['detail']}'
                  : e.message ?? '')
              : '$e';
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Lỗi: $msg',
                      style: TextStyle(color: context.textMuted))));
        },
        data: (teams) {
          final filtered = filterContestId != null
              ? teams
                  .where((t) => t['contest_id'] == filterContestId)
                  .toList()
              : teams;

          return RefreshIndicator(
            color: ptitRed,
            onRefresh: () async => ref.invalidate(myTeamsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                if (filterContestId != null)
                  _ContestHeader(title: filterContestTitle ?? 'Cuộc thi'),
                if (filtered.isEmpty)
                  _EmptyTeamView(forContest: filterContestId != null),
                for (final team in filtered)
                  _TeamCard(
                    team: team,
                    onRegistered: () => Navigator.pop(context, team['team_id']),
                    canRegisterForContest: filterContestId != null &&
                        team['contest_id'] == filterContestId,
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.group_add, size: 18),
                  label: Text(filterContestId != null
                      ? 'Tạo team mới cho cuộc thi này'
                      : 'Tạo team mới'),
                  onPressed: () => _openCreateTeamDialog(context, ref),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: context.infoSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 16, color: context.infoBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mỗi cuộc thi cần team riêng. SV có thể là leader 1 team + member nhiều team.',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: context.infoBlue,
                            height: 1.5),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateTeamDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTeamSheet(
        defaultContestId: filterContestId,
        defaultContestTitle: filterContestTitle,
      ),
    );
    if (result == null) return;
    ref.invalidate(myTeamsProvider);
  }
}

// ============== Empty state ==============

class _EmptyTeamView extends StatelessWidget {
  final bool forContest;
  const _EmptyTeamView({required this.forContest});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
              color: context.ptitRedSoft, shape: BoxShape.circle),
          child: const Icon(Icons.groups_outlined,
              size: 40, color: ptitRed),
        ),
        const SizedBox(height: 16),
        Text(
          forContest
              ? 'Bạn chưa có team cho cuộc thi này'
              : 'Bạn chưa thuộc team nào',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Tạo team mới và mời các bạn cùng tham gia',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
        ),
      ]),
    );
  }
}

class _ContestHeader extends StatelessWidget {
  final String title;
  const _ContestHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.ptitRedSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(children: [
        const Icon(Icons.emoji_events, size: 18, color: ptitRed),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuộc thi đang đăng ký',
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(color: ptitRed)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ptitRed)),
              ]),
        ),
      ]),
    );
  }
}

// ============== Team card ==============

class _TeamCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> team;
  final VoidCallback? onRegistered;
  final bool canRegisterForContest;
  const _TeamCard({
    required this.team,
    this.onRegistered,
    this.canRegisterForContest = false,
  });

  @override
  ConsumerState<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends ConsumerState<_TeamCard> {
  bool _busy = false;

  Future<void> _addMember() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm thành viên'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
                'Nhập MSSV của bạn muốn thêm. SV đó phải đã có tài khoản hệ thống.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'MSSV',
                hintText: 'VD: B22DCCN001',
                prefixIcon: Icon(Icons.school_outlined, size: 18),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy')),
            FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
    if (code == null || code.isEmpty) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/teams/${widget.team['team_id']}/members',
          data: {'student_code': code.toUpperCase()});
      ref.invalidate(myTeamsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm $code vào team')),
      );
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

  Future<void> _registerWithThisTeam() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post(
        '/contests/${widget.team['contest_id']}/register/team',
        data: {'team_id': widget.team['team_id'], 'note': 'Đăng ký bằng team đã có'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Đăng ký team thành công, chờ BTC duyệt'),
            backgroundColor: context.successGreen),
      );
      widget.onRegistered?.call();
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
    final t = widget.team;
    final members = (t['members'] as List).cast<Map<String, dynamic>>();
    final fmt = DateFormat('dd/MM/yy HH:mm');

    return MCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.groups, size: 16, color: ptitRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(t['team_name'] as String,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary)),
              ),
              Pill.status(t['status'] as String? ?? 'ACTIVE'),
            ]),
            const SizedBox(height: 6),
            Text(
                'Contest #${t['contest_id']} · Leader student #${t['leader_student_id']} · ${fmt.format(DateTime.parse(t['created_at']))}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted)),
            Divider(height: 18, color: context.cardBorder),
            Text('Thành viên (${members.length})',
                style: TextStyle(
                    fontSize: 11, color: context.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            ...members.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: m['is_leader'] == true
                            ? ptitRed
                            : context.ptitRedSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          m['is_leader'] == true
                              ? Icons.star
                              : Icons.person,
                          size: 14,
                          color: m['is_leader'] == true
                              ? Colors.white
                              : ptitRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Student #${m['student_id']}'
                        '${m['is_leader'] == true ? "  (Leader)" : ""}',
                        style: TextStyle(
                            fontSize: 12,
                            color: context.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yy').format(DateTime.parse(m['joined_at'])),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted),
                    ),
                  ]),
                )),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add, size: 14),
                  label: Text('Thêm thành viên',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textPrimary)),
                  onPressed: _busy ? null : _addMember,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10)),
                ),
              ),
              if (widget.canRegisterForContest) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.app_registration, size: 14),
                    label: Text('Đăng ký bằng team này',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textPrimary)),
                    onPressed: _busy ? null : _registerWithThisTeam,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10)),
                  ),
                ),
              ],
            ]),
          ]),
    );
  }
}

// ============== Create team bottom sheet ==============

class _CreateTeamSheet extends ConsumerStatefulWidget {
  final int? defaultContestId;
  final String? defaultContestTitle;
  const _CreateTeamSheet({
    this.defaultContestId,
    this.defaultContestTitle,
  });

  @override
  ConsumerState<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends ConsumerState<_CreateTeamSheet> {
  final _nameCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên team tối thiểu 2 ký tự')),
      );
      return;
    }
    if (widget.defaultContestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Tạo team từ tab Cuộc thi → Đăng ký để chọn contest cụ thể.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post(
          '/contests/${widget.defaultContestId}/teams',
          data: {'team_name': name});
      if (!mounted) return;
      Navigator.pop(context, res.data as Map<String, dynamic>);
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
                color: context.cardBorder, borderRadius: BorderRadius.circular(AppRadius.tight)),
          ),
          Text('Tạo team mới',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
          const SizedBox(height: 4),
          if (widget.defaultContestTitle != null)
            Text('Cho cuộc thi: ${widget.defaultContestTitle}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tên team *',
              hintText: 'VD: Team Phượng Hoàng',
              prefixIcon: Icon(Icons.groups, size: 18),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn sẽ là leader. Sau khi tạo team có thể thêm thành viên bằng MSSV.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _create,
              icon: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 16),
              label: Text(_busy ? 'Đang tạo...' : 'Tạo team'),
            ),
          ),
        ]),
      ),
    );
  }
}
