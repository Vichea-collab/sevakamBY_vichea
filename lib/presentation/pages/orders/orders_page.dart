import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/pagination.dart';
import '../../state/order_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/primary_button.dart';
import '../main_shell_page.dart';
import '../../widgets/app_bottom_nav.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  static const String routeName = '/orders';
  static final ValueNotifier<OrderItem?> queuedLatestOrder = ValueNotifier(
    null,
  );
  final OrderItem? latestOrder;

  const OrdersPage({super.key, this.latestOrder});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

enum _FinderOrderTab { pending, inProgress, completed }

class _OrdersPageState extends State<OrdersPage> with WidgetsBindingObserver {
  _FinderOrderTab _activeTab = _FinderOrderTab.pending;
  bool _isPaging = false;
  bool _historyTabLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MainShellPage.activeTab.addListener(_handleActiveTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadOrders(forceNetwork: true, page: 1));
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
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadOrders(forceNetwork: true));
    }
  }

  void _handleActiveTabChanged() {
    if (!mounted || MainShellPage.activeTab.value != AppBottomTab.order) {
      return;
    }
    unawaited(
      _loadOrders(
        forceNetwork: true,
        page: _normalizedPage(OrderState.finderPagination.value.page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
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
                final visibleOrders = sourceOrders;
                final showHistoryLoading =
                    _activeTab == _FinderOrderTab.completed &&
                    _historyTabLoading;
                return Scaffold(
                  body: PopScope(
                    canPop: Navigator.canPop(context),
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) return;
                      MainShellPage.activeTab.value = AppBottomTab.home;
                    },
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(rs.space(AppSpacing.lg)),
                        child: Column(
                          children: [
                            AppTopBar(
                              title: 'My Bookings',
                              showBack: true,
                              onBack: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  MainShellPage.activeTab.value =
                                      AppBottomTab.home;
                                }
                              },
                            ),
                            SizedBox(height: rs.space(12)),
                            Row(
                              children: [
                                _TabChip(
                                  label: 'Booked',
                                  active: _activeTab == _FinderOrderTab.pending,
                                  onTap: () =>
                                      _onTabSelected(_FinderOrderTab.pending),
                                ),
                                SizedBox(width: rs.space(8)),
                                _TabChip(
                                  label: 'In Progress',
                                  active:
                                      _activeTab == _FinderOrderTab.inProgress,
                                  onTap: () => _onTabSelected(
                                    _FinderOrderTab.inProgress,
                                  ),
                                ),
                                SizedBox(width: rs.space(8)),
                                _TabChip(
                                  label: 'History',
                                  active:
                                      _activeTab == _FinderOrderTab.completed,
                                  onTap: () =>
                                      _onTabSelected(_FinderOrderTab.completed),
                                ),
                              ],
                            ),
                            SizedBox(height: rs.space(14)),
                            Expanded(
                              child: showHistoryLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                        ),
                                        child: AppStatePanel.loading(
                                          title: 'Loading history',
                                        ),
                                      ),
                                    )
                                  : isLoading && allOrders.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                        ),
                                        child: AppStatePanel.loading(
                                          title: 'Loading bookings',
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
                                                  'empty_orders_${_activeTab.name}',
                                                ),
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                children: [
                                                  SizedBox(
                                                    height: rs.dimension(80),
                                                  ),
                                                  AppStatePanel.empty(
                                                    title: _emptyTitleForTab(
                                                      _activeTab,
                                                    ),
                                                    message:
                                                        _emptyMessageForTab(
                                                          _activeTab,
                                                        ),
                                                  ),
                                                ],
                                              )
                                            : ListView.separated(
                                                key: ValueKey<String>(
                                                  'orders_${visibleOrders.length}_${pagination.page}_${_activeTab.name}',
                                                ),
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                itemCount: visibleOrders.length,
                                                cacheExtent: 1000,
                                                separatorBuilder: (_, _) =>
                                                    SizedBox(
                                                      height: rs.space(
                                                        AppSpacing.md,
                                                      ),
                                                    ),
                                                itemBuilder: (context, index) {
                                                  final order =
                                                      visibleOrders[index];
                                                  return _OrderCard(
                                                    order: order,
                                                    onTap: () =>
                                                        _openOrder(order),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                            ),
                            if (pagination.totalItems > pagination.limit) ...[
                              SizedBox(height: rs.space(12)),
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
    final shouldShowHistoryLoading = _activeTab == _FinderOrderTab.completed;
    if (shouldShowHistoryLoading && mounted) {
      setState(() => _historyTabLoading = true);
    }
    try {
      if (forceNetwork) {
        await OrderState.refreshFinderOrders(
          page: targetPage,
          statuses: statuses,
        );
      } else {
        await OrderState.refreshCurrentRole(page: targetPage);
      }
      final latest = widget.latestOrder ?? OrdersPage.queuedLatestOrder.value;
      if (latest == null) return;
      if (targetPage != 1) return;
      final hasLatest = OrderState.finderOrders.value.any(
        (item) => item.id == latest.id,
      );
      if (!hasLatest) {
        OrderState.replaceFinderOrderLocal(latest);
      }
      OrdersPage.queuedLatestOrder.value = null;
    } finally {
      if (shouldShowHistoryLoading && mounted) {
        setState(() => _historyTabLoading = false);
      }
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
        return 'No bookings';
      case _FinderOrderTab.inProgress:
        return 'No active services';
      case _FinderOrderTab.completed:
        return 'No history yet';
    }
  }

  String _emptyMessageForTab(_FinderOrderTab tab) {
    switch (tab) {
      case _FinderOrderTab.pending:
        return 'Your new service requests will appear here.';
      case _FinderOrderTab.inProgress:
        return 'Confirmed services in progress appear here.';
      case _FinderOrderTab.completed:
        return 'Completed and cancelled bookings appear here.';
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
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(rs.radius(12)),
        onTap: onTap,
        child: Container(
          height: rs.dimension(40),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : const Color(0xFFEAF1FF))
                : theme.cardColor,
            borderRadius: BorderRadius.circular(rs.radius(12)),
            border: Border.all(
              color: active ? AppColors.primary : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: active
                  ? AppColors.primaryLight
                  : theme.textTheme.bodyMedium?.color,
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

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(rs.radius(14)),
      child: Container(
        padding: rs.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(rs.radius(14)),
          border: Border.all(color: theme.dividerColor),
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
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _OrderStatusPill(status: order.status),
              ],
            ),
            rs.gapH(8),
            Wrap(
              spacing: rs.space(12),
              runSpacing: rs.space(6),
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
            rs.gapH(10),
            PrimaryButton(
              label: order.status == OrderStatus.completed
                  ? 'Rate service'
                  : 'View details',
              icon: order.status == OrderStatus.completed
                  ? Icons.star_rate_rounded
                  : Icons.receipt_long_rounded,
              isOutlined: true,
              onPressed: onTap,
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
    final rs = context.rs;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: rs.icon(14),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        rs.gapW(4),
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
    final rs = context.rs;
    final (label, bg) = switch (status) {
      OrderStatus.booked => ('Booked', const Color(0xFFD97706)),
      OrderStatus.onTheWay => ('Confirmed', AppColors.primary),
      OrderStatus.started => ('Started', const Color(0xFF7C6EF2)),
      OrderStatus.completed => ('Completed', AppColors.success),
      OrderStatus.cancelled => ('Cancelled', AppColors.danger),
      OrderStatus.declined => ('Declined', AppColors.danger),
    };

    return Container(
      padding: rs.symmetric(horizontal: 8, vertical: 4),
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
