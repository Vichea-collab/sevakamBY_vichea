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
import '../../widgets/shimmer_loading.dart';
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
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_handleRefresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            children: [
              AppTopBar(
                title: 'My Profile',
                showBack: true,
                onBack: () => MainShellPage.activeTab.value = AppBottomTab.home,
              ),
              const SizedBox(height: 10),
              _ProfileHero(loading: _loadingProfile),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'Account'),
              const SizedBox(height: 10),
              _SectionCard(
                children: [
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const EditProfilePage()),
                    ),
                  ),
                  _ActionDivider(),
                  _ActionTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notification',
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const ProfileNotificationPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'Preferences'),
              const SizedBox(height: 10),
              _SectionCard(
                children: [
                  _ActionTile(
                    icon: Icons.support_agent_outlined,
                    label: 'Help & support',
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const HelpSupportPage()),
                    ),
                  ),
                  _ActionDivider(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        _ActionIcon(icon: Icons.dark_mode_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dark Mode',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
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
                              activeThumbColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'Workspace'),
              const SizedBox(height: 10),
              RoleModeCard(
                isProvider: false,
                isSwitching: _switchingRole,
                onSwitch: _switchingRole ? null : _switchToProvider,
              ),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'Session'),
              const SizedBox(height: 10),
              _DangerActionCard(
                label: 'Logout',
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() => _loadingProfile = true);
    }
    await ProfileSettingsState.syncRoleProfileFromBackend(isProvider: false);
    if (mounted) {
      setState(() => _loadingProfile = false);
    }
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
  final bool loading;

  const _ProfileHero({required this.loading});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ProfileSettingsState.finderProfile,
      builder: (context, profile, _) {
        final showLoading =
            loading &&
            profile.name.trim().isEmpty &&
            profile.email.trim().isEmpty &&
            profile.phoneNumber.trim().isEmpty;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDE7F5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110F172A),
                blurRadius: 20,
                spreadRadius: -12,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                width: 72,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              if (showLoading)
                const _ProfileHeroLoading()
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        shape: BoxShape.circle,
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: ProfileImageState.listenable,
                        builder: (context, value, child) {
                          final image = ProfileImageState.avatarProvider();
                          return CircleAvatar(
                            radius: 34,
                            backgroundColor: const Color(0xFFF7FAFF),
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                profile.name.trim().isEmpty
                                    ? 'Customer'
                                    : profile.name.trim(),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF1FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Finder',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.phoneNumber.trim().isEmpty
                                ? profile.email
                                : profile.phoneNumber,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (profile.city.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  profile.city.trim(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeroLoading extends StatelessWidget {
  const _ProfileHeroLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerPlaceholder.circular(size: 74),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerPlaceholder(width: 64, height: 24, borderRadius: 999),
              SizedBox(height: 10),
              ShimmerPlaceholder(width: 150, height: 24, borderRadius: 999),
              SizedBox(height: 8),
              ShimmerPlaceholder(width: 180, height: 14, borderRadius: 999),
            ],
          ),
        ),
      ],
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _ActionIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 20,
            spreadRadius: -12,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: children),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.divider);
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;

  const _ActionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 19),
    );
  }
}

class _DangerActionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerActionCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110F172A),
                blurRadius: 20,
                spreadRadius: -12,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }
}
