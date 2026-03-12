import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../domain/entities/order.dart';
import '../../state/chat_state.dart';
import '../../state/order_state.dart';
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
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    OrderState.finderOrders.addListener(_syncOrderFromState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        OrderState.refreshCurrentRole(
          forceNetwork: !OrderState.realtimeActive.value,
        ),
      );
    });
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
    _safeSetState(() => _order = latest);
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.postFrameCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
      return;
    }
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final hasReview = _order.hasReview;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTopBar(
                title: 'Order Information',
                subtitle: '${_order.address.street}, ${_order.address.city}',
                onBack: () => Navigator.pop(context, _order),
              ),
              const SizedBox(height: 12),
              Text(
                _order.serviceName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              Text(
                'Order ID: #${_order.id}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _OrderStatusChip(status: _order.status),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scheduled: ${_dateLabel(_order.scheduledAt)} @ ${_order.timeRange}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Service: ${_order.serviceName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: _order.status == OrderStatus.completed
                                ? (hasReview
                                      ? 'Review submitted'
                                      : 'Rate service')
                                : 'Manage order',
                            icon: _order.status == OrderStatus.completed
                                ? (hasReview
                                      ? Icons.check_circle_rounded
                                      : Icons.star_rate_rounded)
                                : Icons.tune_rounded,
                            isOutlined: true,
                            onPressed: _order.status == OrderStatus.completed
                                ? (hasReview ? null : () => _openRating())
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
                    ? 'Your service has been completed!'
                    : (_order.status == OrderStatus.cancelled ||
                          _order.status == OrderStatus.declined)
                    ? (_order.status == OrderStatus.declined
                          ? 'This booking was declined by provider.'
                          : 'This booking has been cancelled.')
                    : 'Your booking has been confirmed!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
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
              
              if (_order.status == OrderStatus.started) ...[
                PrimaryButton(
                  label: _updating ? 'Marking complete...' : 'Mark as Completed',
                  icon: Icons.verified_rounded,
                  tone: PrimaryButtonTone.success,
                  onPressed: _updating ? null : () => _updateStatus(OrderStatus.completed),
                ),
                const SizedBox(height: 12),
              ],

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.background,
                      backgroundImage: _order.provider.imagePath.trim().isNotEmpty
                          ? safeImageProvider(_order.provider.imagePath)
                          : null,
                      child: _order.provider.imagePath.trim().isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 24,
                              color: AppColors.primary,
                            )
                          : null,
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
                'Booking Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
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
                    if (_order.additionalService.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Additional Info',
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
                      label: 'Address Link',
                      value: _resolvedAddressLink(_order.address),
                    ),
                  ],
                ),
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
    );
  }

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _updating = true);
    try {
      final synced = await OrderState.updateFinderOrderStatus(
        orderId: _order.id,
        status: status,
      );
      if (!mounted) return;
      setState(() => _order = synced);
      if (status == OrderStatus.completed) {
        _openRating();
      }
    } catch (_) {
      if (mounted) AppToast.error(context, 'Failed to update status.');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
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
    final rating = result.rating;
    if (rating == null || rating <= 0) return;
    try {
      final synced = await OrderState.submitFinderOrderReview(
        orderId: result.id,
        rating: rating,
        comment: result.reviewComment,
      );
      if (!mounted) return;
      setState(() => _order = synced);
      AppToast.success(context, 'Thanks for your feedback.');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to submit review.');
    }
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
          icon: Icons.delivery_dining_rounded,
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
          color: const Color(0xFF7C6EF2),
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
}

class _StatusStepper extends StatelessWidget {
  final OrderStatus status;

  const _StatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['Booked', 'Confirm', 'Started', 'Completed'];
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
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isCurrent ? 24 : 20,
                    height: isCurrent ? 24 : 20,
                    decoration: BoxDecoration(
                      color: reached ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 89)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      reached ? Icons.check : Icons.circle,
                      size: reached ? 12 : 8,
                      color: reached ? Colors.white : Theme.of(context).hintColor,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (index < activeIndex)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: reached ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
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
        'Provider confirmed',
        Icons.delivery_dining_rounded,
        const Color(0xFFEAF1FF),
        AppColors.primary,
      ),
      OrderStatus.started => (
        'Service in progress',
        Icons.handyman_rounded,
        const Color(0xFFF1ECFF),
        const Color(0xFF7C6EF2),
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
      OrderStatus.booked => ('Booked', const Color(0xFFD97706)),
      OrderStatus.onTheWay => ('Confirm', AppColors.primary),
      OrderStatus.started => ('Started', const Color(0xFF7C6EF2)),
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
