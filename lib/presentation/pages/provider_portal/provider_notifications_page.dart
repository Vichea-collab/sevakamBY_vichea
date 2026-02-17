import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/order_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../chat/chat_list_page.dart';
import 'provider_orders_page.dart';

class ProviderNotificationsPage extends StatefulWidget {
  static const String routeName = '/provider/notifications';

  const ProviderNotificationsPage({super.key});

  @override
  State<ProviderNotificationsPage> createState() =>
      _ProviderNotificationsPageState();
}

class _ProviderNotificationsPageState extends State<ProviderNotificationsPage> {
  final Set<String> _clearedNoticeKeys = <String>{};
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshNotifications(forceNetwork: true));
    _ticker = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!mounted) return;
      unawaited(_refreshNotifications());
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ProviderOrderItem>>(
      valueListenable: OrderState.providerOrders,
      builder: (context, orders, _) {
        final incoming = orders
            .where((item) => item.state == ProviderOrderState.incoming)
            .length;
        final active = orders
            .where(
              (item) =>
                  item.state == ProviderOrderState.onTheWay ||
                  item.state == ProviderOrderState.started,
            )
            .length;
        final completed = orders
            .where((item) => item.state == ProviderOrderState.completed)
            .length;
        final declined = orders
            .where((item) => item.state == ProviderOrderState.declined)
            .length;
        final notices = <_ProviderNoticeEntry>[
          _ProviderNoticeEntry(
            key: 'incoming:$incoming',
            title: 'Order Incoming',
            description: '$incoming live request(s) waiting for your action.',
            timeLabel: _timeAgo(
              _latestStatusTime(
                orders.where(
                  (item) => item.state == ProviderOrderState.incoming,
                ),
              ),
            ),
            icon: Icons.inbox_rounded,
            color: const Color(0xFFF59E0B),
            tab: ProviderOrderTab.incoming,
          ),
          _ProviderNoticeEntry(
            key: 'active:$active',
            title: 'Orders In Progress',
            description:
                '$active live order(s) in progress. Keep updating client.',
            timeLabel: _timeAgo(
              _latestStatusTime(
                orders.where(
                  (item) =>
                      item.state == ProviderOrderState.onTheWay ||
                      item.state == ProviderOrderState.started,
                ),
              ),
            ),
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFF7C6EF2),
            tab: ProviderOrderTab.active,
          ),
          _ProviderNoticeEntry(
            key: 'completed:$completed',
            title: 'Order Completed',
            description:
                '$completed completed order(s). Check recent feedback.',
            timeLabel: _timeAgo(
              _latestStatusTime(
                orders.where(
                  (item) => item.state == ProviderOrderState.completed,
                ),
              ),
            ),
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            tab: ProviderOrderTab.completed,
          ),
          _ProviderNoticeEntry(
            key: 'declined:$declined',
            title: 'Order Declined',
            description: '$declined declined order(s) in history.',
            timeLabel: _timeAgo(
              _latestStatusTime(
                orders.where(
                  (item) => item.state == ProviderOrderState.declined,
                ),
              ),
            ),
            icon: Icons.cancel_rounded,
            color: AppColors.danger,
            tab: ProviderOrderTab.completed,
          ),
        ];
        final visibleNotices = notices
            .where((row) => !_clearedNoticeKeys.contains(row.key))
            .toList();

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _refreshNotifications(forceNetwork: true),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppTopBar(
                    title: 'Notifications',
                    showBack: false,
                    actions: [
                      IconButton(
                        onPressed: () => _openMessenger(context),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        tooltip: 'Messenger',
                      ),
                      TextButton(
                        onPressed: () => _confirmClearAll(context, notices),
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibleNotices.isNotEmpty) ...[
                    _ProviderNotificationSummary(
                      incoming: incoming,
                      active: active,
                      completed: completed,
                    ),
                    const SizedBox(height: 14),
                    ...visibleNotices.map(
                      (notice) => _NotificationTile(
                        title: notice.title,
                        description: notice.description,
                        timeLabel: notice.timeLabel,
                        icon: notice.icon,
                        color: notice.color,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProviderOrdersPage(initialTab: notice.tab),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 34,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 36,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No notifications yet',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const AppBottomNav(
            current: AppBottomTab.notification,
          ),
        );
      },
    );
  }

  void _openMessenger(BuildContext context) {
    Navigator.pushNamed(context, ChatListPage.routeName);
  }

  Future<void> _refreshNotifications({bool forceNetwork = false}) {
    return OrderState.refreshCurrentRole(
      forceNetwork: forceNetwork || !OrderState.realtimeActive.value,
    );
  }

  DateTime? _latestStatusTime(Iterable<ProviderOrderItem> items) {
    DateTime? latest;
    for (final item in items) {
      final eventTime = _statusTime(item);
      if (eventTime == null) continue;
      if (latest == null || eventTime.isAfter(latest)) {
        latest = eventTime;
      }
    }
    return latest;
  }

  DateTime? _statusTime(ProviderOrderItem item) {
    final timeline = item.timeline;
    return switch (item.state) {
      ProviderOrderState.incoming => timeline.bookedAt,
      ProviderOrderState.onTheWay => timeline.onTheWayAt ?? timeline.bookedAt,
      ProviderOrderState.started =>
        timeline.startedAt ?? timeline.onTheWayAt ?? timeline.bookedAt,
      ProviderOrderState.completed =>
        timeline.completedAt ??
            timeline.startedAt ??
            timeline.onTheWayAt ??
            timeline.bookedAt,
      ProviderOrderState.declined => timeline.declinedAt ?? timeline.bookedAt,
    };
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Just now';
    final delta = DateTime.now().difference(date);
    if (delta.isNegative) return 'Just now';
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inHours < 1) {
      final minute = delta.inMinutes;
      return '$minute min ago';
    }
    if (delta.inDays < 1) {
      final hour = delta.inHours;
      return '$hour hr ago';
    }
    final day = delta.inDays;
    return '$day day${day > 1 ? 's' : ''} ago';
  }

  void _clearAll(List<_ProviderNoticeEntry> notices) {
    setState(() {
      _clearedNoticeKeys.addAll(notices.map((e) => e.key));
    });
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    List<_ProviderNoticeEntry> notices,
  ) async {
    final shouldClear = await showAppConfirmDialog(
      context: context,
      icon: Icons.delete_sweep_rounded,
      title: 'Clear all notifications?',
      message: 'This will remove all current notifications from this screen.',
      confirmText: 'Clear all',
      cancelText: 'Cancel',
      tone: AppDialogTone.warning,
    );
    if (shouldClear != true || !context.mounted) return;
    _clearAll(notices);
  }
}

class _ProviderNoticeEntry {
  final String key;
  final String title;
  final String description;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final ProviderOrderTab tab;

  const _ProviderNoticeEntry({
    required this.key,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.tab,
  });
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String description;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderNotificationSummary extends StatelessWidget {
  final int incoming;
  final int active;
  final int completed;

  const _ProviderNotificationSummary({
    required this.incoming,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5CC7), Color(0xFF5F6CE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$incoming incoming • $active active • $completed completed',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
