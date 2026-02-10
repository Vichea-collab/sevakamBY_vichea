import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProfileNotificationPage extends StatefulWidget {
  static const String routeName = '/profile/notification';

  const ProfileNotificationPage({super.key});

  @override
  State<ProfileNotificationPage> createState() =>
      _ProfileNotificationPageState();
}

class _ProfileNotificationPageState extends State<ProfileNotificationPage> {
  bool general = true;
  bool sound = false;
  bool vibrate = true;
  bool newService = false;
  bool payment = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final values = ProfileSettingsState.currentNotification;
    general = values.general;
    sound = values.sound;
    vibrate = values.vibrate;
    newService = values.newService;
    payment = values.payment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            10,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(title: 'Notification'),
              const SizedBox(height: 12),
              _SwitchTile(
                label: 'General notification',
                value: general,
                onChanged: (v) => setState(() => general = v),
              ),
              _SwitchTile(
                label: 'Sound',
                value: sound,
                onChanged: (v) => setState(() => sound = v),
              ),
              _SwitchTile(
                label: 'Vibrate',
                value: vibrate,
                onChanged: (v) => setState(() => vibrate = v),
              ),
              _SwitchTile(
                label: 'New Service',
                value: newService,
                onChanged: (v) => setState(() => newService = v),
              ),
              _SwitchTile(
                label: 'Payment',
                value: payment,
                onChanged: (v) => setState(() => payment = v),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _saving ? 'Saving...' : 'Save',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProfileSettingsState.saveCurrentNotifications(
      NotificationPreference(
        general: general,
        sound: sound,
        vibrate: vibrate,
        newService: newService,
        payment: payment,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    AppToast.success(context, 'Notification settings saved.');
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryLight,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
