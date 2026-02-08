import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProviderVerificationPage extends StatelessWidget {
  static const String routeName = '/provider/verification';

  const ProviderVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const AppTopBar(title: 'Verification'),
              const SizedBox(height: 16),
              _VerificationRow(
                icon: Icons.mark_email_read_outlined,
                title: 'Email',
                status: 'Verified',
              ),
              const SizedBox(height: 10),
              _VerificationRow(
                icon: Icons.call_outlined,
                title: 'Mobile number',
                status: 'Verified',
              ),
              const SizedBox(height: 10),
              _VerificationRow(
                icon: Icons.badge_outlined,
                title: 'National ID card',
                status: 'Verify',
                statusColor: AppColors.primary,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Save',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final Color? statusColor;

  const _VerificationRow({
    required this.icon,
    required this.title,
    required this.status,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(
            status,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: statusColor ?? AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
