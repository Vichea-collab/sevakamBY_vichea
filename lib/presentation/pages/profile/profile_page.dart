import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/responsive.dart';
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
    final rs = context.rs;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: rs.only(left: 18, top: 12, right: 18, bottom: 18),
            children: [
              AppTopBar(
                title: 'My Profile',
                showBack: true,
                onBack: () => MainShellPage.activeTab.value = AppBottomTab.home,
              ),
              rs.gapH(10),
              _ProfileHero(loading: _loadingProfile),
              rs.gapH(16),
              const _SectionLabel(text: 'Account'),
              rs.gapH(10),
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
              rs.gapH(16),
              const _SectionLabel(text: 'Preferences'),
              rs.gapH(10),
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
              rs.gapH(16),
              const _SectionLabel(text: 'Workspace'),
              rs.gapH(10),
              RoleModeCard(
                isProvider: false,
                isSwitching: _switchingRole,
                onSwitch: _switchingRole ? null : _switchToProvider,
              ),
              rs.gapH(16),
              const _SectionLabel(text: 'Session'),
              rs.gapH(10),
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
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ValueListenableBuilder(
      valueListenable: ProfileSettingsState.finderProfile,
      builder: (context, profile, _) {
        final showLoading =
            loading &&
            profile.name.trim().isEmpty &&
            profile.email.trim().isEmpty &&
            profile.phoneNumber.trim().isEmpty;
        return Container(
          padding: rs.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(rs.radius(20)),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
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
                height: rs.dimension(6),
                width: rs.dimension(72),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              rs.gapH(14),
              if (showLoading)
                const _ProfileHeroLoading()
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: rs.all(3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A2840)
                            : const Color(0xFFEAF1FF),
                        shape: BoxShape.circle,
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: ProfileImageState.listenable,
                        builder: (context, value, child) {
                          final image = ProfileImageState.avatarProvider();
                          return CircleAvatar(
                            radius: rs.dimension(34),
                            backgroundColor: isDark
                                ? const Color(0xFF111C2D)
                                : const Color(0xFFF7FAFF),
                            backgroundImage: image,
                            child: image == null
                                ? Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: rs.icon(34),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                    rs.gapW(14),
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
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              Container(
                                padding: rs.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.primary.withValues(
                                          alpha: 0.18,
                                        )
                                      : const Color(0xFFEAF1FF),
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
                          rs.gapH(4),
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
                            rs.gapH(10),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: rs.icon(16),
                                  color: AppColors.primary,
                                ),
                                rs.gapW(6),
                                Text(
                                  profile.city.trim(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.primaryLight,
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
    final rs = context.rs;
    return Row(
      children: [
        ShimmerPlaceholder.circular(size: rs.dimension(74)),
        rs.gapW(14),
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
    final rs = context.rs;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rs.radius(14)),
        child: Padding(
          padding: rs.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              _ActionIcon(icon: icon),
              rs.gapW(12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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
    final rs = context.rs;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: rs.space(0.6),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(rs.radius(18)),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.24
                  : 0.07,
            ),
            blurRadius: 20,
            spreadRadius: -12,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: rs.symmetric(horizontal: 12, vertical: 8),
      child: Column(children: children),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor);
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;

  const _ActionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return Container(
      height: rs.dimension(38),
      width: rs.dimension(38),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(rs.radius(12)),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: rs.icon(19),
      ),
    );
  }
}

class _DangerActionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerActionCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rs.radius(18)),
        child: Container(
          width: double.infinity,
          padding: rs.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(rs.radius(18)),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.24
                      : 0.07,
                ),
                blurRadius: 20,
                spreadRadius: -12,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: rs.dimension(40),
                width: rs.dimension(40),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(rs.radius(12)),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: rs.icon(20),
                ),
              ),
              rs.gapW(12),
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
