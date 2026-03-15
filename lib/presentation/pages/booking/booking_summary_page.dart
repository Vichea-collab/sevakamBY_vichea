import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../domain/entities/order.dart';
import '../../state/booking_catalog_state.dart';
import '../../state/order_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/booking_step_progress.dart';
import '../../widgets/primary_button.dart';
import 'booking_confirmation_page.dart';

class BookingPaymentPage extends StatefulWidget {
  final BookingDraft draft;

  const BookingPaymentPage({super.key, required this.draft});

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final serviceFieldDefs = BookingCatalogState.bookingFieldsForService(
      widget.draft.serviceName,
    );
    final visibleServiceEntries = _visibleServiceEntries(
      widget.draft.serviceFields,
      serviceFieldDefs,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                children: [
                  const AppTopBar(title: 'Booking Summary'),
                  const SizedBox(height: 16),
                  const BookingStepProgress(
                    currentStep: BookingFlowStep.payment,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // Booking Detail Header Section
                  _SectionHeader(
                    title: 'Booking Details',
                    icon: Icons.assignment_outlined,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _SummaryDetailRow(
                          icon: Icons.build_circle_rounded,
                          label: 'Service',
                          value: widget.draft.serviceName,
                          valueColor: AppColors.primary,
                        ),
                        const _SummaryDivider(),
                        _SummaryDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: _dateLabel(widget.draft.preferredDate),
                        ),
                        const _SummaryDivider(),
                        _SummaryDetailRow(
                          icon: Icons.access_time_filled_rounded,
                          label: 'Time Slot',
                          value: widget.draft.preferredTimeSlot,
                        ),
                        const _SummaryDivider(),
                        _SummaryDetailRow(
                          icon: Icons.location_on_rounded,
                          label: 'Location',
                          value: widget.draft.address?.street ?? 'Not provided',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Provider Section
                  _SectionHeader(
                    title: 'Service Provider',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _ProviderInfoCard(draft: widget.draft),

                  const SizedBox(height: 24),

                  // Service Requirements (Dynamic Fields)
                  if (visibleServiceEntries.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Service Requirements',
                      icon: Icons.fact_check_outlined,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ...visibleServiceEntries.asMap().entries.map((item) {
                            final index = item.key;
                            final entry = item.value;
                            final isLast =
                                index == visibleServiceEntries.length - 1;
                            return Column(
                              children: [
                                _SummaryDetailRow(
                                  icon: _summaryIconForValue(entry.value),
                                  label: entry.key,
                                  value: entry.value,
                                  isSmall: true,
                                ),
                                if (!isLast) const _SummaryDivider(),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Bottom Info Note
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Direct cash payment to provider",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Pay the service fee after completion",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
        child: PrimaryButton(
          label: _submitting ? 'Confirming...' : 'Confirm Booking',
          icon: Icons.check_circle_rounded,
          onPressed: _submitting ? null : _confirmBooking,
        ),
      ),
    );
  }

  Future<void> _confirmBooking() async {
    setState(() => _submitting = true);
    try {
      final order = await OrderState.createFinderOrder(widget.draft);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        slideFadeRoute(BookingConfirmationPage(order: order)),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to confirm booking. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _dateLabel(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  IconData _summaryIconForValue(String value) {
    if (value == 'Yes' || value == 'No') {
      return Icons.toggle_on_rounded;
    }
    if (value == 'Photo attached') {
      return Icons.photo_camera_outlined;
    }
    return Icons.arrow_right_rounded;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _SummaryDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isSmall;

  const _SummaryDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 15,
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 10, bottom: 10),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ProviderInfoCard extends StatelessWidget {
  final BookingDraft draft;

  const _ProviderInfoCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: SafeImage(
                isAvatar: true,
                source: draft.provider.imagePath,
                width: 52,
                height: 52,
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
                  draft.provider.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  draft.provider.role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  draft.provider.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB47800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
