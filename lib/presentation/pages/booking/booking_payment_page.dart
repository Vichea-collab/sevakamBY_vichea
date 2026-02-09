import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';
import 'booking_confirmation_page.dart';

class BookingPaymentPage extends StatefulWidget {
  final BookingDraft draft;

  const BookingPaymentPage({super.key, required this.draft});

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  late PaymentMethod _selectedMethod;
  late TextEditingController _promoController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.draft.paymentMethod;
    _promoController = TextEditingController(text: widget.draft.promoCode);
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft.copyWith(
      paymentMethod: _selectedMethod,
      promoCode: _promoController.text.trim(),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              const AppTopBar(title: 'Payment'),
              const SizedBox(height: 14),
              Text(
                'Select Payment method',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 10),
              _PaymentTile(
                label: 'Credit Card',
                icon: Icons.credit_card,
                selected: _selectedMethod == PaymentMethod.creditCard,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.creditCard),
              ),
              _PaymentTile(
                label: 'Bank account',
                icon: Icons.account_balance,
                selected: _selectedMethod == PaymentMethod.bankAccount,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.bankAccount),
              ),
              _PaymentTile(
                label: 'Cash',
                icon: Icons.payments_outlined,
                selected: _selectedMethod == PaymentMethod.cash,
                onTap: () =>
                    setState(() => _selectedMethod = PaymentMethod.cash),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _promoController,
                decoration: const InputDecoration(
                  hintText: 'Promo code',
                  prefixIcon: Icon(Icons.local_offer_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
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
                    _InfoRow(label: 'Service', value: draft.serviceName),
                    _InfoRow(label: 'Provider', value: draft.provider.name),
                    _InfoRow(
                      label: 'Date',
                      value: _dateLabel(draft.preferredDate),
                    ),
                    _InfoRow(
                      label: 'Time slot',
                      value: draft.preferredTimeSlot,
                    ),
                    _InfoRow(
                      label: 'Duration',
                      value: '${draft.hours} hour(s)',
                    ),
                    _InfoRow(label: 'Workers', value: '${draft.workers}'),
                    _InfoRow(
                      label: 'Home type',
                      value: _homeTypeLabel(draft.homeType),
                    ),
                    _InfoRow(
                      label: 'Address',
                      value:
                          '${draft.address?.street ?? ''}, ${draft.address?.city ?? ''}',
                    ),
                    if (draft.additionalService.trim().isNotEmpty)
                      _InfoRow(
                        label: 'Additional service',
                        value: draft.additionalService,
                      ),
                    _InfoRow(
                      label: 'Payment method',
                      value: _paymentLabel(_selectedMethod),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _AmountRow(label: 'Sub Total', amount: draft.subtotal),
                    _AmountRow(
                      label: 'Processing fee',
                      amount: draft.processingFee,
                    ),
                    _AmountRow(
                      label: draft.promoCode.trim().isEmpty
                          ? 'Promo code'
                          : 'Promo code (${draft.promoCode.trim()})',
                      amount: -draft.discount,
                    ),
                    const Divider(height: 20),
                    _AmountRow(
                      label: 'Booking Cost',
                      amount: draft.total,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _submitting ? 'Processing...' : 'Place Booking',
                onPressed: _submitting ? null : () => _placeBooking(draft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeBooking(BookingDraft draft) async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final order = MockData.createOrderFromDraft(draft);
    Navigator.pushReplacement(
      context,
      slideFadeRoute(BookingConfirmationPage(order: order)),
    );
  }

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.bankAccount:
        return 'Bank account';
      case PaymentMethod.cash:
        return 'Cash';
    }
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

  String _dateLabel(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
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

class _PaymentTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDCEBFF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Icon(
              Icons.check,
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ],
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
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
