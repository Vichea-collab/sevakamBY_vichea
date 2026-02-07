import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class EditProfilePage extends StatelessWidget {
  static const String routeName = '/profile/edit';

  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            10,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              const AppTopBar(title: 'Edit Profile'),
              const SizedBox(height: 12),
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 42,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _LabeledField(label: 'Name', hint: 'Kimheng'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Email', hint: 'kimheng@gmail.com'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Date of Birth', hint: '28/11/2005'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Country', hint: 'Cambodia'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Phone number', hint: '+88 123456'),
              const SizedBox(height: 18),
              PrimaryButton(label: 'Save', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;

  const _LabeledField({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
