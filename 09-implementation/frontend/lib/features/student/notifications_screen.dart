import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';
import 'student_shell.dart' show studentTabProvider;

/// Phase 2 sprint 1 step 1 (2026-05-06): map deep-link route ảo (BE convention)
/// sang tab index của StudentShell. Lý do: StudentShell có 6 tab bottom nav,
/// KHÔNG phải 6 GoRouter route riêng — tab index là state, KHÔNG phải URL.
/// BE giữ semantic route `/me/entries` (intuitive), FE map sang tab index 2.
const Map<String, int> _shellTabRoutes = {
  '/me/entries': 2,        // Tab "Của tôi" — đơn đăng ký
  '/me/results': 3,        // Tab "Kết quả"
  '/me/notifications': 4,  // Tab "Thông báo" (đã ở đây)
  '/me/profile': 5,        // Tab "Tôi"
};

final notificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/notifications', queryParameters: {'limit': 50});
  return res.data as Map<String, dynamic>;
});

/// Reusable badge để hiện ở top bar các màn khác.
class NotificationBadge extends ConsumerWidget {
  final VoidCallback onTap;
  const NotificationBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(notificationsProvider);
    final unread = asyncData.maybeWhen(
      data: (d) => d['unread_count'] as int? ?? 0,
      orElse: () => 0,
    );
    // Sprint 5 Semantics: chuông thông báo có announce số lượng chưa đọc
    final badgeLabel = unread == 0
        ? 'Thông báo, không có thông báo mới'
        : 'Thông báo, $unread chưa đọc';
    return Stack(clipBehavior: Clip.none, children: [
      Semantics(
        label: badgeLabel,
        button: true,
        hint: 'Mở danh sách thông báo',
        child: IconButton(
          tooltip: 'Thông báo',
          onPressed: onTap,
          icon: Icon(Icons.notifications_outlined, color: context.textMuted),
          visualDensity: VisualDensity.compact,
        ),
      ),
      if (unread > 0)
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
                color: ptitRed, borderRadius: BorderRadius.circular(AppRadius.sm)),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
            child: Text(
              unread > 99 ? '99+' : '$unread',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
    ]);
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(notificationsProvider);
    final canPop = Navigator.canPop(context);
    return Scaffold(
      appBar: MTopBar(
        title: 'Thông báo',
        leading: canPop
            ? IconButton(
                // Sprint 3 a11y fix: tooltip cho back arrow IconButton
                tooltip: 'Quay lại',
                icon: Icon(Icons.arrow_back, color: context.textMuted),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        actions: [
          asyncData.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final unread = data['unread_count'] as int? ?? 0;
              if (unread == 0) return const SizedBox.shrink();
              return Semantics(
                label: 'Đọc tất cả — đánh dấu $unread thông báo đã đọc',
                button: true,
                hint: 'Xóa badge chưa đọc cho toàn bộ list',
                child: TextButton(
                  onPressed: () => _markAllRead(context, ref),
                  child: const Text('Đọc tất',
                      style: TextStyle(color: ptitRed, fontSize: 12)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: asyncData.when(
        // Phase 2 step 5 (2026-05-06): skeleton thay spinner cho UX modern
        loading: () => const MCardListSkeleton(count: 5, textLines: 2),
        error: (e, _) => Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: ${_msg(e)}',
                    style: const TextStyle(color: ptitRed),
                    textAlign: TextAlign.center))),
        data: (data) {
          final items = (data['items'] as List).cast<Map<String, dynamic>>();
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 56, color: context.textMuted),
                  SizedBox(height: 12),
                  Text('Chưa có thông báo nào',
                      style: TextStyle(color: context.textMuted, fontSize: 13)),
                ]),
              ),
            );
          }
          return RefreshIndicator(
            color: ptitRed,
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  _NotificationCard(data: items[i], onTap: () => _markRead(context, ref, items[i])),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markRead(
      BuildContext context, WidgetRef ref, Map<String, dynamic> notif) async {
    // Phase 2 sprint 1 step 1 (2026-05-06): mark read + deep-link navigate.
    // Logic:
    // - Nếu chưa đọc → PATCH mark read (fire-and-forget, không await navigate)
    // - Nếu có target_route → navigate ngay (không cần đợi mark read xong)
    // - Nếu null target_route → ở lại screen list (legacy behavior)
    final notifId = notif['notification_id'];
    final isRead = notif['is_read'] == true;
    final targetRoute = notif['target_route'] as String?;

    // Mark read async (không block navigate)
    if (!isRead) {
      try {
        final api = ref.read(apiClientProvider);
        // Không await — navigate trước, mark read background
        api.dio.patch('/me/notifications/$notifId/read').then((_) {
          ref.invalidate(notificationsProvider);
        }).catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
          }
        });
      } catch (_) {/* swallow */}
    }

    // Deep-link navigate nếu có
    if (targetRoute != null && targetRoute.isNotEmpty && context.mounted) {
      // Phase 2 sprint 1 step 1 fix (2026-05-06): map route ảo /me/* sang
      // tab index của StudentShell (vì 6 tab là state, KHÔNG phải GoRouter route).
      final tabIdx = _shellTabRoutes[targetRoute];
      if (tabIdx != null) {
        // Set provider tab index → StudentShell tự switch tab tới target.
        ref.read(studentTabProvider.notifier).state = tabIdx;
        // Phase 2 sprint 1 step 1 fix v2 (2026-05-06): nếu NotificationsScreen
        // được mở như sub-route (push từ icon chuông top bar trên screen khác),
        // pop nó về để user thấy StudentShell với tab vừa switch. Khi user
        // đang ở tab Thông báo (trong StudentShell shell), canPop=false → no-op.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        // Route thật (vd /contests/abc, /admin/contests/5/manage) → push như cũ.
        try {
          context.push(targetRoute);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Không tìm thấy màn hình: $targetRoute')));
          }
        }
      }
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/me/notifications/mark-all-read');
      ref.invalidate(notificationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Đã đọc ${res.data['marked_read'] ?? 0} thông báo')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _NotificationCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    final created = DateTime.parse(data['created_at']);
    final isRead = data['is_read'] == true;
    final scope = data['scope'] as String?;

    // Sprint 5 Semantics: tổng hợp title + scope + read-state + message + thời gian
    final title = data['title'] ?? '';
    final message = data['message'] ?? '';
    final readPrefix = isRead ? 'Đã đọc' : 'Chưa đọc';
    final scopePrefix = scope == null ? '' : '[$scope] ';
    final timeText = fmt.format(created);
    final notifLabel =
        '$readPrefix. $scopePrefix$title. $message. Lúc $timeText';

    return Semantics(
      label: notifLabel,
      button: true,
      onTap: onTap,
      hint: isRead
          ? 'Mở chi tiết'
          : 'Mở chi tiết và đánh dấu đã đọc',
      child: ExcludeSemantics(child: MCard(
      onTap: onTap,
      backgroundColor: isRead ? null : context.ptitRedSoft.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                    color: ptitRed, shape: BoxShape.circle),
              ),
            Expanded(
              child: Text(data['title'] ?? '',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: context.textPrimary)),
            ),
            if (scope != null) ...[
              const SizedBox(width: 6),
              Pill(
                label: scope,
                color: context.textMuted,
                bg: const Color(0xFFF3F4F6),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Text(data['message'] ?? '',
              style: TextStyle(fontSize: 12, color: context.textPrimary, height: 1.4)),
          const SizedBox(height: 6),
          Text(fmt.format(created),
              style: TextStyle(fontSize: 10, color: context.textMuted)),
        ],
      ),
    )),
    );
  }
}

String _msg(Object e) => e is DioException
    ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
    : '$e';
