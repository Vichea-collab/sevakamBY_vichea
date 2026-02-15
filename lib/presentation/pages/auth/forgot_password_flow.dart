import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../state/auth_state.dart';
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
  final TextEditingController _emailController = TextEditingController();
  int _index = 0;
  bool _sending = false;
  String _sentEmail = '';

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= 2) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, CustomerAuthPage.routeName);
      }
      return;
    }
    _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (!_validEmail(email)) {
      AppToast.warning(context, 'Please enter a valid email address.');
      return;
    }

    setState(() => _sending = true);
    final error = await AuthState.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    setState(() => _sending = false);

    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    _sentEmail = email;
    AppToast.success(context, 'Password reset link sent.');
    _next();
  }

  Future<void> _resendResetLink() async {
    final email = _sentEmail.isNotEmpty
        ? _sentEmail
        : _emailController.text.trim();
    if (!_validEmail(email)) {
      AppToast.warning(context, 'Enter a valid email first.');
      return;
    }
    setState(() => _sending = true);
    final error = await AuthState.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    setState(() => _sending = false);

    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    AppToast.success(context, 'Reset link sent again.');
  }

  bool _validEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
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
                    onPressed: _back,
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
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => setState(() => _index = value),
                children: [
                  _ResetRequestStep(
                    controller: _emailController,
                    sending: _sending,
                    onNext: _sendResetLink,
                  ),
                  _ResetEmailSentStep(
                    email: _sentEmail,
                    sending: _sending,
                    onNext: _next,
                    onResend: _resendResetLink,
                  ),
                  _ResetSuccessStep(
                    email: _sentEmail,
                    onBackToSignIn: () => Navigator.pushReplacementNamed(
                      context,
                      CustomerAuthPage.routeName,
                    ),
                  ),
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
  final TextEditingController controller;
  final VoidCallback onNext;
  final bool sending;

  const _ResetRequestStep({
    required this.controller,
    required this.onNext,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "We'll email you a secure link to reset your password.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            hint: 'Email Address',
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: sending ? 'Sending...' : 'Send Reset Link',
            icon: Icons.email_outlined,
            onPressed: sending ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _ResetEmailSentStep extends StatelessWidget {
  final String email;
  final VoidCallback onNext;
  final VoidCallback onResend;
  final bool sending;

  const _ResetEmailSentStep({
    required this.email,
    required this.onNext,
    required this.onResend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    final shownEmail = email.trim().isEmpty ? 'your email' : email.trim();
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check your inbox',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'A reset link has been sent to $shownEmail.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'I have checked email',
            icon: Icons.mark_email_read_outlined,
            onPressed: onNext,
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: sending ? 'Resending...' : 'Resend Link',
            icon: Icons.refresh_rounded,
            isOutlined: true,
            onPressed: sending ? null : onResend,
          ),
        ],
      ),
    );
  }
}

class _ResetSuccessStep extends StatelessWidget {
  final String email;
  final VoidCallback onBackToSignIn;

  const _ResetSuccessStep({required this.email, required this.onBackToSignIn});

  @override
  Widget build(BuildContext context) {
    final shownEmail = email.trim().isEmpty ? 'your email' : email.trim();
    return _CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All Set', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Use the link from $shownEmail to set a new password, then sign in again.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Back to Sign in',
            icon: Icons.login_rounded,
            onPressed: onBackToSignIn,
          ),
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
