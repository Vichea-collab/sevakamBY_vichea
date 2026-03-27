import 'dart:async';


import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/utils/listenable_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/time_utils.dart';
import '../../state/user_notification_state.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../chat/chat_list_page.dart';
import '../main_shell_page.dart';
import '../profile/help_support_page.dart';
import '../../widgets/app_bottom_nav.dart';

enum _NoticeFilter { all, orders, system, promos }

class NotificationsPage extends StatefulWidget {
  static const String routeName = '/notifications';

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with WidgetsBindingObserver {
  static const Duration _autoRefreshCooldown = Duration(seconds: 30);

  _NoticeFilter _filter = _NoticeFilter.all;
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
    final rs = context.rs;
    return ValueListenableBuilder<List<UserNotificationItem>>(
      valueListenable: UserNotificationState.notices,
      builder: (context, notices, _) {
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
                            padding: EdgeInsets.fromLTRB(
                              rs.space(AppSpacing.lg),
                              rs.space(AppSpacing.lg),
                              rs.space(AppSpacing.lg),
                              rs.space(AppSpacing.xl),
                            ),
                            children: [
                              AppTopBar(
                                title: 'Notifications',
                                showBack: true,
                                onBack: () => MainShellPage.activeTab.value =
                                    AppBottomTab.home,
                              ),
                              SizedBox(height: rs.space(16)),
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

                    final backendSystemUpdates = _buildSystemUpdates(notices);
                    final backendOrderUpdates = _buildBackendOrderUpdates(
                      notices,
                    );
                    final backendPromos = _buildPromoNotices(notices);

                    final updates = <_NotificationUpdate>[
                      ...backendOrderUpdates,
                      ...backendSystemUpdates,
                    ]
                        .map(
                          (item) => item.copyWith(
                            unread: !UserNotificationState.isRead(
                              _updateStateKey(item.key),
                            ),
                          ),
                        )
                        .where(
                          (item) => !UserNotificationState.isCleared(
                            _updateStateKey(item.key),
                          ),
                        )
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final promos = backendPromos
                        .map(
                          (item) => item.copyWith(
                            unread: !UserNotificationState.isRead(
                              _promoStateKey(item.id),
                            ),
                          ),
                        )
                        .where(
                          (item) => !UserNotificationState.isCleared(
                            _promoStateKey(item.id),
                          ),
                        )
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

                    final hasItems =
                        visibleUpdates.isNotEmpty || visiblePromos.isNotEmpty;
                    final primaryText = AppThemeTokens.textPrimary(context);
                    final surface = AppThemeTokens.surface(context);
                    final outline = AppThemeTokens.outline(context);

                    final contentKey = ValueKey<String>(
                      'notifications_${_filter.name}_'
                      'updates:${visibleUpdates.map((item) => item.key).join('|')}_'
                      'promos:${visiblePromos.map((item) => item.id).join('|')}',
                    );

                    final Widget content = hasItems
                        ? Column(
                            key: contentKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (visibleUpdates.isNotEmpty) ...[
                                Text(
                                  'Recent Updates',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: primaryText),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: outline),
                                  ),
                                  child: Column(
                                    children: List.generate(
                                      visibleUpdates.length,
                                      (index) {
                                        final item = visibleUpdates[index];
                                        return _UpdateTile(
                                          item: item,
                                          isLast:
                                              index ==
                                              visibleUpdates.length - 1,
                                          onTap: () => _handleUpdateTap(item),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (visiblePromos.isNotEmpty) ...[
                                Text(
                                  'Promotions',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: primaryText),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: outline),
                                  ),
                                  child: Column(
                                    children: List.generate(
                                      visiblePromos.length,
                                      (index) {
                                        final item = visiblePromos[index];
                                        return _PromoTile(
                                          item: item,
                                          isLast:
                                              index == visiblePromos.length - 1,
                                          onTap: () =>
                                              _markPromoAsRead(item.id),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const AppStatePanel.empty(
                            key: ValueKey<String>('notifications_empty'),
                            title: 'No notifications yet',
                            message:
                                'Order updates and promos will appear here.',
                          );

                    return Scaffold(
                      body: SafeArea(
                        child: RefreshIndicator(
                          onRefresh: _refreshFeed,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              rs.space(AppSpacing.lg),
                              rs.space(AppSpacing.lg),
                              rs.space(AppSpacing.lg),
                              rs.space(AppSpacing.xl),
                            ),
                            children: [
                              AppTopBar(
                                title: 'Notifications',
                                showBack: true,
                                onBack: () => MainShellPage.activeTab.value =
                                    AppBottomTab.home,
                                actions: [
                                  IconButton(
                                    onPressed: _openMessenger,
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                    ),
                                    tooltip: 'Messenger',
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'More actions',
                                    onSelected: (value) {
                                      if (value == 'read') {
                                        _markAllAsRead(updates, promos);
                                        return;
                                      }
                                      if (value == 'clear') {
                                        _confirmClearAllNotifications(context);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem<String>(
                                        value: 'read',
                                        child: Text('Mark all as read'),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'clear',
                                        child: Text('Clear order updates'),
                                      ),
                                    ],
                                    icon: const Icon(Icons.more_horiz_rounded),
                                  ),
                                ],
                              ),
                              rs.gapH(12),
                              _HeroCard(
                                unreadCount: unreadCount,
                                totalCount: totalCount,
                              ),
                              rs.gapH(14),
                              SizedBox(
                                height: rs.dimension(40),
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _FilterChip(
                                      label: 'All',
                                      selected: _filter == _NoticeFilter.all,
                                      onTap: () => setState(
                                        () => _filter = _NoticeFilter.all,
                                      ),
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
                              rs.gapH(16),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: content,
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
  }

  void _markAllAsRead(
    List<_NotificationUpdate> updates,
    List<_PromoNotice> promos,
  ) {
    final keys = <String>[
      ...updates.map((e) => _updateStateKey(e.key)),
      ...promos.map((e) => _promoStateKey(e.id)),
    ];
    unawaited(UserNotificationState.markReadMany(keys));
  }

  void _clearAllNotifications() {
    final orderUpdateKeys = _buildBackendOrderUpdates(
      UserNotificationState.notices.value,
    ).map((item) => _updateStateKey(item.key)).toList(growable: false);
    unawaited(UserNotificationState.clearMany(orderUpdateKeys));
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
    unawaited(UserNotificationState.markRead(_updateStateKey(key)));
  }

  void _handleUpdateTap(_NotificationUpdate item) {
    _markUpdateAsRead(item.key);
    switch (item.source) {
      case 'chat_message':
        unawaited(UserNotificationState.clear(_updateStateKey(item.key)));
        Navigator.pushNamed(context, ChatListPage.routeName);
        return;
      case 'support_message':
        Navigator.pushNamed(context, HelpSupportPage.routeName);
        return;
      default:
        MainShellPage.activeTab.value = AppBottomTab.order;
        return;
    }
  }

  void _markPromoAsRead(String id) {
    unawaited(UserNotificationState.markRead(_promoStateKey(id)));
  }

  String _updateStateKey(String key) {
    return 'finder:update:${key.trim()}';
  }

  String _promoStateKey(String id) {
    return 'finder:promo:${id.trim()}';
  }

  void _openMessenger() {
    Navigator.pushNamed(context, ChatListPage.routeName);
  }

  // Delegated to shared waitUntilNotLoading in listenable_utils.dart

  Future<void> _refreshInboxNoticesAndWait() async {
    await UserNotificationState.refresh();
    await waitUntilNotLoading(UserNotificationState.loading);
  }

  Future<void> _loadScreen({bool forceNetwork = false}) async {
    if (_screenRefreshInFlight) return;
    final hasCachedData = UserNotificationState.notices.value.isNotEmpty;
    final hasFreshCache =
        !forceNetwork &&
        hasCachedData &&
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
      await _refreshInboxNoticesAndWait();
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

  List<_NotificationUpdate> _buildBackendOrderUpdates(
    List<UserNotificationItem> notices,
  ) {
    final indexed = <String, UserNotificationItem>{};
    final sorted =
        notices
            .where(
              (item) =>
                  item.source == 'order_status' &&
                  item.orderId.trim().isNotEmpty &&
                  item.orderStatus.trim().isNotEmpty,
            )
            .toList()
          ..sort((a, b) {
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
    for (final item in sorted) {
      indexed.putIfAbsent('${item.orderId}:${item.orderStatus}', () => item);
    }

    return indexed.values.map((item) {
      final (icon, color) = switch (item.orderStatus) {
        'booked' => (Icons.fact_check_outlined, const Color(0xFFF59E0B)),
        'on_the_way' => (Icons.verified_rounded, AppColors.primary),
        'started' => (Icons.handyman_rounded, const Color(0xFF7C6EF2)),
        'completed' => (
          Icons.check_circle_outline_rounded,
          AppColors.success,
        ),
        'cancelled' => (Icons.cancel_outlined, AppColors.danger),
        'declined' => (Icons.highlight_off_rounded, AppColors.danger),
        _ => (Icons.notifications_none_rounded, AppColors.primary),
      };

      return _NotificationUpdate(
        key: '${item.orderId}:${item.orderStatus}',
        title: item.title,
        description: item.message,
        timeLabel: timeAgo(item.createdAt ?? DateTime.now()),
        createdAt: item.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        icon: icon,
        iconColor: color,
        kind: _NoticeFilter.orders,
        source: item.source,
        unread: false,
      );
    }).toList(growable: false);
  }

  List<_NotificationUpdate> _buildSystemUpdates(
    List<UserNotificationItem> notices,
  ) {
    final systems =
        notices
            .where((item) => !item.isPromo && item.source != 'order_status')
            .toList()
          ..sort((a, b) {
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
    return systems
        .map((item) {
          final (icon, color) = switch (item.source) {
            'chat_message' => (
              Icons.chat_bubble_outline_rounded,
              AppColors.primary,
            ),
            'support_message' => (
              Icons.support_agent_rounded,
              const Color(0xFFF59E0B),
            ),
            _ => (Icons.campaign_outlined, const Color(0xFF4B5563)),
          };
          return _NotificationUpdate(
            key: 'system:${item.id}',
            title: item.title,
            description: item.message,
            timeLabel: timeAgo(item.createdAt ?? DateTime.now()),
            createdAt: item.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            icon: icon,
            iconColor: color,
            kind: _NoticeFilter.system,
            source: item.source,
            unread: false,
          );
        })
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
          return _PromoNotice(
            id: item.id,
            title: item.title,
            description: item.message,
            trailingLabel: trailingLabel,
            trailingColor: trailingColor,
            dateRange: dateRange,
            unread: false,
          );
        })
        .toList(growable: false);
  }

  // Delegated to shared timeAgo() in time_utils.dart
}

class _HeroCard extends StatelessWidget {
  final int unreadCount;
  final int totalCount;

  const _HeroCard({required this.unreadCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final isDark = AppThemeTokens.isDark(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: rs.space(16),
        vertical: rs.space(16),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF172554), Color(0xFF1D4ED8)]
              : const [AppColors.splashStart, AppColors.splashEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(rs.radius(18)),
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
                rs.gapH(4),
                Text(
                  unreadCount == 0
                      ? '$totalCount notification${totalCount > 1 ? 's' : ''} reviewed'
                      : '$unreadCount unread notification${unreadCount > 1 ? 's' : ''} out of $totalCount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.35,
                  ),
                ),
                rs.gapH(10),
                Wrap(
                  spacing: rs.space(8),
                  runSpacing: rs.space(8),
                  children: [
                    _SummaryPill(label: 'Unread', value: '$unreadCount'),
                    _SummaryPill(label: 'Total', value: '$totalCount'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: rs.dimension(46),
            height: rs.dimension(46),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: rs.icon(22),
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
    final rs = context.rs;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: rs.space(10),
        vertical: rs.space(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(rs.radius(100)),
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
    final rs = context.rs;
    final surface = AppThemeTokens.surface(context);
    final outline = AppThemeTokens.outline(context);
    final primaryText = AppThemeTokens.textPrimary(context);
    return Padding(
      padding: EdgeInsets.only(right: rs.space(8)),
      child: PressableScale(
        onTap: onTap,
        child: InkWell(
          borderRadius: BorderRadius.circular(rs.radius(100)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: rs.space(14),
              vertical: rs.space(8),
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : surface,
              borderRadius: BorderRadius.circular(rs.radius(100)),
              border: Border.all(
                color: selected ? AppColors.primary : outline,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : primaryText,
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
    final rs = context.rs;
    final outline = AppThemeTokens.outline(context);
    final dotColor = item.unread ? AppColors.primary : outline;
    final primaryText = AppThemeTokens.textPrimary(context);
    final secondaryText = AppThemeTokens.textSecondary(context);
    final surface = AppThemeTokens.surface(context);
    final mutedSurface = AppThemeTokens.mutedSurface(context);
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: rs.space(12),
            vertical: rs.space(14),
          ),
          decoration: BoxDecoration(
            color: item.unread ? mutedSurface : surface,
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: outline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: rs.dimension(44),
                width: rs.dimension(44),
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(rs.radius(8)),
                ),
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: rs.icon(22),
                ),
              ),
              rs.gapW(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    rs.gapH(4),
                    Row(
                      children: [
                        Container(
                          height: rs.dimension(8),
                          width: rs.dimension(8),
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        rs.gapW(8),
                        Icon(
                          Icons.access_time,
                          size: rs.icon(14),
                          color: secondaryText,
                        ),
                        rs.gapW(4),
                        Text(
                          item.timeLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: secondaryText),
                        ),
                      ],
                    ),
                    rs.gapH(8),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
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
    final rs = context.rs;
    final outline = AppThemeTokens.outline(context);
    final primaryText = AppThemeTokens.textPrimary(context);
    final secondaryText = AppThemeTokens.textSecondary(context);
    final surface = AppThemeTokens.surface(context);
    final mutedSurface = AppThemeTokens.mutedSurface(context);
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: rs.space(12),
            vertical: rs.space(14),
          ),
          decoration: BoxDecoration(
            color: item.unread ? mutedSurface : surface,
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: outline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: rs.space(12),
                      vertical: rs.space(4),
                    ),
                    decoration: BoxDecoration(
                      color: item.trailingColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(rs.radius(100)),
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
              rs.gapH(8),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: secondaryText,
                  height: 1.35,
                ),
              ),
              if (item.dateRange != null) ...[
                rs.gapH(6),
                Text(
                  item.dateRange!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
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
  final DateTime createdAt;
  final IconData icon;
  final Color iconColor;
  final _NoticeFilter kind;
  final String source;
  final bool unread;

  const _NotificationUpdate({
    required this.key,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.createdAt,
    required this.icon,
    required this.iconColor,
    required this.kind,
    required this.source,
    required this.unread,
  });

  _NotificationUpdate copyWith({bool? unread}) {
    return _NotificationUpdate(
      key: key,
      title: title,
      description: description,
      timeLabel: timeLabel,
      createdAt: createdAt,
      icon: icon,
      iconColor: iconColor,
      kind: kind,
      source: source,
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
