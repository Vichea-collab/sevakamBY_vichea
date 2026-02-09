import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transition.dart';
import '../../state/app_role_state.dart';
import '../../state/profile_image_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../auth/customer_auth_page.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'notification_page.dart';
import 'payment_page.dart';

class ProfilePage extends StatelessWidget {
  static const String routeName = '/profile';

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const AppTopBar(title: 'Profile', showBack: false),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProfileHero(),
                    const SizedBox(height: 20),
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      onTap: () => Navigator.push(
                        context,
                        slideFadeRoute(const EditProfilePage()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notification',
                      onTap: () => Navigator.push(
                        context,
                        slideFadeRoute(const ProfileNotificationPage()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.credit_card_outlined,
                      label: 'Payment method',
                      onTap: () => Navigator.push(
                        context,
                        slideFadeRoute(const PaymentPage()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.support_agent_outlined,
                      label: 'Help & support',
                      onTap: () => Navigator.push(
                        context,
                        slideFadeRoute(const HelpSupportPage()),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Change Profile to selling mode',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Switch(
                            value: false,
                            onChanged: (enabled) {
                              if (!enabled) return;
                              AppRoleState.setProvider(true);
                              Navigator.pushReplacementNamed(
                                context,
                                '/provider/home',
                              );
                            },
                            activeTrackColor: AppColors.primaryLight,
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    PressableScale(
                      onTap: () => _showLogoutDialog(context),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showLogoutDialog(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 55),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Logout',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.profile),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final shouldLogout = await showAppConfirmDialog(
      context: context,
      icon: Icons.logout_rounded,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Stay Logged In',
      tone: AppDialogTone.danger,
    );
    if (shouldLogout != true || !context.mounted) return;

    AppRoleState.setProvider(false);
    Navigator.pushNamedAndRemoveUntil(
      context,
      CustomerAuthPage.routeName,
      (route) => false,
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.splashStart, AppColors.splashEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26005BBB),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 220),
              shape: BoxShape.circle,
            ),
            child: ValueListenableBuilder(
              valueListenable: ProfileImageState.listenable,
              builder: (context, value, child) {
                return CircleAvatar(
                  radius: 34,
                  backgroundImage: ProfileImageState.avatarProvider(),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eang Kimheng',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
