import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/step_indicator.dart';
import 'customer_auth_page.dart';

class ForgotPasswordFlow extends StatefulWidget {
  static const String routeName = '/auth/forgot';

  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  final PageController _controller = PageController();
  int _index = 0;

  void _next() {
    if (_index < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      CustomerAuthPage.routeName,
                    ),
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Forgot Password',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                children: [
                  _ResetRequestStep(onNext: _next),
                  _ResetEmailSentStep(onNext: _next),
                  const _ResetSuccessStep(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            StepIndicator(count: 3, index: _index),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ResetRequestStep extends StatelessWidget {
  final VoidCallback onNext;

  const _ResetRequestStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Forgot Password?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            "We'll email you a link you can use to reset your password.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppTextField(hint: 'Email Address'),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Next', onPressed: onNext),
        ],
      ),
    );
  }
}

class _ResetEmailSentStep extends StatelessWidget {
  final VoidCallback onNext;

  const _ResetEmailSentStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Let\'s reset your password.',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'We will email you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppTextField(hint: 'kimheng@gmail.com'),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Next', onPressed: onNext),
        ],
      ),
    );
  }
}

class _ResetSuccessStep extends StatelessWidget {
  const _ResetSuccessStep();

  @override
  Widget build(BuildContext context) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check your inbox',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'We sent a link to kimheng@gmail.com to set up a new password.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Resend Link', onPressed: () {}),
        ],
      ),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  final Widget child;

  const _CardWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
