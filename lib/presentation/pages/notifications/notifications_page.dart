import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/mock/mock_data.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/notification_messenger_sheet.dart';
import '../../widgets/pressable_scale.dart';

enum _NoticeFilter { all, orders, system, promos }

class NotificationsPage extends StatefulWidget {
  static const String routeName = '/notifications';

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NoticeFilter _filter = _NoticeFilter.all;

  late List<_NotificationUpdate> _updates;
  late List<_PromoNotice> _promos;

  @override
  void initState() {
    super.initState();
    _updates = [
      const _NotificationUpdate(
        title: 'Order Accepted',
        description: 'We have accepted your order. Click to view details.',
        timeLabel: '2 hrs ago',
        icon: Icons.fact_check_outlined,
        iconColor: Color(0xFFF59E0B),
        kind: _NoticeFilter.orders,
        unread: true,
      ),
      const _NotificationUpdate(
        title: 'Confirm Order',
        description: 'We have added items in your order. Please check and confirm.',
        timeLabel: '2 hrs ago',
        icon: Icons.verified_user_outlined,
        iconColor: Color(0xFF7C6EF2),
        kind: _NoticeFilter.orders,
        unread: true,
      ),
      const _NotificationUpdate(
        title: 'Announcement',
        description: 'Our service will be down tomorrow for planned maintenance.',
        timeLabel: '2 hrs ago',
        icon: Icons.campaign_outlined,
        iconColor: Color(0xFF4B5563),
        kind: _NoticeFilter.system,
        unread: false,
      ),
    ];

    _promos = [
      const _PromoNotice(
        title: 'EID FITR 2023',
        description:
            'Get 2% discount on all orders on this Eid Al Fitr (Max discount = USD 100)',
        trailingLabel: 'Expired',
        trailingColor: AppColors.danger,
        unread: false,
      ),
      const _PromoNotice(
        title: 'EID AZHA 2023',
        description: 'Get 5% discount on all orders on this Eid Al Azha.',
        trailingLabel: 'Active',
        trailingColor: AppColors.success,
        dateRange: '15 Jan - 30 Feb',
        unread: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visibleUpdates = _updates
        .where(
          (item) =>
              _filter == _NoticeFilter.all ||
              _filter == _NoticeFilter.orders && item.kind == _NoticeFilter.orders ||
              _filter == _NoticeFilter.system && item.kind == _NoticeFilter.system,
        )
        .toList();

    final visiblePromos = _promos
        .where((_) => _filter == _NoticeFilter.all || _filter == _NoticeFilter.promos)
        .toList();

    final unreadCount = _updates.where((item) => item.unread).length +
        _promos.where((item) => item.unread).length;

    return Scaffold(
      body: SafeArea(
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
                  onPressed: _markAllAsRead,
                  child: const Text('Mark all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _HeroCard(unreadCount: unreadCount),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == _NoticeFilter.all,
                    onTap: () => setState(() => _filter = _NoticeFilter.all),
                  ),
                  _FilterChip(
                    label: 'Orders',
                    selected: _filter == _NoticeFilter.orders,
                    onTap: () => setState(() => _filter = _NoticeFilter.orders),
                  ),
                  _FilterChip(
                    label: 'System',
                    selected: _filter == _NoticeFilter.system,
                    onTap: () => setState(() => _filter = _NoticeFilter.system),
                  ),
                  _FilterChip(
                    label: 'Promotions',
                    selected: _filter == _NoticeFilter.promos,
                    onTap: () => setState(() => _filter = _NoticeFilter.promos),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (visibleUpdates.isNotEmpty) ...[
              Text(
                'Recent Updates',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: List.generate(visibleUpdates.length, (index) {
                    final item = visibleUpdates[index];
                    return _UpdateTile(
                      item: item,
                      isLast: index == visibleUpdates.length - 1,
                      onTap: () => _markUpdateAsRead(item.title),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (visiblePromos.isNotEmpty) ...[
              Text(
                'Promotions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: List.generate(visiblePromos.length, (index) {
                    final item = visiblePromos[index];
                    return _PromoTile(
                      item: item,
                      isLast: index == visiblePromos.length - 1,
                      onTap: () => _markPromoAsRead(item.title),
                    );
                  }),
                ),
              ),
            ],
            if (visibleUpdates.isEmpty && visiblePromos.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.notification),
    );
  }

  void _markAllAsRead() {
    setState(() {
      _updates = _updates.map((item) => item.copyWith(unread: false)).toList();
      _promos = _promos.map((item) => item.copyWith(unread: false)).toList();
    });
  }

  void _markUpdateAsRead(String title) {
    setState(() {
      _updates = _updates
          .map((item) => item.title == title ? item.copyWith(unread: false) : item)
          .toList();
    });
  }

  void _markPromoAsRead(String title) {
    setState(() {
      _promos = _promos
          .map((item) => item.title == title ? item.copyWith(unread: false) : item)
          .toList();
    });
  }

  void _openMessenger() {
    showNotificationMessengerSheet(
      context,
      title: 'Finder Messenger',
      subtitle: 'Recent chats with providers',
      threads: MockData.chats,
      accentColor: AppColors.primary,
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int unreadCount;

  const _HeroCard({required this.unreadCount});

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
                  'Finder Noti',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount == 0
                      ? 'All caught up'
                      : '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '$unreadCount',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        Text(item.timeLabel, style: Theme.of(context).textTheme.bodyMedium),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
  final String title;
  final String description;
  final String timeLabel;
  final IconData icon;
  final Color iconColor;
  final _NoticeFilter kind;
  final bool unread;

  const _NotificationUpdate({
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
  final String title;
  final String description;
  final String trailingLabel;
  final Color trailingColor;
  final String? dateRange;
  final bool unread;

  const _PromoNotice({
    required this.title,
    required this.description,
    required this.trailingLabel,
    required this.trailingColor,
    this.dateRange,
    required this.unread,
  });

  _PromoNotice copyWith({bool? unread}) {
    return _PromoNotice(
      title: title,
      description: description,
      trailingLabel: trailingLabel,
      trailingColor: trailingColor,
      dateRange: dateRange,
      unread: unread ?? this.unread,
    );
  }
}
