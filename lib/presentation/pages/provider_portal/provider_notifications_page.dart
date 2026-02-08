import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import 'provider_orders_page.dart';

class ProviderNotificationsPage extends StatelessWidget {
  static const String routeName = '/provider/notifications';

  const ProviderNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = MockData.providerOrders();
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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const AppTopBar(
              title: 'Notifications',
              showBack: false,
            ),
            const SizedBox(height: 12),
            _ProviderNotificationSummary(
              incoming: incoming,
              active: active,
              completed: completed,
            ),
            const SizedBox(height: 14),
            _NotificationTile(
              title: 'Order Incoming',
              description: '$incoming new order request waiting for your action.',
              timeLabel: '2 hrs ago',
              icon: Icons.inbox_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const ProviderOrdersPage(initialTab: ProviderOrderTab.incoming),
                ),
              ),
            ),
            _NotificationTile(
              title: 'Confirm Order',
              description: '$active order in progress. Keep updating your client.',
              timeLabel: '2 hrs ago',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFF7C6EF2),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const ProviderOrdersPage(initialTab: ProviderOrderTab.active),
                ),
              ),
            ),
            _NotificationTile(
              title: 'Order Completed',
              description: '$completed completed orders. Check recent feedback.',
              timeLabel: '2 hrs ago',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const ProviderOrdersPage(initialTab: ProviderOrderTab.completed),
                ),
              ),
            ),
            _NotificationTile(
              title: 'Order Cancelled',
              description: 'Your cancelled order details are available to review.',
              timeLabel: '3 hrs ago',
              icon: Icons.cancel_rounded,
              color: AppColors.danger,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const ProviderOrdersPage(initialTab: ProviderOrderTab.incoming),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.notification),
    );
  }
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
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
