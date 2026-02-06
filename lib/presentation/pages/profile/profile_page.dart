import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/pressable_scale.dart';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.splashStart, AppColors.splashEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      'My Profile',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const CircleAvatar(
                      radius: 36,
                      backgroundImage: AssetImage('assets/images/profile.jpg'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kimheng',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ActionTile(
                icon: Icons.edit,
                label: 'Edit Profile',
                onTap: () => Navigator.push(
                  context,
                  slideFadeRoute(const EditProfilePage()),
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.notifications_none,
                label: 'Notification',
                onTap: () => Navigator.push(
                  context,
                  slideFadeRoute(const ProfileNotificationPage()),
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.payment,
                label: 'Payment method',
                onTap: () => Navigator.push(
                  context,
                  slideFadeRoute(const PaymentPage()),
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.help_outline,
                label: 'Help & support',
                onTap: () => Navigator.push(
                  context,
                  slideFadeRoute(const HelpSupportPage()),
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.logout,
                label: 'Logout',
                textColor: AppColors.primary,
                onTap: () => _showLogoutDialog(context),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
                title: const Text('Change Profile to selling mode'),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(
        current: AppBottomTab.profile,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, size: 44, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Logout', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Are you sure to logout?', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Logout'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
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
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
