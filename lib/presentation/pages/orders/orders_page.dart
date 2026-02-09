import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';
import 'order_detail_page.dart';
import '../booking/booking_address_page.dart';

class OrdersPage extends StatefulWidget {
  static const String routeName = '/orders';
  final OrderItem? latestOrder;

  const OrdersPage({super.key, this.latestOrder});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

enum _FinderOrderTab { pending, inProgress, completed }

class _OrdersPageState extends State<OrdersPage> {
  late List<OrderItem> _pending;
  late List<OrderItem> _inProgress;
  late List<OrderItem> _completed;
  _FinderOrderTab _activeTab = _FinderOrderTab.pending;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _pending = <OrderItem>[];
    _inProgress = <OrderItem>[];
    _completed = <OrderItem>[];

    final seeded = <OrderItem>[...MockData.orders];
    if (widget.latestOrder != null) {
      seeded.insert(0, widget.latestOrder!);
    }
    for (final order in seeded) {
      _insertOrder(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceOrders = switch (_activeTab) {
      _FinderOrderTab.pending => _pending,
      _FinderOrderTab.inProgress => _inProgress,
      _FinderOrderTab.completed => _completed,
    };
    final visibleOrders = sourceOrders
        .where((order) => _matchesFilter(order))
        .toList();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AppTopBar(
                title: 'Orders',
                showBack: false,
                actions: [
                  PopupMenuButton<String>(
                    initialValue: _filter,
                    onSelected: (value) => setState(() => _filter = value),
                    color: Colors.white,
                    elevation: 8,
                    offset: const Offset(0, 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'all', child: Text('All')),
                      PopupMenuItem(value: 'today', child: Text('Today')),
                      PopupMenuItem(value: 'upcoming', child: Text('Upcoming')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Text(_filterLabel(_filter)),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TabChip(
                    label: 'Incoming',
                    active: _activeTab == _FinderOrderTab.pending,
                    onTap: () =>
                        setState(() => _activeTab = _FinderOrderTab.pending),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'In Progress',
                    active: _activeTab == _FinderOrderTab.inProgress,
                    onTap: () => setState(
                      () => _activeTab = _FinderOrderTab.inProgress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Completed',
                    active: _activeTab == _FinderOrderTab.completed,
                    onTap: () => setState(
                      () => _activeTab = _FinderOrderTab.completed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: visibleOrders.isEmpty
                    ? _EmptyOrders(activeTab: _activeTab)
                    : ListView.separated(
                        itemCount: visibleOrders.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final order = visibleOrders[index];
                          return _OrderCard(
                            order: order,
                            onTap: () => _openOrder(order),
                            onMarkCompleted: order.status == OrderStatus.started
                                ? () => _markCompleted(order)
                                : null,
                          );
                        },
                      ),
              ),
              if (_activeTab == _FinderOrderTab.inProgress &&
                  visibleOrders.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: PrimaryButton(
                    label: 'Make another booking',
                    onPressed: () => Navigator.push(
                      context,
                      slideFadeRoute(
                        BookingAddressPage(
                          draft: MockData.defaultBookingDraft(
                            provider: MockData.cleanerProviders.first,
                            serviceName: 'Indoor Cleaning',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.order),
    );
  }

  Future<void> _openOrder(OrderItem order) async {
    final updated = await Navigator.push<OrderItem>(
      context,
      slideFadeRoute(OrderDetailPage(order: order)),
    );
    if (!mounted || updated == null) return;
    _replaceOrder(updated);
  }

  void _markCompleted(OrderItem order) {
    final completedOrder = order.copyWith(status: OrderStatus.completed);
    setState(() {
      _pending.removeWhere((item) => item.id == order.id);
      _inProgress.removeWhere((item) => item.id == order.id);
      _completed.removeWhere((item) => item.id == order.id);
      _insertOrder(completedOrder, atStart: true);
      _activeTab = _FinderOrderTab.completed;
    });
  }

  void _replaceOrder(OrderItem order) {
    setState(() {
      _pending.removeWhere((item) => item.id == order.id);
      _inProgress.removeWhere((item) => item.id == order.id);
      _completed.removeWhere((item) => item.id == order.id);
      _insertOrder(order, atStart: true);
    });
  }

  void _insertOrder(OrderItem order, {bool atStart = false}) {
    final target = switch (order.status) {
      OrderStatus.booked || OrderStatus.cancelled => _pending,
      OrderStatus.onTheWay || OrderStatus.started => _inProgress,
      OrderStatus.completed => _completed,
    };
    if (atStart) {
      target.insert(0, order);
    } else {
      target.add(order);
    }
  }

  bool _matchesFilter(OrderItem order) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(
      order.scheduledAt.year,
      order.scheduledAt.month,
      order.scheduledAt.day,
    );

    switch (_filter) {
      case 'today':
        return orderDay == today;
      case 'upcoming':
        return orderDay.isAfter(today);
      default:
        return true;
    }
  }

  String _filterLabel(String value) {
    switch (value) {
      case 'today':
        return 'Today';
      case 'upcoming':
        return 'Upcoming';
      default:
        return 'All';
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEAF1FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: active ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onTap;
  final VoidCallback? onMarkCompleted;

  const _OrderCard({
    required this.order,
    required this.onTap,
    this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.serviceName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                      ),
                  ),
                ),
                _OrderStatusPill(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _MetaText(
                  icon: Icons.calendar_today_outlined,
                  text: _dateLabel(order.scheduledAt),
                ),
                _MetaText(icon: Icons.schedule, text: order.timeRange),
                _MetaText(
                  icon: Icons.person_outline,
                  text: order.provider.name,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onTap,
                  child: Text(order.status == OrderStatus.completed
                      ? 'Rate service'
                      : 'View details'),
                ),
                if (onMarkCompleted != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Mark as completed',
                      onPressed: onMarkCompleted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final _FinderOrderTab activeTab;

  const _EmptyOrders({required this.activeTab});

  @override
  Widget build(BuildContext context) {
    final label = switch (activeTab) {
      _FinderOrderTab.pending => 'No incoming orders.',
      _FinderOrderTab.inProgress => 'No orders in progress.',
      _FinderOrderTab.completed => 'No completed orders yet.',
    };
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _OrderStatusPill extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      OrderStatus.booked => (
          'Incoming',
          const Color(0xFFFFF4E5),
          const Color(0xFFD97706),
        ),
      OrderStatus.onTheWay => (
          'On the way',
          const Color(0xFFEAF1FF),
          AppColors.primary,
        ),
      OrderStatus.started => (
          'Started',
          const Color(0xFFE9FDF4),
          AppColors.success,
        ),
      OrderStatus.completed => (
          'Completed',
          const Color(0xFFE9FDF4),
          AppColors.success,
        ),
      OrderStatus.cancelled => (
          'Cancelled',
          const Color(0xFFFFEFEF),
          AppColors.danger,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
