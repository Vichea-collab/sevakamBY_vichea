import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../domain/entities/order.dart';
import '../../state/booking_catalog_state.dart';
import '../../state/order_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';
import '../main_shell_page.dart';
import '../orders/orders_page.dart';

class BookingConfirmationPage extends StatefulWidget {
  final OrderItem? order;
  final BookingDraft? draft;

  const BookingConfirmationPage({super.key, this.order, this.draft})
    : assert(order != null || draft != null);

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  bool _isSubmitting = false;
  OrderItem? _order;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _order = widget.order;
    } else if (widget.draft != null) {
      _createOrderFromDraft();
    }
  }

  Future<void> _createOrderFromDraft() async {
    final draft = widget.draft;
    if (draft == null) return;
    setState(() => _isSubmitting = true);
    try {
      final created = await OrderState.createFinderOrder(draft);
      if (!mounted) return;
      setState(() {
        _order = created;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.error(context, 'Failed to create booking. Please try again.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting || _order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F6FB),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ),
      );
    }

    final order = _order!;
    final serviceFieldDefs = BookingCatalogState.bookingFieldsForService(
      order.serviceName,
    );
    final serviceEntries = _visibleServiceEntries(
      order.serviceFields,
      serviceFieldDefs,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(title: 'Booking Complete', showBack: false),
              const SizedBox(height: 12),
              _SuccessHero(order: order),
              const SizedBox(height: 22),
              _SectionTitle(title: 'Booking Summary'),
              const SizedBox(height: 12),
              _BookingSummaryCard(order: order),
              if (serviceEntries.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SectionTitle(title: 'Service Requirements'),
                const SizedBox(height: 12),
                _ServiceRequirementsCard(entries: serviceEntries),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Go to Orders',
                icon: Icons.receipt_long_rounded,
                onPressed: _goOrders,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goOrders() {
    final order = _order;
    if (order == null) return;
    OrderState.replaceFinderOrderLocal(order);
    OrdersPage.queuedLatestOrder.value = order;
    MainShellPage.activeTab.value = AppBottomTab.order;
    Navigator.pushNamedAndRemoveUntil(
      context,
      MainShellPage.routeName,
      (route) => false,
    );
  }

  List<MapEntry<String, String>> _visibleServiceEntries(
    Map<String, dynamic> values,
    List<BookingFieldDef> defs,
  ) {
    final defsByKey = {for (final def in defs) def.key: def};
    final entries = <MapEntry<String, String>>[];
    for (final entry in values.entries) {
      final def = defsByKey[entry.key];
      if (def == null) continue;
      final displayValue = _displayServiceValue(entry.value);
      if (displayValue == null) continue;
      entries.add(MapEntry(def.label, displayValue));
    }
    return entries;
  }

  String? _displayServiceValue(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 'Yes' : 'No';
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final normalized = text.toLowerCase();
    if (normalized == 'true') return 'Yes';
    if (normalized == 'false') return 'No';
    if (text.startsWith('data:image/')) return 'Photo attached';
    return text;
  }
}

class _SuccessHero extends StatelessWidget {
  final OrderItem order;

  const _SuccessHero({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD9E6FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 24,
            spreadRadius: -12,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FDF4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Booking Confirmed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your booking is confirmed',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your ${order.serviceName.toLowerCase()} request has been sent to ${order.provider.name}. Track updates from the Orders tab.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final OrderItem order;

  const _BookingSummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: SafeImage(
                    isAvatar: true,
                    source: order.provider.imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.serviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.provider.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Date',
                  value: _dateLabel(order.scheduledAt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCell(label: 'Time', value: order.timeRange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCell(label: 'Category', value: order.provider.role),
          const SizedBox(height: 12),
          _SummaryCell(
            label: 'Address',
            value: '${order.address.street}, ${order.address.city}',
            multiline: true,
          ),
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
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _SummaryCell({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: multiline ? null : 2,
            overflow: multiline ? null : TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRequirementsCard extends StatelessWidget {
  final List<MapEntry<String, String>> entries;

  const _ServiceRequirementsCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: entries
            .asMap()
            .entries
            .map((item) {
              final index = item.key;
              final entry = item.value;
              final isLast = index == entries.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconForValue(entry.value),
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  static IconData _iconForValue(String value) {
    if (value == 'Yes' || value == 'No') {
      return Icons.toggle_on_rounded;
    }
    if (value == 'Photo attached') {
      return Icons.photo_camera_outlined;
    }
    return Icons.checklist_rtl_rounded;
  }
}
