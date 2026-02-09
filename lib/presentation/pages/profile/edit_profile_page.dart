import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../state/profile_image_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class EditProfilePage extends StatefulWidget {
  static const String routeName = '/profile/edit';

  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            10,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              const AppTopBar(title: 'Edit Profile'),
              const SizedBox(height: 12),
              ValueListenableBuilder(
                valueListenable: ProfileImageState.listenable,
                builder: (context, value, child) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundImage: ProfileImageState.avatarProvider(),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              ProfileImageState.hasCustomAvatar
                                  ? Icons.swap_horiz_rounded
                                  : Icons.edit,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showPhotoOptions,
                child: Text(
                  ProfileImageState.hasCustomAvatar
                      ? 'Change or use default photo'
                      : 'Upload profile photo',
                ),
              ),
              const SizedBox(height: 8),
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
              PrimaryButton(label: 'Save', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _PhotoOptionTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Upload from gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery();
                  },
                ),
                _PhotoOptionTile(
                  icon: Icons.person_outline,
                  label: 'Use default profile',
                  onTap: () {
                    ProfileImageState.useDefaultAvatar();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    ProfileImageState.setCustomAvatar(bytes);
  }
}

class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            ),
          ],
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
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
