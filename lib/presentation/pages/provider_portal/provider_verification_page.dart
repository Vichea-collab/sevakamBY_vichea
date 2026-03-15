import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/firebase/firebase_storage_service.dart';
import '../../../core/utils/app_toast.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProviderVerificationPage extends StatefulWidget {
  static const String routeName = '/provider/verification';

  const ProviderVerificationPage({super.key});

  @override
  State<ProviderVerificationPage> createState() =>
      _ProviderVerificationPageState();
}

class _ProviderVerificationPageState extends State<ProviderVerificationPage> {
  String? _idFrontPath;
  String? _idBackPath;
  bool _submitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    unawaited(ProfileSettingsState.syncProviderProfessionFromBackend());
  }

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        if (isFront) {
          _idFrontPath = picked.path;
        } else {
          _idBackPath = picked.path;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_idFrontPath == null || _idBackPath == null) {
      AppToast.warning(
        context,
        'Please upload both front and back of your ID.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final frontBytes = await XFile(_idFrontPath!).readAsBytes();
      final backBytes = await XFile(_idBackPath!).readAsBytes();
      final frontUrl = await _uploadKycSide(
        bytes: frontBytes,
        localPath: _idFrontPath!,
        side: 'front',
      );
      final backUrl = await _uploadKycSide(
        bytes: backBytes,
        localPath: _idBackPath!,
        side: 'back',
      );
      if (frontUrl == null || backUrl == null) {
        throw Exception('upload_failed');
      }
      await ProfileSettingsState.submitProviderVerification(
        idFrontUrl: frontUrl,
        idBackUrl: backUrl,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.warning(context, 'Unable to submit verification right now.');
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    AppToast.success(
      context,
      'Verification documents submitted. Your KYC is now pending review.',
    );
    Navigator.pop(context);
  }

  Future<String?> _uploadKycSide({
    required Uint8List bytes,
    required String localPath,
    required String side,
  }) {
    final extension = _fileExtension(localPath);
    return FirebaseStorageService.uploadProviderKycDocument(
      bytes,
      side: side,
      extension: extension,
    );
  }

  String _fileExtension(String path) {
    final normalized = path.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) return 'jpg';
    return normalized.substring(dotIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(title: 'Provider Verification'),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: ProfileSettingsState.providerKycStatus,
                builder: (context, status, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: ProfileSettingsState.providerVerified,
                    builder: (context, verified, _) {
                      return _VerificationStatusCard(
                        status: status,
                        verified: verified,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Upload your National ID or Passport so admin can review your account and unlock the verified badge.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _UploadBox(
                      label: 'Front of ID',
                      path: _idFrontPath,
                      onTap: () => _pickImage(true),
                    ),
                    const SizedBox(height: 16),
                    _UploadBox(
                      label: 'Back of ID',
                      path: _idBackPath,
                      onTap: () => _pickImage(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _submitting ? 'Submitting...' : 'Submit for Review',
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onTap;

  const _UploadBox({required this.label, this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 22,
            spreadRadius: -12,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 176,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider),
              ),
              child: path != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(File(path!), fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to upload',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationStatusCard extends StatelessWidget {
  final String status;
  final bool verified;

  const _VerificationStatusCard({required this.status, required this.verified});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final resolvedStatus = verified
        ? 'approved'
        : (normalized.isEmpty ? 'unverified' : normalized);
    final tone = switch (resolvedStatus) {
      'approved' => const (
        bg: Color(0xFFE9FDF4),
        fg: Color(0xFF15803D),
        icon: Icons.verified_rounded,
        label: 'Approved',
        message:
            'Your account is verified and visible with the verified badge.',
      ),
      'pending' => const (
        bg: Color(0xFFFFF7E6),
        fg: Color(0xFFB45309),
        icon: Icons.hourglass_top_rounded,
        label: 'Pending Review',
        message:
            'Your documents were submitted. Admin review is still in progress.',
      ),
      'rejected' => const (
        bg: Color(0xFFFEECEC),
        fg: Color(0xFFB91C1C),
        icon: Icons.error_outline_rounded,
        label: 'Needs Update',
        message: 'Please upload clearer documents and submit again.',
      ),
      _ => const (
        bg: Color(0xFFEFF6FF),
        fg: Color(0xFF1D4ED8),
        icon: Icons.badge_outlined,
        label: 'Not Submitted',
        message: 'Submit your ID documents to start verification review.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 22,
            spreadRadius: -12,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tone.icon, color: tone.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KYC Status',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tone.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tone.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tone.fg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tone.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
