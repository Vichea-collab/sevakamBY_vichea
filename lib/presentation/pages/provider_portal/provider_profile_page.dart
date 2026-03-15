import 'dart:async';

import 'package:flutter/material.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/utils/app_toast.dart';
import 'package:servicefinder/core/utils/page_transition.dart';
import 'package:servicefinder/presentation/state/app_role_state.dart';
import 'package:servicefinder/presentation/state/app_state.dart';
import 'package:servicefinder/presentation/state/auth_state.dart';
import 'package:servicefinder/presentation/state/order_state.dart';
import 'package:servicefinder/presentation/state/profile_image_state.dart';
import 'package:servicefinder/presentation/state/profile_settings_state.dart';
import 'package:servicefinder/presentation/widgets/app_dialog.dart';
import 'package:servicefinder/presentation/widgets/app_top_bar.dart';
import 'package:servicefinder/presentation/widgets/pressable_scale.dart';
import 'package:servicefinder/presentation/pages/auth/provider_auth_page.dart';
import 'package:servicefinder/presentation/pages/main_shell_page.dart';
import 'package:servicefinder/presentation/pages/profile/edit_profile_page.dart';
import 'package:servicefinder/presentation/pages/profile/help_support_page.dart';
import 'package:servicefinder/presentation/pages/profile/notification_page.dart';
import 'package:servicefinder/presentation/widgets/app_bottom_nav.dart';
import 'package:servicefinder/presentation/widgets/role_mode_card.dart';
import 'package:servicefinder/presentation/widgets/shimmer_loading.dart';
import 'provider_verification_page.dart';
import 'provider_availability_page.dart';
import 'subscription_page.dart';
import 'package:servicefinder/presentation/state/subscription_state.dart';
import 'package:servicefinder/domain/entities/subscription.dart';
import 'package:servicefinder/presentation/widgets/subscription_badge.dart';
import 'package:servicefinder/presentation/widgets/verified_badge.dart';

class ProviderProfilePage extends StatefulWidget {
  static const String routeName = '/provider/profile';

  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  double _providerRating = 0.0;
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

  Future<void> _fetchRating() async {
    final providerUid = AuthState.currentUser.value?.uid.trim() ?? '';
    if (providerUid.isEmpty) return;
    try {
      final summary = await OrderState.fetchProviderReviewSummary(
        providerUid: providerUid,
        limit: 1,
      );
      if (mounted) {
        setState(() {
          _providerRating = summary.averageRating;
        });
      }
    } catch (_) {}
  }

  Future<void> _syncCompletedOrders() async {
    await ProfileSettingsState.syncProviderCompletedOrdersFromBackend();
    final providerUid = AuthState.currentUser.value?.uid.trim() ?? '';
    if (providerUid.isEmpty) return;
    try {
      final summary = await OrderState.fetchProviderReviewSummary(
        providerUid: providerUid,
        limit: 1,
      );
      final current = ProfileSettingsState.providerCompletedOrders.value;
      final merged = summary.completedJobs > current
          ? summary.completedJobs
          : current;
      if (merged != current) {
        ProfileSettingsState.providerCompletedOrders.value = merged;
      }
    } catch (_) {
      // Keep current value from provider profile endpoint when summary fetch fails.
    }
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
              _ProviderHero(rating: _providerRating, loading: _loadingProfile),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'Business'),
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
                    icon: Icons.calendar_month_outlined,
                    label: 'Availability',
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const ProviderAvailabilityPage()),
                    ),
                  ),
                  _ActionDivider(),
                  _ActionTile(
                    icon: Icons.photo_library_outlined,
                    label: 'Portfolio Gallery',
                    onTap: () =>
                        Navigator.pushNamed(context, '/provider/portfolio'),
                  ),
                  _ActionDivider(),
                  _ActionTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Verification',
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const ProviderVerificationPage()),
                    ),
                  ),
                  _ActionDivider(),
                  _ActionTile(
                    icon: Icons.workspace_premium,
                    label: 'Subscription',
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const SubscriptionPage()),
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
                    icon: Icons.notifications_none_rounded,
                    label: 'Notification',
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const ProfileNotificationPage()),
                    ),
                  ),
                  _ActionDivider(),
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
                isProvider: true,
                isSwitching: _switchingRole,
                onSwitch: _switchingRole ? null : _switchToFinder,
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
    await Future.wait<void>([
      ProfileSettingsState.syncRoleProfileFromBackend(isProvider: true),
      _syncCompletedOrders(),
      _fetchRating(),
      SubscriptionState.fetchStatus(),
    ]);
    if (mounted) {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _switchToFinder() async {
    if (_switchingRole) return;
    setState(() => _switchingRole = true);
    final error = await AuthState.switchRole(toProvider: false);
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
    AppRoleState.setProvider(true);
    Navigator.pushNamedAndRemoveUntil(
      context,
      ProviderAuthPage.routeName,
      (route) => false,
    );
  }
}

class _ProviderHero extends StatelessWidget {
  final double rating;
  final bool loading;

  const _ProviderHero({required this.rating, required this.loading});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ProfileSettingsState.providerProfile,
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
                width: 88,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              if (showLoading)
                const _ProviderHeroLoading()
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                profile.name.trim().isEmpty
                                    ? 'Provider'
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
                                  'Provider',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    ProfileSettingsState.providerVerified,
                                builder: (context, isVerified, _) {
                                  if (!isVerified) {
                                    return const SizedBox.shrink();
                                  }
                                  return const VerifiedBadge(size: 11);
                                },
                              ),
                              ValueListenableBuilder<SubscriptionStatus>(
                                valueListenable: SubscriptionState.status,
                                builder: (context, status, _) {
                                  if (status.tier == SubscriptionTier.basic) {
                                    return const SizedBox.shrink();
                                  }
                                  return SubscriptionBadge(tier: status.tier);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetricPill(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                text: rating.toStringAsFixed(1),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: ProfileSettingsState
                                    .providerCompletedOrders,
                                builder: (context, completedOrders, _) {
                                  return _MetricPill(
                                    icon: Icons.task_alt_rounded,
                                    iconColor: AppColors.success,
                                    text: '$completedOrders completed',
                                  );
                                },
                              ),
                            ],
                          ),
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

class _ProviderHeroLoading extends StatelessWidget {
  const _ProviderHeroLoading();

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
              ShimmerPlaceholder(width: 160, height: 24, borderRadius: 999),
              SizedBox(height: 10),
              ShimmerPlaceholder(width: 180, height: 20, borderRadius: 999),
              SizedBox(height: 12),
              ShimmerPlaceholder(width: 220, height: 32, borderRadius: 999),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _MetricPill({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
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
