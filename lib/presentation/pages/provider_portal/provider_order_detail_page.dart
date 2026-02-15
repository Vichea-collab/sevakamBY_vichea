import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/order_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProviderOrderDetailPage extends StatefulWidget {
  final ProviderOrderItem order;

  const ProviderOrderDetailPage({super.key, required this.order});

  @override
  State<ProviderOrderDetailPage> createState() =>
      _ProviderOrderDetailPageState();
}

class _ProviderOrderDetailPageState extends State<ProviderOrderDetailPage> {
  late ProviderOrderItem _order;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
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
                subtitle: _order.address,
                onBack: () => Navigator.pop(context, _order),
              ),
              const SizedBox(height: 12),
              Text(
                _order.serviceName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Project ID: #${_order.id}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _ProviderStatusChip(status: _order.state),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
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
                      'The Skill will start - ${_order.scheduleDate} @ ${_order.scheduleTime}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One-Time ${_order.serviceName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your project progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ProviderStatusBanner(status: _order.state),
              const SizedBox(height: 10),
              _StatusStepper(status: _order.state),
              const SizedBox(height: 16),
              Text(
                'Finder booking details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Client', value: _order.clientName),
                    if (_order.clientPhone.trim().isNotEmpty)
                      _InfoRow(label: 'Contact', value: _order.clientPhone),
                    _InfoRow(label: 'Category', value: _order.category),
                    _InfoRow(label: 'Service', value: _order.serviceName),
                    _InfoRow(
                      label: 'Scheduled date',
                      value: _order.scheduleDate,
                    ),
                    _InfoRow(label: 'Time slot', value: _order.scheduleTime),
                    _InfoRow(
                      label: 'Duration',
                      value: '${_order.hours} hour(s)',
                    ),
                    _InfoRow(label: 'Workers', value: '${_order.workers}'),
                    if (_order.homeType.trim().isNotEmpty)
                      _InfoRow(label: 'Home type', value: _order.homeType),
                    if (_order.additionalService.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Additional service',
                        value: _order.additionalService,
                      ),
                    _InfoRow(label: 'Address', value: _order.address),
                    _InfoRow(
                      label: 'Address link',
                      value: _resolvedAddressLink(_order),
                    ),
                    if (_order.paymentMethod.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Payment method',
                        value: _order.paymentMethod,
                      ),
                    if (_order.finderNote.trim().isNotEmpty)
                      _InfoRow(label: 'Finder note', value: _order.finderNote),
                    if (_order.serviceInputs.isNotEmpty) ...[
                      const Divider(height: 22),
                      Text(
                        'Service inputs from finder',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._order.serviceInputs.entries.map(
                        (entry) =>
                            _InfoRow(label: entry.key, value: entry.value),
                      ),
                    ],
                    const Divider(height: 22),
                    _AmountRow(label: 'Sub Total', amount: _order.subtotal),
                    _AmountRow(
                      label: 'Processing fee',
                      amount: _order.processingFee,
                    ),
                    _AmountRow(
                      label: 'Promo discount',
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
              const SizedBox(height: 18),
              _ActionPanel(
                status: _order.state,
                busy: _updatingStatus,
                onAccept: () => _updateStatus(ProviderOrderState.onTheWay),
                onDecline: () => _updateStatus(ProviderOrderState.declined),
                onMarkStarted: () => _updateStatus(ProviderOrderState.started),
                onMarkCompleted: () =>
                    _updateStatus(ProviderOrderState.completed),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: _updatingStatus ? 'Updating...' : 'Done',
                icon: Icons.check_rounded,
                onPressed: _updatingStatus
                    ? null
                    : () => Navigator.pop(context, _order),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.order),
    );
  }

  Future<void> _updateStatus(ProviderOrderState next) async {
    if (_updatingStatus || _order.state == next) return;
    setState(() => _updatingStatus = true);
    try {
      final updated = await OrderState.updateProviderOrderStatus(
        orderId: _order.id,
        state: next,
      );
      if (!mounted) return;
      setState(() => _order = updated);
      AppToast.success(context, 'Status updated: ${_statusLabel(next)}');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update order status.');
    } finally {
      if (mounted) {
        setState(() => _updatingStatus = false);
      }
    }
  }

  String _statusLabel(ProviderOrderState status) {
    switch (status) {
      case ProviderOrderState.incoming:
        return 'Incoming';
      case ProviderOrderState.onTheWay:
        return 'On the way';
      case ProviderOrderState.started:
        return 'Started';
      case ProviderOrderState.completed:
        return 'Completed';
      case ProviderOrderState.declined:
        return 'Declined';
    }
  }

  String _resolvedAddressLink(ProviderOrderItem order) {
    final direct = order.addressLink.trim();
    if (direct.isNotEmpty) return direct;
    final query = Uri.encodeComponent(order.address);
    return 'https://maps.google.com/?q=$query';
  }
}

class _ActionPanel extends StatelessWidget {
  final ProviderOrderState status;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onMarkStarted;
  final VoidCallback onMarkCompleted;

  const _ActionPanel({
    required this.status,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onMarkStarted,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ProviderOrderState.completed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBF0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFE8CA)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.task_alt_rounded,
              color: AppColors.success,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              'Order completed',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
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
            'Update order status',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (status == ProviderOrderState.incoming) ...[
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Accept',
                    icon: Icons.check_circle_outline_rounded,
                    tone: PrimaryButtonTone.success,
                    onPressed: busy ? null : onAccept,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Decline',
                    icon: Icons.close_rounded,
                    isOutlined: true,
                    tone: PrimaryButtonTone.danger,
                    onPressed: busy ? null : onDecline,
                  ),
                ),
              ],
            ),
          ] else if (status == ProviderOrderState.onTheWay) ...[
            PrimaryButton(
              label: 'Mark Started',
              icon: Icons.play_circle_fill_rounded,
              tone: PrimaryButtonTone.primary,
              onPressed: busy ? null : onMarkStarted,
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Mark Complete',
              icon: Icons.task_alt_rounded,
              isOutlined: true,
              tone: PrimaryButtonTone.success,
              onPressed: busy ? null : onMarkCompleted,
            ),
          ] else if (status == ProviderOrderState.started) ...[
            PrimaryButton(
              label: 'Mark Complete',
              icon: Icons.task_alt_rounded,
              tone: PrimaryButtonTone.success,
              onPressed: busy ? null : onMarkCompleted,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final ProviderOrderState status;

  const _StatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['Booked', 'On the way', 'Started', 'Completed'];
    final index = _statusIndex(status);
    return Row(
      children: List.generate(steps.length, (i) {
        final reached = i <= index;
        final isCurrent = i == index;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i == 0
                          ? Colors.transparent
                          : reached
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isCurrent ? 25 : 21,
                    height: isCurrent ? 25 : 21,
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
                      reached ? Icons.check_rounded : Icons.circle,
                      size: reached ? 14 : 8,
                      color: reached ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i == steps.length - 1
                          ? Colors.transparent
                          : (i < index)
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[i],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  int _statusIndex(ProviderOrderState value) {
    switch (value) {
      case ProviderOrderState.incoming:
        return 0;
      case ProviderOrderState.onTheWay:
        return 1;
      case ProviderOrderState.started:
        return 2;
      case ProviderOrderState.completed:
        return 3;
      case ProviderOrderState.declined:
        return 0;
    }
  }
}

class _ProviderStatusBanner extends StatelessWidget {
  final ProviderOrderState status;

  const _ProviderStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      ProviderOrderState.incoming => (
        'New request waiting for your action',
        Icons.inbox_rounded,
        const Color(0xFFFFF4E5),
        const Color(0xFFD97706),
      ),
      ProviderOrderState.onTheWay => (
        'You accepted and are on the way',
        Icons.local_shipping_outlined,
        const Color(0xFFEAF1FF),
        AppColors.primary,
      ),
      ProviderOrderState.started => (
        'Service started, keep client updated',
        Icons.handyman_rounded,
        const Color(0xFFE9FDF4),
        AppColors.success,
      ),
      ProviderOrderState.completed => (
        'Order successfully completed',
        Icons.verified_rounded,
        const Color(0xFFE9FDF4),
        AppColors.success,
      ),
      ProviderOrderState.declined => (
        'You declined this request',
        Icons.cancel_outlined,
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

class _ProviderStatusChip extends StatelessWidget {
  final ProviderOrderState status;

  const _ProviderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ProviderOrderState.incoming => ('Incoming', const Color(0xFFD97706)),
      ProviderOrderState.onTheWay => ('On the way', AppColors.primary),
      ProviderOrderState.started => ('Started', AppColors.success),
      ProviderOrderState.completed => ('Completed', AppColors.success),
      ProviderOrderState.declined => ('Declined', AppColors.danger),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: bold ? AppColors.primary : AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
