import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../state/app_role_state.dart';
import '../../state/app_state.dart';
import '../../state/auth_state.dart';
import '../../state/profile_image_state.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/role_mode_card.dart';
import '../auth/customer_auth_page.dart';
import '../main_shell_page.dart';
import '../../widgets/app_bottom_nav.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'notification_page.dart';

class ProfilePage extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _switchingRole = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          children: [
            AppTopBar(
              title: 'My Profile',
              showBack: true,
              onBack: () => MainShellPage.activeTab.value = AppBottomTab.home,
            ),
            const SizedBox(height: 10),
            const _ProfileHero(),
            const SizedBox(height: 16),
            Text(
              'Account information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
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
            const SizedBox(height: 16),
            Text(
              'General preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.dark_mode_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dark Mode',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppState.themeMode,
                    builder: (context, themeMode, _) {
                      return Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) => AppState.toggleTheme(),
                        activeTrackColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RoleModeCard(
              isProvider: false,
              isSwitching: _switchingRole,
              onSwitch: _switchingRole ? null : _switchToProvider,
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3),
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
    );
  }

  Future<void> _switchToProvider() async {
    if (_switchingRole) return;
    setState(() => _switchingRole = true);
    final error = await AuthState.switchRole(toProvider: true);
    if (!mounted) return;
    setState(() => _switchingRole = false);
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      slideFadeRoute(const MainShellPage()),
      (route) => false,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
              valueListenable: ProfileSettingsState.finderProfile,
              builder: (context, profile, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.name.trim().isEmpty
                          ? 'Customer'
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
                    const SizedBox(height: 4),
                    Text(
                      profile.phoneNumber.trim().isEmpty
                          ? profile.email
                          : profile.phoneNumber,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
