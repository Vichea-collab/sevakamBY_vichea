import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/order.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class PaymentPage extends StatefulWidget {
  static const String routeName = '/profile/payment';

  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late PaymentMethod _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = ProfileSettingsState.currentPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            10,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(title: 'Payment'),
              const SizedBox(height: 18),
              Text(
                'Select Payment method',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              _PaymentTile(
                label: 'Credit Card',
                icon: Icons.credit_card,
                selected: _selected == PaymentMethod.creditCard,
                onTap: () =>
                    setState(() => _selected = PaymentMethod.creditCard),
              ),
              _PaymentTile(
                label: 'Bank account',
                icon: Icons.account_balance,
                selected: _selected == PaymentMethod.bankAccount,
                onTap: () =>
                    setState(() => _selected = PaymentMethod.bankAccount),
              ),
              _PaymentTile(
                label: 'Cash Out',
                icon: Icons.payments_outlined,
                selected: _selected == PaymentMethod.cash,
                onTap: () => setState(() => _selected = PaymentMethod.cash),
              ),
              _PaymentTile(
                label: 'Bakong KHQR',
                icon: Icons.qr_code_2_rounded,
                selected: _selected == PaymentMethod.khqr,
                onTap: () => setState(() => _selected = PaymentMethod.khqr),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppToast.info(
                      context,
                      'Card management screen can be added next.',
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add new card'),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _saving ? 'Saving...' : 'Save',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProfileSettingsState.saveCurrentPaymentMethod(_selected);
    if (!mounted) return;
    setState(() => _saving = false);
    AppToast.success(context, 'Payment preference saved.');
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDCEBFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              ),
            ),
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
