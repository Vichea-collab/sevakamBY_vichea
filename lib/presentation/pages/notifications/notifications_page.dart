import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/order.dart';
import '../../state/order_state.dart';
import '../../state/user_notification_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../chat/chat_list_page.dart';

enum _NoticeFilter { all, orders, system, promos }

class NotificationsPage extends StatefulWidget {
  static const String routeName = '/notifications';

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NoticeFilter _filter = _NoticeFilter.all;
  final Set<String> _readUpdateKeys = <String>{};
  final Set<String> _readPromoTitles = <String>{};
  final Set<String> _clearedUpdateKeys = <String>{};
  final Set<String> _clearedPromoTitles = <String>{};
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshNotifications(forceNetwork: true));
    unawaited(UserNotificationState.refresh());
    _ticker = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!mounted) return;
      unawaited(_refreshNotifications());
      unawaited(UserNotificationState.refresh());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OrderItem>>(
      valueListenable: OrderState.finderOrders,
      builder: (context, orders, _) {
        return ValueListenableBuilder<List<UserNotificationItem>>(
          valueListenable: UserNotificationState.notices,
          builder: (context, notices, _) {
            final backendSystemUpdates = _buildSystemUpdates(notices);
            final backendPromos = _buildPromoNotices(notices);

            final liveUpdates = <_NotificationUpdate>[
              ..._buildOrderUpdates(orders),
              ...backendSystemUpdates,
            ];
            final updates = liveUpdates
                .map(
                  (item) => item.copyWith(
                    unread: !_readUpdateKeys.contains(item.key),
                  ),
                )
                .where((item) => !_clearedUpdateKeys.contains(item.key))
                .toList();
            final promos = backendPromos
                .map(
                  (item) => item.copyWith(
                    unread: !_readPromoTitles.contains(item.id),
                  ),
                )
                .where((item) => !_clearedPromoTitles.contains(item.id))
                .toList();

            final visibleUpdates = updates.where((item) {
              return _filter == _NoticeFilter.all ||
                  (_filter == _NoticeFilter.orders &&
                      item.kind == _NoticeFilter.orders) ||
                  (_filter == _NoticeFilter.system &&
                      item.kind == _NoticeFilter.system);
            }).toList();

            final visiblePromos = promos.where((_) {
              return _filter == _NoticeFilter.all ||
                  _filter == _NoticeFilter.promos;
            }).toList();

            final unreadCount =
                updates.where((item) => item.unread).length +
                promos.where((item) => item.unread).length;
            final totalCount = updates.length + promos.length;

            return Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: _refreshFeed,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    children: [
                      AppTopBar(
                        title: 'Notifications',
                        showBack: false,
                        actions: [
                          IconButton(
                            onPressed: _openMessenger,
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            tooltip: 'Messenger',
                          ),
                          TextButton(
                            onPressed: () => _markAllAsRead(updates, promos),
                            child: const Text('Mark all'),
                          ),
                          TextButton(
                            onPressed: () =>
                                _confirmClearAllNotifications(context),
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _HeroCard(
                        unreadCount: unreadCount,
                        totalCount: totalCount,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filter == _NoticeFilter.all,
                              onTap: () =>
                                  setState(() => _filter = _NoticeFilter.all),
                            ),
                            _FilterChip(
                              label: 'Orders',
                              selected: _filter == _NoticeFilter.orders,
                              onTap: () => setState(
                                () => _filter = _NoticeFilter.orders,
                              ),
                            ),
                            _FilterChip(
                              label: 'System',
                              selected: _filter == _NoticeFilter.system,
                              onTap: () => setState(
                                () => _filter = _NoticeFilter.system,
                              ),
                            ),
                            _FilterChip(
                              label: 'Promotions',
                              selected: _filter == _NoticeFilter.promos,
                              onTap: () => setState(
                                () => _filter = _NoticeFilter.promos,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (visibleUpdates.isNotEmpty) ...[
                        Text(
                          'Recent Updates',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: List.generate(visibleUpdates.length, (
                              index,
                            ) {
                              final item = visibleUpdates[index];
                              return _UpdateTile(
                                item: item,
                                isLast: index == visibleUpdates.length - 1,
                                onTap: () => _markUpdateAsRead(item.key),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (visiblePromos.isNotEmpty) ...[
                        Text(
                          'Promotions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: List.generate(visiblePromos.length, (
                              index,
                            ) {
                              final item = visiblePromos[index];
                              return _PromoTile(
                                item: item,
                                isLast: index == visiblePromos.length - 1,
                                onTap: () => _markPromoAsRead(item.id),
                              );
                            }),
                          ),
                        ),
                      ],
                      if (visibleUpdates.isEmpty && visiblePromos.isEmpty)
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
      },
    );
  }

  void _markAllAsRead(
    List<_NotificationUpdate> updates,
    List<_PromoNotice> promos,
  ) {
    setState(() {
      _readUpdateKeys.addAll(updates.map((e) => e.key));
      _readPromoTitles.addAll(promos.map((e) => e.id));
    });
  }

  void _clearAllNotifications() {
    final orderUpdateKeys = _buildOrderUpdates(OrderState.finderOrders.value)
        .where((item) => item.kind == _NoticeFilter.orders)
        .map((item) => item.key);
    setState(() {
      _clearedUpdateKeys.addAll(orderUpdateKeys);
      _readUpdateKeys.addAll(orderUpdateKeys);
    });
  }

  Future<void> _confirmClearAllNotifications(BuildContext context) async {
    final shouldClear = await showAppConfirmDialog(
      context: context,
      icon: Icons.delete_sweep_rounded,
      title: 'Clear all order notifications?',
      message:
          'This only removes order updates from this screen. System and Promotions stay visible.',
      confirmText: 'Clear all',
      cancelText: 'Cancel',
      tone: AppDialogTone.warning,
    );
    if (shouldClear != true || !context.mounted) return;
    _clearAllNotifications();
  }

  void _markUpdateAsRead(String key) {
    setState(() {
      _readUpdateKeys.add(key);
    });
  }

  void _markPromoAsRead(String id) {
    setState(() {
      _readPromoTitles.add(id);
    });
  }

  void _openMessenger() {
    Navigator.pushNamed(context, ChatListPage.routeName);
  }

  Future<void> _refreshNotifications({bool forceNetwork = false}) {
    return OrderState.refreshCurrentRole(
      forceNetwork: forceNetwork || !OrderState.realtimeActive.value,
    );
  }

  Future<void> _refreshFeed() async {
    await Future.wait<void>([
      _refreshNotifications(forceNetwork: true),
      UserNotificationState.refresh(),
    ]);
  }

  List<_NotificationUpdate> _buildOrderUpdates(List<OrderItem> orders) {
    final sortedOrders = List<OrderItem>.from(orders)
      ..sort(
        (a, b) =>
            _statusEventTime(b).millisecondsSinceEpoch -
            _statusEventTime(a).millisecondsSinceEpoch,
      );
    final updates = <_NotificationUpdate>[];
    for (final order in sortedOrders) {
      final status = order.status;
      final label = switch (status) {
        OrderStatus.booked => 'Order Booked',
        OrderStatus.onTheWay => 'Provider On The Way',
        OrderStatus.started => 'Service Started',
        OrderStatus.completed => 'Order Completed',
        OrderStatus.cancelled => 'Order Cancelled',
        OrderStatus.declined => 'Order Declined',
      };
      final icon = switch (status) {
        OrderStatus.booked => Icons.fact_check_outlined,
        OrderStatus.onTheWay => Icons.delivery_dining_rounded,
        OrderStatus.started => Icons.handyman_rounded,
        OrderStatus.completed => Icons.check_circle_outline_rounded,
        OrderStatus.cancelled => Icons.cancel_outlined,
        OrderStatus.declined => Icons.highlight_off_rounded,
      };
      final color = switch (status) {
        OrderStatus.booked => const Color(0xFFF59E0B),
        OrderStatus.onTheWay => AppColors.primary,
        OrderStatus.started => const Color(0xFF7C6EF2),
        OrderStatus.completed => AppColors.success,
        OrderStatus.cancelled => AppColors.danger,
        OrderStatus.declined => AppColors.danger,
      };

      updates.add(
        _NotificationUpdate(
          key: '${order.id}:${status.name}',
          title: label,
          description:
              '${order.serviceName} with ${order.provider.name} • ${order.address.city}',
          timeLabel: _timeAgo(_statusEventTime(order)),
          icon: icon,
          iconColor: color,
          kind: _NoticeFilter.orders,
          unread: false,
        ),
      );
    }
    return updates;
  }

  List<_NotificationUpdate> _buildSystemUpdates(
    List<UserNotificationItem> notices,
  ) {
    final systems = notices.where((item) => !item.isPromo).toList()
      ..sort((a, b) {
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    return systems
        .map(
          (item) => _NotificationUpdate(
            key: 'system:${item.id}',
            title: item.title,
            description: item.message,
            timeLabel: _timeAgo(item.createdAt ?? DateTime.now()),
            icon: Icons.campaign_outlined,
            iconColor: const Color(0xFF4B5563),
            kind: _NoticeFilter.system,
            unread: false,
          ),
        )
        .toList(growable: false);
  }

  List<_PromoNotice> _buildPromoNotices(List<UserNotificationItem> notices) {
    final promos = notices.where((item) => item.isPromo).toList()
      ..sort((a, b) {
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    return promos
        .map((item) {
          final state = item.lifecycle;
          final isActive = state == 'active';
          final isScheduled = state == 'scheduled';
          final trailingLabel = isActive
              ? 'Active'
              : isScheduled
              ? 'Scheduled'
              : state == 'expired'
              ? 'Expired'
              : 'Inactive';
          final trailingColor = isActive
              ? AppColors.success
              : isScheduled
              ? const Color(0xFFF59E0B)
              : AppColors.danger;
          final start = item.startAt;
          final end = item.endAt;
          String? dateRange;
          if (start != null || end != null) {
            final startLabel = start == null
                ? 'Now'
                : MaterialLocalizations.of(context).formatShortDate(start);
            final endLabel = end == null
                ? 'No end'
                : MaterialLocalizations.of(context).formatShortDate(end);
            dateRange = '$startLabel - $endLabel';
          }
          final code = item.promoCode.trim();
          final description = code.isEmpty
              ? item.message
              : '${item.message}\nCode: $code';
          return _PromoNotice(
            id: item.id,
            title: item.title,
            description: description,
            trailingLabel: trailingLabel,
            trailingColor: trailingColor,
            dateRange: dateRange,
            unread: false,
          );
        })
        .toList(growable: false);
  }

  DateTime _statusEventTime(OrderItem order) {
    return switch (order.status) {
      OrderStatus.booked => order.timeline.bookedAt ?? order.bookedAt,
      OrderStatus.onTheWay =>
        order.timeline.onTheWayAt ?? order.timeline.bookedAt ?? order.bookedAt,
      OrderStatus.started =>
        order.timeline.startedAt ??
            order.timeline.onTheWayAt ??
            order.timeline.bookedAt ??
            order.bookedAt,
      OrderStatus.completed =>
        order.timeline.completedAt ??
            order.timeline.startedAt ??
            order.timeline.onTheWayAt ??
            order.timeline.bookedAt ??
            order.bookedAt,
      OrderStatus.cancelled =>
        order.timeline.cancelledAt ?? order.timeline.bookedAt ?? order.bookedAt,
      OrderStatus.declined =>
        order.timeline.declinedAt ?? order.timeline.bookedAt ?? order.bookedAt,
    };
  }

  String _timeAgo(DateTime date) {
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
}

class _HeroCard extends StatelessWidget {
  final int unreadCount;
  final int totalCount;

  const _HeroCard({required this.unreadCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.splashStart, AppColors.splashEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25005BBB),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount == 0 ? 'You are all caught up' : 'Inbox Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount == 0
                      ? '$totalCount notification${totalCount > 1 ? 's' : ''} reviewed'
                      : '$unreadCount unread notification${unreadCount > 1 ? 's' : ''} out of $totalCount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryPill(label: 'Unread', value: '$unreadCount'),
                    _SummaryPill(label: 'Total', value: '$totalCount'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressableScale(
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateTile extends StatelessWidget {
  final _NotificationUpdate item;
  final bool isLast;
  final VoidCallback onTap;

  const _UpdateTile({
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = item.unread ? AppColors.primary : AppColors.divider;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: item.unread ? const Color(0xFFF8FAFF) : Colors.white,
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.timeLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
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

class _PromoTile extends StatelessWidget {
  final _PromoNotice item;
  final bool isLast;
  final VoidCallback onTap;

  const _PromoTile({
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: item.unread ? const Color(0xFFF8FAFF) : Colors.white,
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.trailingColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: item.trailingColor),
                    ),
                    child: Text(
                      item.trailingLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: item.trailingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (item.dateRange != null) ...[
                const SizedBox(height: 6),
                Text(
                  item.dateRange!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationUpdate {
  final String key;
  final String title;
  final String description;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final _NoticeFilter kind;
  final bool unread;

  const _NotificationUpdate({
    required this.key,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.icon,
    required this.iconColor,
    required this.kind,
    required this.unread,
  });

  _NotificationUpdate copyWith({bool? unread}) {
    return _NotificationUpdate(
      key: key,
      title: title,
      description: description,
      timeLabel: timeLabel,
      icon: icon,
      iconColor: iconColor,
      kind: kind,
      unread: unread ?? this.unread,
    );
  }
}

class _PromoNotice {
  final String id;
  final String title;
  final String description;
  final String trailingLabel;
  final Color trailingColor;
  final String? dateRange;
  final bool unread;

  const _PromoNotice({
    required this.id,
    required this.title,
    required this.description,
    required this.trailingLabel,
    required this.trailingColor,
    this.dateRange,
    required this.unread,
  });

  _PromoNotice copyWith({bool? unread}) {
    return _PromoNotice(
      id: id,
      title: title,
      description: description,
      trailingLabel: trailingLabel,
      trailingColor: trailingColor,
      dateRange: dateRange,
      unread: unread ?? this.unread,
    );
  }
}
