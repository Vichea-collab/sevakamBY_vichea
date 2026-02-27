import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/pagination.dart';
import '../../state/order_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/primary_button.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  static const String routeName = '/orders';
  final OrderItem? latestOrder;

  const OrdersPage({super.key, this.latestOrder});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

enum _FinderOrderTab { pending, inProgress, completed }

class _OrdersPageState extends State<OrdersPage> with WidgetsBindingObserver {
  _FinderOrderTab _activeTab = _FinderOrderTab.pending;
  String _filter = 'all';
  bool _isPaging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadOrders(forceNetwork: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOrders(forceNetwork: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OrderItem>>(
      valueListenable: OrderState.finderOrders,
      builder: (context, allOrders, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: OrderState.loading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<PaginationMeta>(
              valueListenable: OrderState.finderPagination,
              builder: (context, pagination, _) {
                final sourceOrders = _ordersForTab(_activeTab, allOrders);
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
                            subtitle: 'Track booking progress and history',
                            showBack: true,
                            onBack: () => Navigator.pushReplacementNamed(
                              context,
                              '/home',
                            ),
                            actions: [
                              PopupMenuButton<String>(
                                initialValue: _filter,
                                onSelected: (value) =>
                                    setState(() => _filter = value),
                                color: Colors.white,
                                elevation: 8,
                                offset: const Offset(0, 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: AppColors.divider,
                                  ),
                                ),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'all',
                                    child: Text('All'),
                                  ),
                                  PopupMenuItem(
                                    value: 'today',
                                    child: Text('Today'),
                                  ),
                                  PopupMenuItem(
                                    value: 'upcoming',
                                    child: Text('Upcoming'),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.divider,
                                    ),
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
                                    _onTabSelected(_FinderOrderTab.pending),
                              ),
                              const SizedBox(width: 8),
                              _TabChip(
                                label: 'In Progress',
                                active:
                                    _activeTab == _FinderOrderTab.inProgress,
                                onTap: () =>
                                    _onTabSelected(_FinderOrderTab.inProgress),
                              ),
                              const SizedBox(width: 8),
                              _TabChip(
                                label: 'History',
                                active: _activeTab == _FinderOrderTab.completed,
                                onTap: () =>
                                    _onTabSelected(_FinderOrderTab.completed),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: isLoading && allOrders.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      child: AppStatePanel.loading(
                                        title: 'Loading your orders',
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => _loadOrders(
                                      forceNetwork: true,
                                      page: _normalizedPage(pagination.page),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      child: visibleOrders.isEmpty
                                          ? ListView(
                                              key: ValueKey<String>(
                                                'empty_orders_${_activeTab.name}_$_filter',
                                              ),
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              children: [
                                                const SizedBox(height: 80),
                                                AppStatePanel.empty(
                                                  title: _emptyTitleForTab(
                                                    _activeTab,
                                                  ),
                                                  message: _emptyMessageForTab(
                                                    _activeTab,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : ListView.separated(
                                              key: ValueKey<String>(
                                                'orders_${visibleOrders.length}_${pagination.page}_${_activeTab.name}_$_filter',
                                              ),
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              itemCount: visibleOrders.length,
                                              separatorBuilder: (_, _) =>
                                                  const SizedBox(
                                                    height: AppSpacing.md,
                                                  ),
                                              itemBuilder: (context, index) {
                                                final order =
                                                    visibleOrders[index];
                                                return _OrderCard(
                                                  order: order,
                                                  onTap: () =>
                                                      _openOrder(order),
                                                  onMarkCompleted:
                                                      order.status ==
                                                          OrderStatus.started
                                                      ? () => _markCompleted(
                                                          order,
                                                        )
                                                      : null,
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                          ),
                          if (pagination.totalItems > pagination.limit) ...[
                            const SizedBox(height: 12),
                            PaginationBar(
                              currentPage: _normalizedPage(pagination.page),
                              totalPages: pagination.totalPages > 0
                                  ? pagination.totalPages
                                  : ((pagination.totalItems +
                                            pagination.limit -
                                            1) ~/
                                        pagination.limit),
                              loading: _isPaging,
                              onPageSelected: _goToPage,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  bottomNavigationBar: const AppBottomNav(
                    current: AppBottomTab.order,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _loadOrders({bool forceNetwork = false, int? page}) async {
    final targetPage = _normalizedPage(
      page ?? OrderState.finderPagination.value.page,
    );
    final statuses = _statusFiltersForTab(_activeTab);
    if (forceNetwork) {
      await OrderState.refreshFinderOrders(
        page: targetPage,
        statuses: statuses,
      );
    } else {
      await OrderState.refreshCurrentRole(page: targetPage);
    }
    final latest = widget.latestOrder;
    if (latest == null) return;
    if (targetPage != 1) return;
    final hasLatest = OrderState.finderOrders.value.any(
      (item) => item.id == latest.id,
    );
    if (!hasLatest) {
      OrderState.replaceFinderOrderLocal(latest);
    }
  }

  Future<void> _openOrder(OrderItem order) async {
    final updated = await Navigator.push<OrderItem>(
      context,
      slideFadeRoute(OrderDetailPage(order: order)),
    );
    if (!mounted || updated == null) return;
    await _replaceOrder(updated);
  }

  Future<void> _markCompleted(OrderItem order) async {
    try {
      await OrderState.updateFinderOrderStatus(
        orderId: order.id,
        status: OrderStatus.completed,
      );
      setState(() => _activeTab = _FinderOrderTab.completed);
      if (!mounted) return;
      AppToast.success(context, 'Order marked as completed.');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update order status.');
    }
  }

  Future<void> _goToPage(int page) async {
    final targetPage = _normalizedPage(page);
    if (_isPaging || targetPage == OrderState.finderPagination.value.page) {
      return;
    }
    setState(() => _isPaging = true);
    try {
      await _loadOrders(forceNetwork: true, page: targetPage);
    } finally {
      if (mounted) {
        setState(() => _isPaging = false);
      }
    }
  }

  void _onTabSelected(_FinderOrderTab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _isPaging = false;
    });
    unawaited(_loadOrders(forceNetwork: true, page: 1));
  }

  List<String> _statusFiltersForTab(_FinderOrderTab tab) {
    switch (tab) {
      case _FinderOrderTab.pending:
        return const <String>['booked'];
      case _FinderOrderTab.inProgress:
        return const <String>['on_the_way', 'started'];
      case _FinderOrderTab.completed:
        return const <String>['completed', 'cancelled', 'declined'];
    }
  }

  Future<void> _replaceOrder(OrderItem order) async {
    OrderItem? existing;
    for (final row in OrderState.finderOrders.value) {
      if (row.id == order.id) {
        existing = row;
        break;
      }
    }
    final changedStatus = existing != null && existing.status != order.status;
    if (changedStatus &&
        (order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.completed)) {
      try {
        await OrderState.updateFinderOrderStatus(
          orderId: order.id,
          status: order.status,
        );
      } catch (_) {
        if (mounted) {
          AppToast.error(context, 'Failed to sync order status.');
        }
      }
    } else {
      OrderState.replaceFinderOrderLocal(order);
    }
  }

  List<OrderItem> _ordersForTab(_FinderOrderTab tab, List<OrderItem> source) {
    switch (tab) {
      case _FinderOrderTab.pending:
        return source
            .where((order) => order.status == OrderStatus.booked)
            .toList();
      case _FinderOrderTab.inProgress:
        return source
            .where(
              (order) =>
                  order.status == OrderStatus.onTheWay ||
                  order.status == OrderStatus.started,
            )
            .toList();
      case _FinderOrderTab.completed:
        return source.where((order) {
          return order.status == OrderStatus.completed ||
              order.status == OrderStatus.cancelled ||
              order.status == OrderStatus.declined;
        }).toList();
    }
  }

  String _emptyTitleForTab(_FinderOrderTab tab) {
    switch (tab) {
      case _FinderOrderTab.pending:
        return 'No incoming orders';
      case _FinderOrderTab.inProgress:
        return 'No active orders';
      case _FinderOrderTab.completed:
        return 'No order history yet';
    }
  }

  String _emptyMessageForTab(_FinderOrderTab tab) {
    switch (tab) {
      case _FinderOrderTab.pending:
        return 'New bookings will appear here.';
      case _FinderOrderTab.inProgress:
        return 'Orders in progress will appear here.';
      case _FinderOrderTab.completed:
        return 'Completed, cancelled, and declined orders appear here.';
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

  int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
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
                      color: AppColors.textPrimary,
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
                Expanded(
                  child: PrimaryButton(
                    label: order.status == OrderStatus.completed
                        ? 'Rate service'
                        : 'View details',
                    icon: order.status == OrderStatus.completed
                        ? Icons.star_rate_rounded
                        : Icons.receipt_long_rounded,
                    isOutlined: true,
                    onPressed: onTap,
                  ),
                ),
                if (onMarkCompleted != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Mark as completed',
                      icon: Icons.task_alt_rounded,
                      tone: PrimaryButtonTone.success,
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

class _OrderStatusPill extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (status) {
      OrderStatus.booked => ('Incoming', const Color(0xFFD97706)),
      OrderStatus.onTheWay => ('On the way', AppColors.primary),
      OrderStatus.started => ('Started', const Color(0xFF7C6EF2)),
      OrderStatus.completed => ('Completed', AppColors.success),
      OrderStatus.cancelled => ('Cancelled', AppColors.danger),
      OrderStatus.declined => ('Declined', AppColors.danger),
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
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
