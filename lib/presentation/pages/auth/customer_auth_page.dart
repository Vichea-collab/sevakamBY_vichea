import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_flow.dart';
import 'provider_auth_page.dart';
import '../home/home_page.dart';

class CustomerAuthPage extends StatefulWidget {
  static const String routeName = '/auth/customer';

  const CustomerAuthPage({super.key});

  @override
  State<CustomerAuthPage> createState() => _CustomerAuthPageState();
}

class _CustomerAuthPageState extends State<CustomerAuthPage> {
  bool _isSignUp = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const _AuthHeader(
                title: 'Welcome to Sevakam',
                subtitle: 'Find trusted services near you',
              ),
              const SizedBox(height: AppSpacing.md),
              _AuthToggle(
                leftLabel: 'Become a Customer',
                rightLabel: 'Become a Service Provider',
                isLeftActive: true,
                onTapRight: () {
                  Navigator.pushReplacementNamed(
                    context,
                    ProviderAuthPage.routeName,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        _isSignUp ? 'Get Start With Us' : 'Welcome Back',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp
                          ? 'Enter your detail below'
                          : 'Enter your detail below',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.person_outline,
                          size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_isSignUp) ...[
                      Row(
                        children: const [
                          Expanded(child: AppTextField(hint: 'First Name')),
                          SizedBox(width: 12),
                          Expanded(child: AppTextField(hint: 'Last Name')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const AppTextField(hint: 'Enter Your Phone Number'),
                      const SizedBox(height: 12),
                    ],
                    const AppTextField(hint: 'Enter Your Email Address'),
                    const SizedBox(height: 12),
                    const AppTextField(hint: 'Enter Your Password', obscureText: true),
                    if (_isSignUp) ...[
                      const SizedBox(height: 12),
                      const AppTextField(
                        hint: 'Re-Enter Your Password',
                        obscureText: true,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: _isSignUp ? 'Sign up' : 'Sign in',
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        HomePage.routeName,
                      ),
                    ),
                    if (!_isSignUp) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          ForgotPasswordFlow.routeName,
                        ),
                        child: const Text('Forgot Your Password?'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Or Continue With'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _SocialButton(
                      label: 'Continue with Google',
                      borderColor: Color(0xFFE8EAED),
                      iconAsset: 'assets/images/google_icon.png',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? 'Sign in' : 'Sign up',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.handyman, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isLeftActive;
  final VoidCallback onTapRight;

  const _AuthToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeftActive,
    required this.onTapRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {},
          child: Text(
            leftLabel,
            style: TextStyle(
              color: isLeftActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onTapRight,
          child: Text(
            rightLabel,
            style: TextStyle(
              color: !isLeftActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color borderColor;
  final String? iconAsset;

  const _SocialButton({
    required this.label,
    required this.borderColor,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconAsset != null)
            Container(
              height: 20,
              width: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(iconAsset!, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
