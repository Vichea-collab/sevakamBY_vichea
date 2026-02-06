import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class PaymentPage extends StatefulWidget {
  static const String routeName = '/profile/payment';

  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text('Payment', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 18),
              Text('Select Payment method', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              _PaymentTile(
                label: 'Credit Card',
                icon: Icons.credit_card,
                selected: selected == 0,
                onTap: () => setState(() => selected = 0),
              ),
              _PaymentTile(
                label: 'Bank account',
                icon: Icons.account_balance,
                selected: selected == 1,
                onTap: () => setState(() => selected = 1),
              ),
              _PaymentTile(
                label: 'Cash Out',
                icon: Icons.payments_outlined,
                selected: selected == 2,
                onTap: () => setState(() => selected = 2),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add new card'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
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
            Icon(Icons.check, color: selected ? AppColors.primary : AppColors.divider),
          ],
        ),
      ),
    );
  }
}
