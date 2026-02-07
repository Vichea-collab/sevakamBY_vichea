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

class _OrdersPageState extends State<OrdersPage> {
  late List<OrderItem> _inProgress;
  late List<OrderItem> _completed;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _inProgress = MockData.inProgressOrders(widget.latestOrder);
    _completed = MockData.completedOrders();
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _showCompleted ? _completed : _inProgress;
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
                      child: const Row(
                        children: [
                          Text('Filter'),
                          SizedBox(width: 4),
                          Icon(Icons.expand_more, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TabButton(
                    label: 'In Progress',
                    active: !_showCompleted,
                    onTap: () => setState(() => _showCompleted = false),
                  ),
                  const SizedBox(width: 8),
                  _TabButton(
                    label: 'Completed',
                    active: _showCompleted,
                    onTap: () => setState(() => _showCompleted = true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: visibleOrders.isEmpty
                    ? _EmptyOrders(isCompleted: _showCompleted)
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
              if (!_showCompleted && _inProgress.isEmpty)
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
      _inProgress.removeWhere((item) => item.id == order.id);
      _completed.insert(0, completedOrder);
      _showCompleted = true;
    });
  }

  void _replaceOrder(OrderItem order) {
    setState(() {
      _inProgress.removeWhere((item) => item.id == order.id);
      _completed.removeWhere((item) => item.id == order.id);
      if (order.status == OrderStatus.completed) {
        _completed.insert(0, order);
      } else if (order.status != OrderStatus.cancelled) {
        _inProgress.insert(0, order);
      }
    });
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.primary : AppColors.divider,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                Text(
                  _statusLabel(order.status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
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

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.booked:
        return 'Booked';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.started:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
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
  final bool isCompleted;

  const _EmptyOrders({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isCompleted ? 'No completed orders yet.' : 'No active orders.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
