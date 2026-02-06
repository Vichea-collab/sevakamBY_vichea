import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';

class EditProfilePage extends StatelessWidget {
  static const String routeName = '/profile/edit';

  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                  Text('Edit Profile', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              const Center(
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: AssetImage('assets/images/profile.jpg'),
                ),
              ),
              const SizedBox(height: 16),
              const _LabeledField(label: 'Name', hint: 'Kimheng'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Email', hint: 'kimheng@gmail.com'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Date of Birth', hint: '28/11/2005'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Country', hint: 'Cambodia'),
              const SizedBox(height: 10),
              const _LabeledField(label: 'Phone number', hint: '+88 123456'),
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

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;

  const _LabeledField({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
