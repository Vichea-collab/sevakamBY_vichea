import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/booking_step_progress.dart';
import '../../widgets/primary_button.dart';
import '../orders/orders_page.dart';

class BookingConfirmationPage extends StatefulWidget {
  final OrderItem order;

  const BookingConfirmationPage({super.key, required this.order});

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: const Color(0xFF6B7280),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 62,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 100,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Booking Confirmation',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${order.address.street}, ${order.address.city}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: _goProjects,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 24),
                          const BookingStepProgress(
                            currentStep: BookingFlowStep.confirmation,
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Container(
                              height: 64,
                              width: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Thanks, your booking has been confirmed.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      height: 1.4,
                                    ),
                                children: const [
                                  TextSpan(
                                    text:
                                        'Please check your email for receipt and booking details\nor visit ',
                                  ),
                                  TextSpan(
                                    text: 'Projects',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: ' to review your booking.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Service Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _ServiceDetailCard(
                            order: order,
                            expanded: _expanded,
                            onToggle: () =>
                                setState(() => _expanded = !_expanded),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Booking Cost',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                '\$ ${order.total.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You won't be charged until the job is completed.",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: PrimaryButton(
                      label: 'Go to Projects',
                      onPressed: _goProjects,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goProjects() {
    Navigator.pushAndRemoveUntil(
      context,
      slideFadeRoute(OrdersPage(latestOrder: widget.order)),
      (route) => false,
    );
  }
}

class _ServiceDetailCard extends StatelessWidget {
  final OrderItem order;
  final bool expanded;
  final VoidCallback onToggle;

  const _ServiceDetailCard({
    required this.order,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage(order.provider.imagePath),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.serviceName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoDoubleRow(
              leftLabel: 'Date',
              leftValue: _dateLabel(order.scheduledAt),
              rightLabel: 'Start time',
              rightValue: order.timeRange,
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoSingleRow(label: 'Skillr', value: order.provider.name),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoSingleRow(
              label: 'Payment method',
              value: _paymentLabel(order.paymentMethod),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoDoubleRow(
              leftLabel: 'You selected',
              leftValue: '${order.workers} workers | ${order.hours} hours',
              rightLabel: 'Size of home',
              rightValue: _homeTypeLabel(order.homeType),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoSingleRow(
              label: 'Address',
              value: '${order.address.street}, ${order.address.city}',
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoSingleRow(
              label: 'Address Link',
              value: _resolvedAddressLink(order.address),
            ),
            if (order.additionalService.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _InfoSingleRow(
                label: 'Additional Service',
                value: order.additionalService,
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    const week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${week[date.weekday - 1]}, ${month[date.month - 1]} ${date.day}';
  }

  static String _homeTypeLabel(HomeType value) {
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

  static String _resolvedAddressLink(HomeAddress address) {
    final direct = address.mapLink.trim();
    if (direct.isNotEmpty) return direct;
    final query = Uri.encodeComponent('${address.street}, ${address.city}');
    return 'https://maps.google.com/?q=$query';
  }

  static String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.bankAccount:
        return 'Credit Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.khqr:
        return 'Bakong KHQR';
    }
  }
}

class _InfoSingleRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoSingleRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoDoubleRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _InfoDoubleRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoSingleRow(label: leftLabel, value: leftValue),
        ),
        Container(
          height: 38,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: AppColors.divider,
        ),
        Expanded(
          child: _InfoSingleRow(label: rightLabel, value: rightValue),
        ),
      ],
    );
  }
}
