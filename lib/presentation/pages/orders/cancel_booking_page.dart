import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/order.dart';
import '../../state/booking_catalog_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class CancelBookingPage extends StatefulWidget {
  final OrderItem order;

  const CancelBookingPage({super.key, required this.order});

  @override
  State<CancelBookingPage> createState() => _CancelBookingPageState();
}

class _CancelBookingPageState extends State<CancelBookingPage> {
  String? _selectedReason = BookingCatalogState.cancelReasons.first;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const AppTopBar(title: 'Cancel Booking'),
              const SizedBox(height: 10),
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.sentiment_dissatisfied_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Please let us know why you're canceling your booking.",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: BookingCatalogState.cancelReasons.length,
                  itemBuilder: (context, index) {
                    final reason = BookingCatalogState.cancelReasons[index];
                    final selected = _selectedReason == reason;
                    return InkWell(
                      onTap: () => setState(() => _selectedReason = reason),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(reason)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: "Don't Cancel",
                      isOutlined: true,
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: _submitting ? '...' : 'Cancel Booking',
                      onPressed: _submitting ? null : _cancelBooking,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelBooking() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final cancelled = widget.order.copyWith(status: OrderStatus.cancelled);
    Navigator.pop(context, cancelled);
  }
}
