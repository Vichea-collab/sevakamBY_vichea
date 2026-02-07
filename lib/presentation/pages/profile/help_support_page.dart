import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class HelpSupportPage extends StatelessWidget {
  static const String routeName = '/profile/help';

  const HelpSupportPage({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTopBar(
                title: 'Help & support',
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Live chat')),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    size: 62,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Hello, how can we assist you?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),
              Text('Title', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              const TextField(
                decoration: InputDecoration(hintText: 'Enter the title of your issue'),
              ),
              const SizedBox(height: 12),
              Text(
                'Write in below box',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              const TextField(
                maxLines: 4,
                decoration: InputDecoration(hintText: 'Write here..'),
              ),
              const SizedBox(height: 18),
              PrimaryButton(label: 'Send', onPressed: () {}),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Live chat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
