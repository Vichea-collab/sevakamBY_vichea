import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/order_state.dart';
import '../../state/user_notification_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../chat/chat_list_page.dart';
import 'provider_home_page.dart';
import 'provider_orders_page.dart';

class ProviderNotificationsPage extends StatefulWidget {
  static const String routeName = '/provider/notifications';

  const ProviderNotificationsPage({super.key});

  @override
  State<ProviderNotificationsPage> createState() =>
      _ProviderNotificationsPageState();
}

class _ProviderNotificationsPageState extends State<ProviderNotificationsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshNotifications(forceNetwork: true));
      unawaited(UserNotificationState.refresh());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(_refreshNotifications());
    unawaited(UserNotificationState.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ProviderOrderItem>>(
      valueListenable: OrderState.providerOrders,
      builder: (context, orders, _) {
        return ValueListenableBuilder<List<UserNotificationItem>>(
          valueListenable: UserNotificationState.notices,
          builder: (context, adminNotices, _) {
            return ValueListenableBuilder<int>(
              valueListenable: UserNotificationState.readStateVersion,
              builder: (context, readStateVersion, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: UserNotificationState.loading,
                  builder: (context, loading, _) {
                    final incoming = orders
                        .where(
                          (item) => item.state == ProviderOrderState.incoming,
                        )
                        .length;
                    final active = orders
                        .where(
                          (item) =>
                              item.state == ProviderOrderState.onTheWay ||
                              item.state == ProviderOrderState.started,
                        )
                        .length;
                    final completed = orders
                        .where(
                          (item) => item.state == ProviderOrderState.completed,
                        )
                        .length;
                    final backendItems = _buildAdminNotices(adminNotices)
                        .where(
                          (row) => !UserNotificationState.isCleared(
                            _providerAdminStateKey(row.key),
                          ),
                        )
                        .toList(growable: false);

                    final Widget body = loading
                        ? const SizedBox(
                            height: 320,
                            child: Center(
                              child: AppStatePanel.loading(
                                title: 'Loading notifications',
                              ),
                            ),
                          )
                        : Column(
                            key: ValueKey<String>(
                              'provider_notice_content_${backendItems.length}',
                            ),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProviderNotificationSummary(
                                incoming: incoming,
                                active: active,
                                completed: completed,
                              ),
                              const SizedBox(height: 14),
                              if (backendItems.isNotEmpty) ...[
                                Text(
                                  'Recent Updates',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                ...backendItems.map(
                                  (notice) => _NotificationTile(
                                    title: notice.title,
                                    description: notice.description,
                                    timeLabel: notice.timeLabel,
                                    icon: notice.icon,
                                    color: notice.color,
                                    onTap: () {
                                      if (notice.key.startsWith('order:')) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => ProviderOrdersPage(
                                              initialTab: notice.tab,
                                            ),
                                          ),
                                        );
                                      } else {
                                        unawaited(
                                          UserNotificationState.clear(
                                            _providerAdminStateKey(notice.key),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ] else
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: AppStatePanel.empty(
                                    title: 'No recent updates',
                                    message:
                                        'New order activities will appear here.',
                                  ),
                                ),
                            ],
                          );

                    return Scaffold(
                      body: SafeArea(
                        child: RefreshIndicator(
                          onRefresh: _refreshFeed,
                          child: ListView(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            children: [
                              AppTopBar(
                                title: 'Notifications',
                                showBack: true,
                                onBack: () => Navigator.pushReplacementNamed(
                                  context,
                                  ProviderPortalHomePage.routeName,
                                ),
                                actions: [
                                  IconButton(
                                    onPressed: () => _openMessenger(context),
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                    ),
                                    tooltip: 'Messenger',
                                  ),
                                  TextButton(
                                    onPressed: () => _confirmClearAll(
                                      context,
                                      backendItems,
                                    ),
                                    child: const Text('Clear all'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: body,
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
          },
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

  Future<void> _refreshFeed() async {
    await Future.wait<void>([
      _refreshNotifications(forceNetwork: true),
      UserNotificationState.refresh(),
    ]);
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

  String _providerAdminStateKey(String key) {
    return 'provider:admin:${key.trim()}';
  }

  List<_ProviderNoticeEntry> _buildAdminNotices(
    List<UserNotificationItem> notices,
  ) {
    final sorted = List<UserNotificationItem>.from(notices)
      ..sort((a, b) {
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    return sorted
        .map((item) {
          final isOrderStatus = item.source == 'order_status';
          final lifecycle = item.lifecycle;
          final stateLabel = lifecycle == 'active'
              ? 'Active'
              : lifecycle == 'scheduled'
              ? 'Scheduled'
              : lifecycle == 'expired'
              ? 'Expired'
              : 'Inactive';
          final code = item.promoCode.trim();
          final description = isOrderStatus
              ? item.message
              : item.isPromo
              ? code.isEmpty
                    ? '${item.message} • $stateLabel'
                    : '${item.message} • Code: $code • $stateLabel'
              : '${item.message} • $stateLabel';
          final color = isOrderStatus
              ? _orderStatusColor(item.orderStatus)
              : item.isPromo
              ? (lifecycle == 'active'
                    ? AppColors.success
                    : lifecycle == 'scheduled'
                    ? const Color(0xFFF59E0B)
                    : AppColors.danger)
              : AppColors.primary;
          return _ProviderNoticeEntry(
            key: isOrderStatus ? 'order:${item.id}' : 'admin:${item.id}',
            title: item.title,
            description: description,
            timeLabel: _timeAgo(item.createdAt),
            icon: isOrderStatus
                ? _orderStatusIcon(item.orderStatus)
                : item.isPromo
                ? Icons.local_offer_rounded
                : Icons.campaign_rounded,
            color: color,
            tab: isOrderStatus
                ? _orderStatusTab(item.orderStatus)
                : ProviderOrderTab.active,
          );
        })
        .toList(growable: false);
  }

  ProviderOrderTab _orderStatusTab(String status) {
    switch (status.trim().toLowerCase()) {
      case 'booked':
        return ProviderOrderTab.incoming;
      case 'on_the_way':
      case 'started':
        return ProviderOrderTab.active;
      case 'completed':
      case 'cancelled':
      case 'declined':
      default:
        return ProviderOrderTab.completed;
    }
  }

  IconData _orderStatusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'booked':
        return Icons.inbox_rounded;
      case 'on_the_way':
        return Icons.delivery_dining_rounded;
      case 'started':
        return Icons.handyman_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'declined':
      default:
        return Icons.highlight_off_rounded;
    }
  }

  Color _orderStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'booked':
        return const Color(0xFFF59E0B);
      case 'on_the_way':
      case 'started':
        return const Color(0xFF7C6EF2);
      case 'completed':
        return AppColors.success;
      case 'cancelled':
      case 'declined':
      default:
        return AppColors.danger;
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    List<_ProviderNoticeEntry> adminNotices,
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
    unawaited(
      UserNotificationState.clearMany(
        adminNotices.map((entry) => _providerAdminStateKey(entry.key)),
      ),
    );
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
