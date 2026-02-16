import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../widgets/primary_button.dart';
import 'onboarding_page.dart';
import 'auth/customer_auth_page.dart';
import 'auth/provider_auth_page.dart';
import 'auth/forgot_password_flow.dart';
import 'home/home_page.dart';
import 'providers/provider_home_page.dart';

class WelcomePage extends StatelessWidget {
  static const String routeName = '/welcome';

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sevakam',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Find trusted home\nservices near you',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Book verified professionals for repairs, cleaning, and more.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.splashStart, AppColors.splashEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fast booking',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Professional\nservices, on time',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/plumber_category.jpg',
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Continue as Customer',
                onPressed: () =>
                    Navigator.pushNamed(context, CustomerAuthPage.routeName),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Continue as Provider',
                isOutlined: true,
                onPressed: () =>
                    Navigator.pushNamed(context, ProviderAuthPage.routeName),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, HomePage.routeName),
                child: const Text('Explore home'),
              ),
              const SizedBox(height: 16),
              _NavCard(
                title: 'Onboarding',
                description: 'Preview onboarding screens',
                onPressed: () =>
                    Navigator.pushNamed(context, OnboardingPage.routeName),
              ),
              const SizedBox(height: AppSpacing.md),
              _NavCard(
                title: 'Forgot Password',
                description: 'Password reset flow screens',
                onPressed: () =>
                    Navigator.pushNamed(context, ForgotPasswordFlow.routeName),
              ),
              const SizedBox(height: AppSpacing.md),
              _NavCard(
                title: 'Providers',
                description: 'Service providers lists and categories',
                onPressed: () =>
                    Navigator.pushNamed(context, ProviderHomePage.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPressed;

  const _NavCard({
    required this.title,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
