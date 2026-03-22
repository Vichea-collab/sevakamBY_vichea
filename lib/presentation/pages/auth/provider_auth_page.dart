import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/location_options.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/responsive.dart';
import '../../state/app_role_state.dart';
import '../../state/auth_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/auth_social_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_flow.dart';
import 'customer_auth_page.dart';
import '../main_shell_page.dart';

class ProviderAuthPage extends StatefulWidget {
  static const String routeName = '/auth/provider';

  const ProviderAuthPage({super.key});

  @override
  State<ProviderAuthPage> createState() => _ProviderAuthPageState();
}

class _ProviderAuthPageState extends State<ProviderAuthPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  bool _isSignUp = true;
  bool _authLoading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List<String> get _districtsForSelectedCity {
    return LocationOptions.districtsForCity(_cityController.text.trim());
  }

  @override
  void initState() {
    super.initState();
    _cityController.text = LocationOptions.defaultCity;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(rs.space(AppSpacing.lg)),
          child: Column(
            children: [
              const _AuthHeader(
                title: 'Join as a Provider',
                subtitle: 'Offer as a provider and grow faster',
              ),
              SizedBox(height: rs.space(AppSpacing.md)),
              _AuthToggle(
                leftLabel: 'Become a Customer',
                rightLabel: 'Become a Provider',
                isLeftActive: false,
                onTapLeft: () {
                  AppRoleState.setProvider(false);
                  Navigator.pushReplacementNamed(
                    context,
                    CustomerAuthPage.routeName,
                  );
                },
              ),
              SizedBox(height: rs.space(AppSpacing.md)),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(rs.space(AppSpacing.lg)),
                  child: Column(
                    children: [
                      Text(
                        _isSignUp
                            ? 'Provide the Best Services'
                            : 'Welcome Back',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: rs.space(4)),
                      Text(
                        'Enter your details below',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: rs.space(AppSpacing.md)),
                      CircleAvatar(
                        radius: rs.dimension(30),
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.badge_outlined,
                          size: rs.icon(28),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: rs.space(AppSpacing.md)),
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
                                  SizedBox(width: rs.space(12)),
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
                              SizedBox(height: rs.space(12)),
                              AppTextField(
                                hint: 'Phone Number',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: _validatePhone,
                              ),
                              SizedBox(height: rs.space(12)),
                            ],
                            AppTextField(
                              hint: 'Enter Your Email Address',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                            ),
                            SizedBox(height: rs.space(12)),
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
                              SizedBox(height: rs.space(12)),
                              AppTextField(
                                hint: 'Re-Enter Your Password',
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.next,
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
                              SizedBox(height: rs.space(12)),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      hint: 'Select your City/Province',
                                      controller: _cityController,
                                      readOnly: true,
                                      validator: _validateRequired(
                                        'City/Province',
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: rs.space(12)),
                                  Expanded(
                                    child: AppTextField(
                                      hint: 'Select your District',
                                      controller: _districtController,
                                      readOnly: true,
                                      onTap: _pickDistrict,
                                      suffixIcon: const Icon(
                                        Icons.keyboard_arrow_down,
                                      ),
                                      validator: _validateRequired('District'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: rs.space(AppSpacing.md)),
                      PrimaryButton(
                        label: _authLoading
                            ? (_isSignUp ? 'Signing up...' : 'Signing in...')
                            : (_isSignUp ? 'Sign up' : 'Sign in'),
                        onPressed: _authLoading ? null : _submitEmailAuth,
                      ),
                      if (!_isSignUp) ...[
                        SizedBox(height: rs.space(12)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            ForgotPasswordFlow.routeName,
                          ),
                          child: const Text('Forgot Your Password?'),
                        ),
                      ],
                      SizedBox(height: rs.space(AppSpacing.md)),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: rs.space(8),
                            ),
                            child: Text(
                              'Or Continue With',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      SizedBox(height: rs.space(AppSpacing.md)),
                      AuthSocialButton(
                        label: 'Continue with Google',
                        iconAsset: 'assets/images/google_icon.png',
                        isLoading: _googleLoading,
                        onPressed: _continueWithGoogle,
                      ),
                      SizedBox(height: rs.space(AppSpacing.md)),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: rs.space(4),
                        runSpacing: rs.space(4),
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
      isProvider: true,
      registerIfMissing: _isSignUp,
    );
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    AppRoleState.setProvider(true);
    MainShellPage.activeTab.value = AppBottomTab.home;
    AppToast.success(context, 'Signed in successfully.');
    Navigator.pushReplacementNamed(context, MainShellPage.routeName);
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
        isProvider: true,
        fullName: _fullName(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        city: _providerCity(),
      );
    } else {
      error = await AuthState.signInWithEmailPassword(
        isProvider: true,
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

    AppRoleState.setProvider(true);
    MainShellPage.activeTab.value = AppBottomTab.home;
    AppToast.success(
      context,
      _isSignUp ? 'Account created successfully.' : 'Signed in successfully.',
    );
    Navigator.pushReplacementNamed(context, MainShellPage.routeName);
  }

  String _fullName() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    return [first, last].where((part) => part.isNotEmpty).join(' ').trim();
  }

  String _providerCity() {
    final city = _cityController.text.trim();
    final district = _districtController.text.trim();
    return [city, district].where((item) => item.isNotEmpty).join(', ');
  }

  Future<void> _pickDistrict() async {
    if (_cityController.text.trim().isEmpty) {
      _cityController.text = LocationOptions.defaultCity;
    }

    final options = _districtsForSelectedCity;
    if (options.isEmpty) {
      AppToast.warning(context, 'No district options available for this city.');
      return;
    }

    final picked = await _showOptionSheet(
      title: 'Select your district',
      options: options,
      selected: _districtController.text.trim(),
    );
    if (picked == null) return;
    setState(() => _districtController.text = picked);
  }

  Future<String?> _showOptionSheet({
    required String title,
    required List<String> options,
    required String selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final active = option == selected;
                      return ListTile(
                        title: Text(option),
                        trailing: active
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, option),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final rs = context.rs;

    return Row(
      children: [
        Container(
          height: rs.dimension(52),
          width: rs.dimension(52),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(rs.radius(16)),
          ),
          child: Icon(
            Icons.store_mall_directory,
            color: Colors.white,
            size: rs.icon(24),
          ),
        ),
        SizedBox(width: rs.space(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: rs.space(4)),
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
  final VoidCallback? onTapLeft;

  const _AuthToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeftActive,
    this.onTapLeft,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onTapLeft,
            child: Text(
              leftLabel,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: rs.text(13, minFactor: 0.96, maxFactor: 1.0),
                color: isLeftActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        SizedBox(width: rs.space(8)),
        Expanded(
          child: TextButton(
            onPressed: () {},
            child: Text(
              rightLabel,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: rs.text(13, minFactor: 0.96, maxFactor: 1.0),
                color: !isLeftActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
