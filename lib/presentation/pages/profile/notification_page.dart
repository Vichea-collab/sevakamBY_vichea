import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';

class ProfileNotificationPage extends StatefulWidget {
  static const String routeName = '/profile/notification';

  const ProfileNotificationPage({super.key});

  @override
  State<ProfileNotificationPage> createState() => _ProfileNotificationPageState();
}

class _ProfileNotificationPageState extends State<ProfileNotificationPage> {
  bool general = true;
  bool sound = false;
  bool vibrate = true;
  bool newService = false;
  bool payment = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text('Notification', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 14),
              _SwitchTile(label: 'General notification', value: general, onChanged: (v) => setState(() => general = v)),
              _SwitchTile(label: 'Sound', value: sound, onChanged: (v) => setState(() => sound = v)),
              _SwitchTile(label: 'Vibrate', value: vibrate, onChanged: (v) => setState(() => vibrate = v)),
              _SwitchTile(label: 'New Service', value: newService, onChanged: (v) => setState(() => newService = v)),
              _SwitchTile(label: 'Payment', value: payment, onChanged: (v) => setState(() => payment = v)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(child: Text(label)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
