import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../state/app_role_state.dart';
import '../../state/auth_state.dart';
import '../../state/profile_image_state.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../auth/provider_auth_page.dart';
import '../home/home_page.dart';
import '../profile/edit_profile_page.dart';
import '../profile/help_support_page.dart';
import '../profile/notification_page.dart';
import '../profile/payment_page.dart';
import 'provider_profession_page.dart';
import 'provider_upgrade_page.dart';
import 'provider_verification_page.dart';

class ProviderProfilePage extends StatelessWidget {
  static const String routeName = '/provider/profile';

  const ProviderProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          children: [
            const AppTopBar(title: 'My Profile', showBack: false),
            const SizedBox(height: 10),
            const _ProviderHero(),
            const SizedBox(height: 16),
            Text(
              'Profile information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
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
              icon: Icons.work_outline_rounded,
              label: 'Profession',
              onTap: () => Navigator.push(
                context,
                slideFadeRoute(const ProviderProfessionPage()),
              ),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.verified_user_outlined,
              label: 'Verification',
              onTap: () => Navigator.push(
                context,
                slideFadeRoute(const ProviderVerificationPage()),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Subscription & payments',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.credit_card_outlined,
              label: 'Payment method',
              onTap: () =>
                  Navigator.push(context, slideFadeRoute(const PaymentPage())),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Upgrade',
              onTap: () => Navigator.push(
                context,
                slideFadeRoute(const ProviderUpgradePage()),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'General preferences',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
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
              icon: Icons.support_agent_outlined,
              label: 'Help & support',
              onTap: () => Navigator.push(
                context,
                slideFadeRoute(const HelpSupportPage()),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Switch to finder mode',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: (value) async {
                      if (value) return;
                      final error = await AuthState.switchRole(
                        toProvider: false,
                      );
                      if (!context.mounted) return;
                      if (error != null) {
                        AppToast.warning(context, error);
                        return;
                      }
                      Navigator.of(context).pushAndRemoveUntil(
                        slideFadeRoute(const HomePage()),
                        (route) => false,
                      );
                    },
                    activeTrackColor: AppColors.primaryLight,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PressableScale(
              onTap: () => _showLogoutDialog(context),
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 55),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Logout',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

    await AuthState.signOut();
    if (!context.mounted) return;
    AppRoleState.setProvider(true);
    Navigator.pushNamedAndRemoveUntil(
      context,
      ProviderAuthPage.routeName,
      (route) => false,
    );
  }
}

class _ProviderHero extends StatelessWidget {
  const _ProviderHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5CC7), Color(0xFF616DEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33005BBB),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 235),
              shape: BoxShape.circle,
            ),
            child: ValueListenableBuilder(
              valueListenable: ProfileImageState.listenable,
              builder: (context, value, child) {
                final image = ProfileImageState.avatarProvider();
                return CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFEAF1FF),
                  backgroundImage: image,
                  child: image == null
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 34,
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: ProfileSettingsState.providerProfile,
              builder: (context, profile, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.name.trim().isEmpty
                          ? 'Provider'
                          : profile.name.trim(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD88A)),
                      ),
                      child: Text(
                        profile.city.trim().isEmpty
                            ? 'Provider'
                            : profile.city.trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8A5A00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '3.9',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0F8E3F)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  '56 completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                child: Icon(icon, color: AppColors.primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
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
