import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/order_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/primary_button.dart';
import 'provider_order_detail_page.dart';

enum ProviderOrderTab { incoming, active, completed }

class ProviderOrdersPage extends StatefulWidget {
  static const String routeName = '/provider/orders';
  final ProviderOrderTab initialTab;

  const ProviderOrdersPage({
    super.key,
    this.initialTab = ProviderOrderTab.incoming,
  });

  @override
  State<ProviderOrdersPage> createState() => _ProviderOrdersPageState();
}

class _ProviderOrdersPageState extends State<ProviderOrdersPage>
    with WidgetsBindingObserver {
  late ProviderOrderTab _tab;
  bool _isPaging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tab = widget.initialTab;
    _loadOrders(forceNetwork: true);
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
    return ValueListenableBuilder<List<ProviderOrderItem>>(
      valueListenable: OrderState.providerOrders,
      builder: (context, allOrders, _) {
        return ValueListenableBuilder<PaginationMeta>(
          valueListenable: OrderState.providerPagination,
          builder: (context, pagination, _) {
            final visible = allOrders.where((item) {
              switch (_tab) {
                case ProviderOrderTab.incoming:
                  return item.state == ProviderOrderState.incoming;
                case ProviderOrderTab.active:
                  return item.state == ProviderOrderState.onTheWay ||
                      item.state == ProviderOrderState.started;
                case ProviderOrderTab.completed:
                  return item.state == ProviderOrderState.completed ||
                      item.state == ProviderOrderState.declined;
              }
            }).toList();

            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const AppTopBar(
                        title: 'Provider Orders',
                        showBack: false,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _TabChip(
                            label: 'Incoming',
                            active: _tab == ProviderOrderTab.incoming,
                            onTap: () => setState(
                              () => _tab = ProviderOrderTab.incoming,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TabChip(
                            label: 'In Progress',
                            active: _tab == ProviderOrderTab.active,
                            onTap: () =>
                                setState(() => _tab = ProviderOrderTab.active),
                          ),
                          const SizedBox(width: 8),
                          _TabChip(
                            label: 'History',
                            active: _tab == ProviderOrderTab.completed,
                            onTap: () => setState(
                              () => _tab = ProviderOrderTab.completed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _loadOrders(
                            forceNetwork: true,
                            page: _normalizedPage(pagination.page),
                          ),
                          child: visible.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 80),
                                    _EmptyState(tab: _tab),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final item = visible[index];
                                    return _ProviderOrderCard(
                                      item: item,
                                      onTap: () => _openOrder(item),
                                      onAccept:
                                          item.state ==
                                              ProviderOrderState.incoming
                                          ? () => _move(
                                              item,
                                              ProviderOrderState.onTheWay,
                                            )
                                          : null,
                                      onDecline:
                                          item.state ==
                                              ProviderOrderState.incoming
                                          ? () => _decline(item)
                                          : null,
                                    );
                                  },
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemCount: visible.length,
                                ),
                        ),
                      ),
                      if (pagination.totalPages > 1) ...[
                        const SizedBox(height: 12),
                        PaginationBar(
                          currentPage: _normalizedPage(pagination.page),
                          totalPages: pagination.totalPages,
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
  }

  Future<void> _loadOrders({bool forceNetwork = false, int? page}) async {
    final targetPage = _normalizedPage(
      page ?? OrderState.providerPagination.value.page,
    );
    if (forceNetwork) {
      await OrderState.refreshProviderOrders(page: targetPage);
    } else {
      await OrderState.refreshCurrentRole(page: targetPage);
    }
  }

  Future<void> _openOrder(ProviderOrderItem item) async {
    final updated = await Navigator.push<ProviderOrderItem>(
      context,
      MaterialPageRoute(builder: (_) => ProviderOrderDetailPage(order: item)),
    );
    if (updated == null) return;
    OrderState.replaceProviderOrderLocal(updated);
  }

  Future<void> _move(ProviderOrderItem item, ProviderOrderState next) async {
    try {
      await OrderState.updateProviderOrderStatus(orderId: item.id, state: next);
      if (next == ProviderOrderState.onTheWay ||
          next == ProviderOrderState.started) {
        setState(() => _tab = ProviderOrderTab.active);
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update order status.');
    }
  }

  Future<void> _decline(ProviderOrderItem item) async {
    try {
      await OrderState.updateProviderOrderStatus(
        orderId: item.id,
        state: ProviderOrderState.declined,
      );
      if (!mounted) return;
      AppToast.warning(context, 'Order ${item.id} declined.');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to decline order.');
    }
  }

  Future<void> _goToPage(int page) async {
    final targetPage = _normalizedPage(page);
    if (_isPaging || targetPage == OrderState.providerPagination.value.page) {
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

class _ProviderOrderCard extends StatelessWidget {
  final ProviderOrderItem item;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _ProviderOrderCard({
    required this.item,
    required this.onTap,
    this.onAccept,
    this.onDecline,
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
                    item.serviceName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(state: item.state),
              ],
            ),
            const SizedBox(height: 8),
            Text('Client: ${item.clientName}'),
            Text('Date: ${item.scheduleDate}'),
            Text('Time: ${item.scheduleTime}'),
            Text('Address: ${item.address}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Booking Cost',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$ ${item.total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (onAccept != null) ...[
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Accept',
                      icon: Icons.check_circle_outline_rounded,
                      tone: PrimaryButtonTone.success,
                      onPressed: onAccept,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      isOutlined: true,
                      tone: PrimaryButtonTone.danger,
                      onPressed: onDecline,
                    ),
                  ),
                ],
              ),
            ] else
              PrimaryButton(
                label: item.state == ProviderOrderState.completed
                    ? 'View details'
                    : 'Update status',
                icon: item.state == ProviderOrderState.completed
                    ? Icons.receipt_long_rounded
                    : Icons.sync_alt_rounded,
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ProviderOrderState state;

  const _StatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (state) {
      ProviderOrderState.incoming => ('Incoming', const Color(0xFFD97706)),
      ProviderOrderState.onTheWay => ('On the way', AppColors.primary),
      ProviderOrderState.started => ('Started', AppColors.success),
      ProviderOrderState.completed => ('Completed', AppColors.success),
      ProviderOrderState.declined => ('Declined', AppColors.danger),
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

class _EmptyState extends StatelessWidget {
  final ProviderOrderTab tab;

  const _EmptyState({required this.tab});

  @override
  Widget build(BuildContext context) {
    final label = switch (tab) {
      ProviderOrderTab.incoming => 'No incoming orders now',
      ProviderOrderTab.active => 'No active jobs now',
      ProviderOrderTab.completed => 'No order history yet',
    };
    return Center(
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
