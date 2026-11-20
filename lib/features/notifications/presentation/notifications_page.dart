import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/empty_state.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/pill_chip.dart';
import 'package:nookbook/features/notifications/application/notification_providers.dart';
import 'package:nookbook/features/notifications/domain/app_notification.dart';

/// Màn 25 "Trung tâm thông báo" và màn 27 "Chưa có thông báo".
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  NotificationKind? _filter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    final read = ref.watch(readNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PillChip(label: 'Tất cả', selected: true),
                  ),
                ),
                const SizedBox(height: 24),
                EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'Một khoảng lặng dễ chịu',
                  message:
                      'Bạn chưa có thông báo mới. Tin về đơn hàng, sách hay và ưu đãi sẽ xuất hiện tại đây.',
                  buttonLabel: 'Khám phá sách',
                  onPressed: () => context.go(AppRoutes.categoryBooks),
                ),
              ],
            );
          }
          final unread = all.where((n) => !read.contains(n.id)).length;
          final list =
              _filter == null ? all : all.where((n) => n.kind == _filter).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$unread chưa đọc',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: unread == 0
                        ? null
                        : () => ref
                            .read(readNotificationsProvider.notifier)
                            .markAllRead(all.map((n) => n.id)),
                    child: const Text('Đọc tất cả'),
                  ),
                ],
              ),
              Row(
                children: [
                  PillChip(
                      label: 'Tất cả',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null)),
                  const SizedBox(width: 8),
                  PillChip(
                      label: 'Đơn hàng',
                      selected: _filter == NotificationKind.order,
                      onTap: () => setState(() => _filter = NotificationKind.order)),
                  const SizedBox(width: 8),
                  PillChip(
                      label: 'Sách & ưu đãi',
                      selected: _filter == NotificationKind.promo,
                      onTap: () => setState(() => _filter = NotificationKind.promo)),
                ],
              ),
              const SizedBox(height: 16),
              for (final n in list) ...[
                _NotificationCard(
                  n: n,
                  unread: !read.contains(n.id),
                  onTap: () {
                    ref.read(readNotificationsProvider.notifier).markRead(n.id);
                    context.push(AppRoutes.notificationDetail(n.id));
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.n, required this.unread, required this.onTap});

  final AppNotification n;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(n.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(n.body,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(relativeTime(n.time),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
