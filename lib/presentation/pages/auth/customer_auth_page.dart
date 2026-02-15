import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../state/app_role_state.dart';
import '../../state/auth_state.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSignUp = true;
  bool _authLoading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
                        child: const Icon(
                          Icons.person_outline,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isSignUp) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      hint: 'First Name',
                                      controller: _firstNameController,
                                      textInputAction: TextInputAction.next,
                                      validator: _validateRequired(
                                        'First name',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      hint: 'Last Name',
                                      controller: _lastNameController,
                                      textInputAction: TextInputAction.next,
                                      validator: _validateRequired('Last name'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                hint: 'Enter Your Phone Number',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 12),
                            ],
                            AppTextField(
                              hint: 'Enter Your Email Address',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              hint: 'Enter Your Password',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                onPressed: () => setState(() {
                                  _obscurePassword = !_obscurePassword;
                                }),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            if (_isSignUp) ...[
                              const SizedBox(height: 12),
                              AppTextField(
                                hint: 'Re-Enter Your Password',
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  }),
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                                validator: _validateConfirmPassword,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: _authLoading
                            ? (_isSignUp ? 'Signing up...' : 'Signing in...')
                            : (_isSignUp ? 'Sign up' : 'Sign in'),
                        onPressed: _authLoading ? null : _submitEmailAuth,
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
                      _SocialButton(
                        label: 'Continue with Google',
                        borderColor: Color(0xFFE8EAED),
                        iconAsset: 'assets/images/google_icon.png',
                        onPressed: _googleLoading ? null : _continueWithGoogle,
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

  Future<void> _continueWithGoogle() async {
    setState(() => _googleLoading = true);
    final error = await AuthState.signInWithGoogle(
      isProvider: false,
      registerIfMissing: _isSignUp,
    );
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    AppRoleState.setProvider(false);
    AppToast.success(context, 'Signed in successfully.');
    Navigator.pushReplacementNamed(context, HomePage.routeName);
  }

  Future<void> _submitEmailAuth() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      AppToast.warning(context, 'Please complete required fields.');
      return;
    }

    setState(() => _authLoading = true);
    String? error;
    if (_isSignUp) {
      error = await AuthState.signUpWithEmailPassword(
        isProvider: false,
        fullName: _fullName(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );
    } else {
      error = await AuthState.signInWithEmailPassword(
        isProvider: false,
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() => _authLoading = false);

    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    AppRoleState.setProvider(false);
    AppToast.success(
      context,
      _isSignUp ? 'Account created successfully.' : 'Signed in successfully.',
    );
    Navigator.pushReplacementNamed(context, HomePage.routeName);
  }

  String _fullName() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    return [first, last].where((part) => part.isNotEmpty).join(' ').trim();
  }

  String? Function(String?) _validateRequired(String label) {
    return (value) {
      if ((value ?? '').trim().isEmpty) {
        return '$label is required';
      }
      return null;
    };
  }

  String? _validatePhone(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Phone number is required';
    if (raw.length < 8) return 'Phone number is too short';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Invalid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Minimum 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isSignUp) return null;
    final confirm = value ?? '';
    if (confirm.isEmpty) return 'Confirm password is required';
    if (confirm != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthHeader({required this.title, required this.subtitle});

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
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
              color: !isLeftActive
                  ? AppColors.primary
                  : AppColors.textSecondary,
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
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.borderColor,
    this.iconAsset,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
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
