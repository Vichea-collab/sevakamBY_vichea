import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/order.dart';
import '../../state/chat_state.dart';
import '../../state/order_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/order_status_timeline.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';
import '../booking/booking_address_page.dart';
import '../chat/chat_conversation_page.dart';
import '../../state/booking_catalog_state.dart';
import 'manage_order_page.dart';
import 'order_feedback_page.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderItem order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late OrderItem _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    OrderState.finderOrders.addListener(_syncOrderFromState);
    unawaited(
      OrderState.refreshCurrentRole(
        forceNetwork: !OrderState.realtimeActive.value,
      ),
    );
  }

  @override
  void dispose() {
    OrderState.finderOrders.removeListener(_syncOrderFromState);
    super.dispose();
  }

  void _syncOrderFromState() {
    OrderItem? updated;
    for (final item in OrderState.finderOrders.value) {
      if (item.id == _order.id) {
        updated = item;
        break;
      }
    }
    final latest = updated;
    if (latest == null) return;
    if (!mounted || identical(latest, _order)) return;
    setState(() => _order = latest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTopBar(
                title: 'Orders Information',
                subtitle: '${_order.address.street}, ${_order.address.city}',
                onBack: () => Navigator.pop(context, _order),
              ),
              const SizedBox(height: 12),
              Text(
                _order.serviceName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                'Project ID: #${_order.id}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _OrderStatusChip(status: _order.status),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Skill will start - ${_dateLabel(_order.scheduledAt)} @ ${_order.timeRange}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'One-Time ${_order.serviceName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: _order.status == OrderStatus.completed
                                ? 'Rate service'
                                : 'Manage order',
                            icon: _order.status == OrderStatus.completed
                                ? Icons.star_rate_rounded
                                : Icons.tune_rounded,
                            isOutlined: true,
                            onPressed: _order.status == OrderStatus.completed
                                ? () => _openRating()
                                : () => _openManage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryButton(
                            isOutlined: true,
                            tone: PrimaryButtonTone.neutral,
                            icon: _order.status == OrderStatus.completed
                                ? Icons.replay_rounded
                                : Icons.event_note_rounded,
                            onPressed: () => _reorder(),
                            label: _order.status == OrderStatus.completed
                                ? 'Reorder'
                                : 'Add calendar',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _order.status == OrderStatus.completed
                    ? 'Your project has been completed!'
                    : (_order.status == OrderStatus.cancelled ||
                          _order.status == OrderStatus.declined)
                    ? (_order.status == OrderStatus.declined
                          ? 'This booking was declined by provider.'
                          : 'This booking has been cancelled.')
                    : 'Your project has been booked!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _StatusBanner(status: _order.status),
              const SizedBox(height: 8),
              _StatusStepper(status: _order.status),
              const SizedBox(height: 10),
              OrderStatusTimelineCard(entries: _timelineEntries(_order)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(_order.provider.imagePath),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _order.provider.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _order.provider.rating.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _openProviderChat,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          SizedBox(width: 4),
                          Text('Chat now'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Service Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Provider', value: _order.provider.name),
                    _InfoRow(label: 'Service', value: _order.serviceName),
                    _InfoRow(
                      label: 'Scheduled date',
                      value: _dateLabel(_order.scheduledAt),
                    ),
                    _InfoRow(label: 'Time slot', value: _order.timeRange),
                    _InfoRow(
                      label: 'Duration',
                      value: '${_order.hours} hour(s)',
                    ),
                    _InfoRow(label: 'Workers', value: '${_order.workers}'),
                    if (_order.additionalService.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Additional Service',
                        value: _order.additionalService,
                      ),
                    _InfoRow(
                      label: 'Size of home',
                      value: _homeTypeLabel(_order.homeType),
                    ),
                    _InfoRow(
                      label: 'Address',
                      value: '${_order.address.street}, ${_order.address.city}',
                    ),
                    _InfoRow(
                      label: 'Payment method',
                      value: _paymentLabel(_order.paymentMethod),
                    ),
                    _InfoRow(
                      label: 'Address Link',
                      value: _resolvedAddressLink(_order.address),
                    ),
                    const Divider(height: 24),
                    _AmountRow(label: 'Sub Total', amount: _order.subtotal),
                    _AmountRow(
                      label: 'Processing fee',
                      amount: _order.processingFee,
                    ),
                    _AmountRow(
                      label: _order.discount > 0
                          ? 'Promo discount'
                          : 'Promo code',
                      amount: -_order.discount,
                    ),
                    const SizedBox(height: 4),
                    _AmountRow(
                      label: 'Booking Cost',
                      amount: _order.total,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "You won't be charged until the job is completed.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_order.status == OrderStatus.cancelled ||
                  _order.status == OrderStatus.declined) ...[
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Make another booking',
                  onPressed: _reorder,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.order),
    );
  }

  Future<void> _openManage() async {
    final result = await Navigator.push<OrderItem>(
      context,
      slideFadeRoute(ManageOrderPage(order: _order)),
    );
    if (result == null) return;
    final changedStatus = result.status != _order.status;
    if (changedStatus &&
        (result.status == OrderStatus.cancelled ||
            result.status == OrderStatus.completed)) {
      try {
        final synced = await OrderState.updateFinderOrderStatus(
          orderId: result.id,
          status: result.status,
        );
        if (!mounted) return;
        setState(() => _order = synced);
        return;
      } catch (_) {
        if (!mounted) return;
        AppToast.error(context, 'Failed to sync order status.');
      }
    }
    if (!mounted) return;
    setState(() => _order = result);
  }

  Future<void> _openRating() async {
    final result = await Navigator.push<OrderItem>(
      context,
      slideFadeRoute(OrderFeedbackPage(order: _order)),
    );
    if (result == null) return;
    setState(() => _order = result);
  }

  void _reorder() {
    Navigator.push(
      context,
      slideFadeRoute(
        BookingAddressPage(
          draft: BookingCatalogState.defaultBookingDraft(
            provider: _order.provider,
            serviceName: _order.serviceName,
          ),
        ),
      ),
    );
  }

  Future<void> _openProviderChat() async {
    final providerUid = _order.provider.uid.trim();
    if (providerUid.isEmpty) {
      AppToast.info(
        context,
        'Chat will be available once provider accepts the order.',
      );
      return;
    }
    try {
      final thread = await ChatState.openDirectThread(
        peerUid: providerUid,
        peerName: _order.provider.name,
        peerIsProvider: true,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        slideFadeRoute(ChatConversationPage(thread: thread)),
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to open live chat.');
    }
  }

  String _dateLabel(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _homeTypeLabel(HomeType value) {
    switch (value) {
      case HomeType.apartment:
        return 'Apartment';
      case HomeType.flat:
        return 'Flat';
      case HomeType.villa:
        return 'Villa';
      case HomeType.office:
        return 'Office';
    }
  }

  String _resolvedAddressLink(HomeAddress address) {
    final direct = address.mapLink.trim();
    if (direct.isNotEmpty) return direct;
    final query = Uri.encodeComponent('${address.street}, ${address.city}');
    return 'https://maps.google.com/?q=$query';
  }

  List<StatusTimelineEntry> _timelineEntries(OrderItem order) {
    final timeline = order.timeline;
    final entries = <StatusTimelineEntry>[];
    if (timeline.bookedAt != null) {
      entries.add(
        StatusTimelineEntry(
          label: 'Booked',
          at: timeline.bookedAt!,
          icon: Icons.fact_check_outlined,
          color: const Color(0xFFD97706),
        ),
      );
    }
    if (timeline.onTheWayAt != null) {
      entries.add(
        StatusTimelineEntry(
          label: 'On the way',
          at: timeline.onTheWayAt!,
          icon: Icons.local_shipping_outlined,
          color: AppColors.primary,
        ),
      );
    }
    if (timeline.startedAt != null) {
      entries.add(
        StatusTimelineEntry(
          label: 'Started',
          at: timeline.startedAt!,
          icon: Icons.handyman_rounded,
          color: AppColors.success,
        ),
      );
    }
    if (timeline.completedAt != null) {
      entries.add(
        StatusTimelineEntry(
          label: 'Completed',
          at: timeline.completedAt!,
          icon: Icons.verified_rounded,
          color: AppColors.success,
        ),
      );
    }
    if (timeline.cancelledAt != null) {
      entries.add(
        StatusTimelineEntry(
          label: 'Cancelled',
          at: timeline.cancelledAt!,
          icon: Icons.cancel_outlined,
          color: AppColors.danger,
        ),
      );
    }
    if (timeline.declinedAt != null) {
      entries.add(
        StatusTimelineEntry(
          label: 'Declined',
          at: timeline.declinedAt!,
          icon: Icons.highlight_off_rounded,
          color: AppColors.danger,
        ),
      );
    }
    if (entries.isEmpty) {
      entries.add(
        StatusTimelineEntry(
          label: 'Booked',
          at: order.bookedAt,
          icon: Icons.fact_check_outlined,
          color: const Color(0xFFD97706),
        ),
      );
    }
    return entries;
  }

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.bankAccount:
        return 'Bank account';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.khqr:
        return 'Bakong KHQR';
    }
  }
}

class _StatusStepper extends StatelessWidget {
  final OrderStatus status;

  const _StatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['Booked', 'On the way', 'Started', 'Completed'];
    final activeIndex = _statusIndex(status);
    return Row(
      children: List.generate(steps.length, (index) {
        final reached = index <= activeIndex;
        final isCurrent = index == activeIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : reached
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isCurrent ? 24 : 20,
                    height: isCurrent ? 24 : 20,
                    decoration: BoxDecoration(
                      color: reached ? AppColors.primary : AppColors.divider,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary.withValues(alpha: 89)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      reached ? Icons.check : Icons.circle,
                      size: reached ? 12 : 8,
                      color: reached ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (index < activeIndex)
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: reached ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  int _statusIndex(OrderStatus value) {
    switch (value) {
      case OrderStatus.booked:
        return 0;
      case OrderStatus.onTheWay:
        return 1;
      case OrderStatus.started:
        return 2;
      case OrderStatus.completed:
        return 3;
      case OrderStatus.cancelled:
      case OrderStatus.declined:
        return -1;
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      OrderStatus.booked => (
        'Waiting for provider confirmation',
        Icons.pending_actions_rounded,
        const Color(0xFFFFF4E5),
        const Color(0xFFD97706),
      ),
      OrderStatus.onTheWay => (
        'Provider is on the way',
        Icons.local_shipping_outlined,
        const Color(0xFFEAF1FF),
        AppColors.primary,
      ),
      OrderStatus.started => (
        'Service in progress',
        Icons.handyman_rounded,
        const Color(0xFFE9FDF4),
        AppColors.success,
      ),
      OrderStatus.completed => (
        'Service completed',
        Icons.verified_rounded,
        const Color(0xFFE9FDF4),
        AppColors.success,
      ),
      OrderStatus.cancelled => (
        'Booking cancelled',
        Icons.cancel_outlined,
        const Color(0xFFFFEFEF),
        AppColors.danger,
      ),
      OrderStatus.declined => (
        'Request declined by provider',
        Icons.highlight_off_rounded,
        const Color(0xFFFFEFEF),
        AppColors.danger,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      OrderStatus.booked => ('Incoming', const Color(0xFFD97706)),
      OrderStatus.onTheWay => ('On the way', AppColors.primary),
      OrderStatus.started => ('Started', AppColors.success),
      OrderStatus.completed => ('Completed', AppColors.success),
      OrderStatus.cancelled => ('Cancelled', AppColors.danger),
      OrderStatus.declined => ('Declined', AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool bold;

  const _AmountRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: bold ? AppColors.primary : AppColors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text('\$${amount.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
