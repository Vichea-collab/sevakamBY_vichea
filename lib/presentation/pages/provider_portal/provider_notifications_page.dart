import 'dart:async';

import 'package:flutter/material.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/constants/app_spacing.dart';
import 'package:servicefinder/core/theme/app_theme_tokens.dart';
import 'package:servicefinder/core/utils/listenable_utils.dart';
import 'package:servicefinder/core/utils/time_utils.dart';
import 'package:servicefinder/domain/entities/provider_portal.dart';
import 'package:servicefinder/presentation/state/order_state.dart';
import 'package:servicefinder/presentation/state/user_notification_state.dart';
import 'package:servicefinder/presentation/widgets/app_dialog.dart';
import 'package:servicefinder/presentation/widgets/app_state_panel.dart';
import 'package:servicefinder/presentation/widgets/app_top_bar.dart';
import 'package:servicefinder/presentation/widgets/pressable_scale.dart';
import 'package:servicefinder/presentation/pages/chat/chat_list_page.dart';
import 'package:servicefinder/presentation/pages/main_shell_page.dart';
import 'package:servicefinder/presentation/pages/profile/help_support_page.dart';
import 'package:servicefinder/presentation/widgets/app_bottom_nav.dart';
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
  static const Duration _autoRefreshCooldown = Duration(seconds: 30);

  bool _screenLoading = true;
  bool _screenRefreshInFlight = false;
  bool _initialLoadComplete = false;
  DateTime? _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MainShellPage.activeTab.addListener(_handleActiveTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_requestLoad());
    });
  }

  @override
  void dispose() {
    MainShellPage.activeTab.removeListener(_handleActiveTabChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(_requestLoad());
  }

  void _handleActiveTabChanged() {
    if (!mounted ||
        MainShellPage.activeTab.value != AppBottomTab.notification) {
      return;
    }
    unawaited(_requestLoad());
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
                    if (_screenLoading && !_initialLoadComplete) {
                      return Scaffold(
                        body: SafeArea(
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            children: [
                              AppTopBar(
                                title: 'Notifications',
                                showBack: true,
                                onBack: () => MainShellPage.activeTab.value =
                                    AppBottomTab.home,
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(
                                height: 320,
                                child: Center(
                                  child: AppStatePanel.loading(
                                    title: 'Loading notifications',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

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
                    final showSummary =
                        incoming > 0 ||
                        active > 0 ||
                        completed > 0 ||
                        backendItems.isEmpty;

                    final Widget body = Column(
                      key: ValueKey<String>(
                        'provider_notice_content_${backendItems.length}',
                      ),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showSummary) ...[
                          _ProviderNotificationSummary(
                            incoming: incoming,
                            active: active,
                            completed: completed,
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (backendItems.isNotEmpty) ...[
                          Text(
                            'Recent Updates',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppThemeTokens.textPrimary(context),
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
                                  ProviderOrdersPage.requestedTab.value =
                                      notice.tab;
                                  MainShellPage.activeTab.value =
                                      AppBottomTab.order;
                                } else if (notice.source == 'chat_message') {
                                  Navigator.pushNamed(
                                    context,
                                    ChatListPage.routeName,
                                  );
                                  unawaited(
                                    UserNotificationState.clear(
                                      _providerAdminStateKey(notice.key),
                                    ),
                                  );
                                } else if (notice.source == 'support_message') {
                                  Navigator.pushNamed(
                                    context,
                                    HelpSupportPage.routeName,
                                  );
                                  unawaited(
                                    UserNotificationState.clear(
                                      _providerAdminStateKey(notice.key),
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
                              message: 'New order activities will appear here.',
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
                                onBack: () => MainShellPage.activeTab.value =
                                    AppBottomTab.home,
                                actions: [
                                  IconButton(
                                    onPressed: () => _openMessenger(context),
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                    ),
                                    tooltip: 'Messenger',
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _confirmClearAll(context, backendItems),
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

  // Delegated to shared waitUntilNotLoading in listenable_utils.dart

  Future<void> _refreshNotificationsAndWait({bool forceNetwork = false}) async {
    if (OrderState.loading.value) {
      await waitUntilNotLoading(OrderState.loading);
    }
    await _refreshNotifications(forceNetwork: true);
    await waitUntilNotLoading(OrderState.loading);
  }

  Future<void> _refreshAdminNoticesAndWait() async {
    await UserNotificationState.refresh();
    await waitUntilNotLoading(UserNotificationState.loading);
  }

  Future<void> _loadScreen({bool forceNetwork = false}) async {
    if (_screenRefreshInFlight) return;
    final hasCachedOrders = OrderState.providerOrders.value.isNotEmpty;
    final hasCachedNotices = UserNotificationState.notices.value.isNotEmpty;
    final hasFreshCache =
        !forceNetwork &&
        (hasCachedOrders || hasCachedNotices) &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _autoRefreshCooldown;
    if (hasFreshCache) {
      if (mounted && !_initialLoadComplete) {
        setState(() {
          _screenLoading = false;
          _initialLoadComplete = true;
        });
      }
      return;
    }
    _screenRefreshInFlight = true;
    if (mounted && !_initialLoadComplete) {
      setState(() => _screenLoading = true);
    }
    try {
      await Future.wait<void>([
        _refreshNotificationsAndWait(forceNetwork: forceNetwork),
        _refreshAdminNoticesAndWait(),
      ]);
    } finally {
      _screenRefreshInFlight = false;
      _lastLoadedAt = DateTime.now();
      if (mounted) {
        setState(() {
          _screenLoading = false;
          _initialLoadComplete = true;
        });
      }
    }
  }

  Future<void> _refreshFeed() async {
    await _loadScreen(forceNetwork: true);
  }

  Future<void> _requestLoad() async {
    await _loadScreen(forceNetwork: !_initialLoadComplete);
  }

  // Delegated to shared timeAgo() in time_utils.dart

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
          final isChatMessage = item.source == 'chat_message';
          final isSupportMessage = item.source == 'support_message';
          final lifecycle = item.lifecycle;
          final stateLabel = lifecycle == 'active'
              ? 'Active'
              : lifecycle == 'scheduled'
              ? 'Scheduled'
              : lifecycle == 'expired'
              ? 'Expired'
              : 'Inactive';
          final description = isOrderStatus
              ? item.message
              : (isChatMessage || isSupportMessage)
              ? item.message
              : item.isPromo
              ? '${item.message} • $stateLabel'
              : '${item.message} • $stateLabel';
          final color = isOrderStatus
              ? _orderStatusColor(item.orderStatus)
              : isChatMessage
              ? AppColors.primary
              : isSupportMessage
              ? const Color(0xFFF59E0B)
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
            timeLabel: timeAgo(item.createdAt),
            icon: isOrderStatus
                ? _orderStatusIcon(item.orderStatus)
                : isChatMessage
                ? Icons.chat_bubble_outline_rounded
                : isSupportMessage
                ? Icons.support_agent_rounded
                : item.isPromo
                ? Icons.local_offer_rounded
                : Icons.campaign_rounded,
            color: color,
            source: item.source,
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
        return Icons.verified_rounded;
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
  final String source;
  final ProviderOrderTab tab;

  const _ProviderNoticeEntry({
    required this.key,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.source,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppThemeTokens.outline(context)),
            boxShadow: AppThemeTokens.cardShadow(context),
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
                                  color: AppThemeTokens.textPrimary(context),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppThemeTokens.textSecondary(context),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemeTokens.textSecondary(context),
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
    final stats = <_ProviderNotificationStat>[
      _ProviderNotificationStat(
        label: 'Upcoming',
        value: incoming,
        icon: Icons.mark_email_unread_rounded,
        color: const Color(0xFFFFC857),
      ),
      _ProviderNotificationStat(
        label: 'In Progress',
        value: active,
        icon: Icons.sync_alt_rounded,
        color: const Color(0xFF7DD3FC),
      ),
      _ProviderNotificationStat(
        label: 'Completed',
        value: completed,
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF86EFAC),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5CC7), Color(0xFF4F7BFF), Color(0xFF809BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2563EB),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order status overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track current workload and recent booking movement at a glance.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: stats
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: item == stats.last ? 0 : 10,
                      ),
                      child: _ProviderNotificationStatCard(stat: item),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ProviderNotificationStat {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _ProviderNotificationStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ProviderNotificationStatCard extends StatelessWidget {
  final _ProviderNotificationStat stat;

  const _ProviderNotificationStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            stat.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stat.value}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
