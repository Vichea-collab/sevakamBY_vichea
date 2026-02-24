import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_calendar_picker.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../state/app_role_state.dart';
import '../../state/profile_image_state.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class EditProfilePage extends StatefulWidget {
  static const String routeName = '/profile/edit';

  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const int _maxPhotoBytes = 450 * 1024;

  final ImagePicker _picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _saving = false;
  bool _photoChanged = false;
  String _selectedPhotoDataUrl = '';

  bool get _isProvider => AppRoleState.isProvider;

  @override
  void initState() {
    super.initState();
    final profile = ProfileSettingsState.currentProfile;
    _setForm(profile);
    _selectedPhotoDataUrl = profile.photoUrl.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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
                  final image = ProfileImageState.avatarProvider();
                  return InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFFEAF1FF),
                          backgroundImage: image,
                          child: image == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 40,
                                )
                              : null,
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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _LabeledField(
                      label: 'Name',
                      hint: 'Enter your name',
                      controller: _nameController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _LabeledField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (email.isEmpty) return 'Email is required';
                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!regex.hasMatch(email)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _LabeledField(
                      label: 'Date of Birth',
                      hint: 'DD/MM/YYYY',
                      controller: _dobController,
                      readOnly: true,
                      suffixIcon: Icons.calendar_month_outlined,
                      onTap: _pickDateOfBirth,
                    ),
                    const SizedBox(height: 10),
                    _LabeledField(
                      label: 'Country',
                      hint: 'Enter country',
                      controller: _countryController,
                    ),
                    const SizedBox(height: 10),
                    _LabeledField(
                      label: 'Phone number',
                      hint: '+855 ...',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _LabeledField(
                      label: 'City',
                      hint: 'Enter city',
                      controller: _cityController,
                    ),
                    if (_isProvider) ...[
                      const SizedBox(height: 10),
                      _LabeledField(
                        label: 'Bio',
                        hint: 'Tell clients about your service',
                        controller: _bioController,
                        minLines: 3,
                        maxLines: 5,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _saving ? 'Saving...' : 'Save',
                onPressed: _saving ? null : _saveProfile,
              ),
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
                    _photoChanged = true;
                    _selectedPhotoDataUrl = '';
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
    if (bytes.isEmpty) {
      if (!mounted) return;
      AppToast.warning(context, 'Selected image is empty.');
      return;
    }
    if (bytes.lengthInBytes > _maxPhotoBytes) {
      if (!mounted) return;
      AppToast.warning(
        context,
        'Image is too large. Please select an image under 450 KB.',
      );
      return;
    }
    if (!mounted) return;
    final extension = _extensionFromName(picked.name);
    final mimeType = _mimeTypeFromExtension(extension);
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
    ProfileImageState.setCustomAvatar(bytes);
    _photoChanged = true;
    _selectedPhotoDataUrl = dataUrl;
  }

  void _setForm(ProfileFormData profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _dobController.text = profile.dateOfBirth;
    _countryController.text = profile.country;
    _phoneController.text = profile.phoneNumber;
    _cityController.text = profile.city;
    _bioController.text = profile.bio;
  }

  Future<void> _pickDateOfBirth() async {
    final today = DateTime.now();
    final initial =
        _tryParseDob(_dobController.text) ??
        DateTime(today.year - 18, today.month, today.day);
    final picked = await showAppCalendarDatePicker(
      context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(today.year, today.month, today.day),
      helpText: 'Choose date of birth',
      confirmText: 'Select',
    );
    if (picked == null) return;
    _dobController.text = _formatDob(picked);
  }

  DateTime? _tryParseDob(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final iso = DateTime.tryParse(value);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  String _formatDob(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final payload = ProfileFormData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      country: _countryController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      bio: _bioController.text.trim(),
      photoUrl: _photoChanged
          ? _selectedPhotoDataUrl.trim()
          : ProfileSettingsState.currentProfile.photoUrl.trim(),
    );

    setState(() => _saving = true);
    await ProfileSettingsState.saveCurrentProfile(payload);
    if (!mounted) return;
    _photoChanged = false;
    _selectedPhotoDataUrl = payload.photoUrl;
    setState(() => _saving = false);
    AppToast.success(context, 'Profile saved successfully.');
  }

  String _extensionFromName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot >= fileName.length - 1) return 'jpg';
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _mimeTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
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
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

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
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: AppColors.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }
}
