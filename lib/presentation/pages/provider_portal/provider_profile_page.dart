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
import 'provider_profession_page.dart';
import 'provider_verification_page.dart';
import 'provider_availability_page.dart';

class ProviderProfilePage extends StatefulWidget {
  static const String routeName = '/provider/profile';

  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  double _providerRating = 0.0;

  @override
  void initState() {
    super.initState();
    unawaited(_syncCompletedOrders());
    unawaited(_fetchRating());
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
            _ProviderHero(rating: _providerRating),
            const SizedBox(height: 16),
            Text(
              'Profile information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
              icon: Icons.calendar_month_outlined,
              label: 'Availability',
              onTap: () => Navigator.push(
                context,
                slideFadeRoute(const ProviderAvailabilityPage()),
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
              'General preferences',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
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
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
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
                        activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Switch to finder mode',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  ValueListenableBuilder<AppRole>(
                    valueListenable: AppRoleState.role,
                    builder: (context, role, _) {
                      return Switch(
                        value: role == AppRole.provider,
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
                            slideFadeRoute(const MainShellPage()),
                            (route) => false,
                          );
                        },
                        activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      );
                    },
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
  const _ProviderHero({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)],
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
              valueListenable: ProfileSettingsState.providerProfile,
              builder: (context, profile, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                        const SizedBox(width: 6),
                        ValueListenableBuilder<bool>(
                          valueListenable: ProfileSettingsState.providerVerified,
                          builder: (context, isVerified, _) {
                            if (!isVerified) return const SizedBox.shrink();
                            return const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 20,
                            );
                          },
                        ),
                      ],
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
                          rating.toStringAsFixed(1),
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
          ValueListenableBuilder<int>(
            valueListenable: ProfileSettingsState.providerCompletedOrders,
            builder: (context, completedOrders, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                      '$completedOrders completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
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
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 19),
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
