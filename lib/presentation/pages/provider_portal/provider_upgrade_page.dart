import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProviderUpgradePage extends StatelessWidget {
  static const String routeName = '/provider/upgrade';

  const ProviderUpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const AppTopBar(title: 'Upgrade'),
              const SizedBox(height: 20),
              const Icon(
                Icons.verified_user_rounded,
                size: 82,
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'Upgrade to get full access',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              const _Benefit(label: 'Access to three services'),
              const _Benefit(label: 'Featured listings'),
              const _Benefit(label: 'Gallery showcase'),
              const _Benefit(label: 'Extended service area'),
              const _Benefit(label: 'Premium badge'),
              const Spacer(),
              PrimaryButton(
                label: 'Upgrade',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String label;

  const _Benefit({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFFF97316), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
