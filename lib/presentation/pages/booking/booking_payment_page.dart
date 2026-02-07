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
              const AppTopBar(
                title: 'Payment',
              ),
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
                onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
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
                    _AmountRow(label: 'Processing fee', amount: draft.processingFee),
                    _AmountRow(
                      label: 'Promo code (20% OFF)',
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
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
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
