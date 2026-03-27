import 'package:flutter/material.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/constants/app_spacing.dart';
import 'package:servicefinder/core/theme/app_theme_tokens.dart';
import 'package:servicefinder/domain/entities/subscription.dart';
import 'package:servicefinder/presentation/state/subscription_state.dart';
import 'package:servicefinder/domain/entities/provider_portal.dart';
import 'package:servicefinder/presentation/widgets/app_top_bar.dart';
import 'package:servicefinder/presentation/widgets/primary_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servicefinder/core/utils/app_toast.dart';
import 'package:servicefinder/core/utils/safe_image_provider.dart';
import 'package:servicefinder/presentation/state/provider_post_state.dart';
import 'package:servicefinder/core/firebase/firebase_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:servicefinder/presentation/widgets/app_dialog.dart';

import 'provider_post_page.dart';

class ProviderPortfolioPage extends StatefulWidget {
  static const String routeName = '/provider/portfolio';

  const ProviderPortfolioPage({super.key});

  @override
  State<ProviderPortfolioPage> createState() => _ProviderPortfolioPageState();
}

class _ProviderPortfolioPageState extends State<ProviderPortfolioPage> {
  static const double _portfolioTileRadius = 16;
  bool _isUploading = false;
  bool _loadingPost = true;
  ProviderPostItem? _currentPost;

  @override
  void initState() {
    super.initState();
    _loadCurrentPost();
  }

  Future<void> _loadCurrentPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() => _loadingPost = true);
    }
    if (user == null) {
      if (mounted) {
        setState(() {
          _currentPost = null;
          _loadingPost = false;
        });
      }
      return;
    }
    final post = await ProviderPostState.findLatestByUid(user.uid);
    if (mounted) {
      setState(() {
        _currentPost = post;
        _loadingPost = false;
      });
    }
  }

  List<String> get _photos => _currentPost?.portfolioPhotos ?? [];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SubscriptionStatus>(
      valueListenable: SubscriptionState.status,
      builder: (context, status, _) {
        final plan = status.plan;
        final maxPhotos = plan.maxPhotos;
        final isUnlimited = maxPhotos < 0;
        final remains = isUnlimited
            ? double.infinity
            : maxPhotos - _photos.length;
        final canAdd = remains > 0;

        return Scaffold(
          backgroundColor: AppThemeTokens.pageBackground(context),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: const AppTopBar(
                    title: 'Portfolio Gallery',
                    showBack: true,
                  ),
                ),
                Container(height: 1, color: AppColors.divider),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubscriptionStatus(
                          plan,
                          _photos.length,
                          maxPhotos,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Work Samples',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppThemeTokens.textPrimary(context),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Showcase your best work to attract more clients.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppThemeTokens.textSecondary(context),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (_loadingPost) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ] else if (_currentPost == null) ...[
                          _buildMissingPostState(),
                        ] else ...[
                          _buildPhotoGrid(canAdd, remains.toDouble(), plan),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!canAdd && !isUnlimited) _buildUpgradePrompt(plan),
              ],
            ),
          ),
          floatingActionButton: canAdd
              ? Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.splashEnd],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: _addPhoto,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    highlightElevation: 0,
                    icon: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Add Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSubscriptionStatus(SubscriptionPlan plan, int current, int max) {
    final isUnlimited = max < 0;
    final percent = isUnlimited
        ? 0.0
        : (current / max).clamp(0.0, 1.0).toDouble();
    final color = percent > 0.8 ? Colors.orange : AppColors.primary;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: plan.badgeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: plan.badgeColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(plan.badgeIcon, color: plan.badgeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${plan.name} Tier',
                    style: TextStyle(
                      color: plan.badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gallery Limit',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    isUnlimited ? 'Unlimited' : '$current / $max photos',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (!isUnlimited) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.white,
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoGrid(bool canAdd, double remains, SubscriptionPlan plan) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length + (canAdd ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _photos.length) {
          return _buildPhotoItem(_photos[index]);
        } else {
          return _buildAddPlaceholder();
        }
      },
    );
  }

  Widget _buildPhotoItem(String url) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => _showFullscreenImage(context, url),
            child: Container(
              decoration: BoxDecoration(
                color: AppThemeTokens.mutedSurface(context),
                borderRadius: BorderRadius.circular(_portfolioTileRadius),
                border: Border.all(color: AppThemeTokens.outline(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeImage(
                source: url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _deletePhoto(url),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.red),
            ),
          ),
        ),
        ],
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: SafeImage(
                  source: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPlaceholder() {
    return GestureDetector(
      onTap: _addPhoto,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppThemeTokens.mutedSurface(context),
            borderRadius: BorderRadius.circular(_portfolioTileRadius),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt(SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gallery limit reached!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Upgrade to Plus for 15 photos.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PrimaryButton(
            label: 'Upgrade',
            onPressed: () {
              // Navigate to subscription page
              AppToast.success(context, 'Redirecting to upgrade...');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMissingPostState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppThemeTokens.mutedSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppThemeTokens.outline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Create a provider post first',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppThemeTokens.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Portfolio photos are attached to your latest provider post. Create or save a provider post first, then upload images here.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: AppThemeTokens.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loadCurrentPost,
                  child: const Text('Retry'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Open Post',
                  onPressed: _openProviderPostPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openProviderPostPage() async {
    await Navigator.pushNamed(context, ProviderPostPage.routeName);
    await _loadCurrentPost();
  }

  Future<ProviderPostItem?> _ensureCurrentPostForUpload() async {
    if (_currentPost != null) return _currentPost;
    await _loadCurrentPost();
    if (_currentPost != null) return _currentPost;
    if (!mounted) return null;

    final shouldOpenPost = await showAppConfirmDialog(
      context: context,
      icon: Icons.post_add_rounded,
      title: 'Provider Post Required',
      message:
          'Portfolio photos are saved on your provider post. Create or save a provider post first, then upload photos here.',
      confirmText: 'Open Post',
      cancelText: 'Not Now',
      tone: AppDialogTone.info,
    );
    if (shouldOpenPost == true && mounted) {
      await _openProviderPostPage();
    }
    return _currentPost;
  }

  String _resolveImageExtension(XFile image) {
    final name = image.name.trim();
    final source = name.isNotEmpty ? name : image.path;
    final dotIndex = source.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == source.length - 1) {
      return 'jpg';
    }
    return source.substring(dotIndex + 1).toLowerCase();
  }

  Future<void> _addPhoto() async {
    if (_isUploading) return;

    final post = await _ensureCurrentPostForUpload();
    if (post == null || !mounted) return;

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      setState(() => _isUploading = true);

      final bytes = await image.readAsBytes();
      final extension = _resolveImageExtension(image);

      final downloadUrl = await FirebaseStorageService.uploadPortfolioPhoto(
        bytes,
        extension: extension,
      );

      if (downloadUrl == null) {
        throw Exception('Storage upload failed');
      }

      final nextPhotos = [..._photos, downloadUrl];

      await ProviderPostState.updateProviderPost(
        postId: post.id,
        category: post.category,
        services: post.services,
        area: post.area,
        details: post.details,
        availableNow: post.availableNow,
        portfolioPhotos: nextPhotos,
      );

      await _loadCurrentPost();
      if (!mounted) return;
      AppToast.success(context, 'Photo added to your gallery!');
    } catch (e) {
      debugPrint('ProviderPortfolioPage._addPhoto error: $e');
      if (mounted) {
        AppToast.error(
          context,
          'Unable to upload photo. Please check gallery access and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deletePhoto(String url) async {
    if (_isUploading || _currentPost == null) return;

    try {
      setState(() => _isUploading = true);

      final nextPhotos = _photos.where((p) => p != url).toList();

      await ProviderPostState.updateProviderPost(
        postId: _currentPost!.id,
        category: _currentPost!.category,
        services: _currentPost!.services,
        area: _currentPost!.area,
        details: _currentPost!.details,
        availableNow: _currentPost!.availableNow,
        portfolioPhotos: nextPhotos,
      );

      await _loadCurrentPost();
      if (!mounted) return;
      AppToast.success(context, 'Photo removed.');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Unable to remove photo.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
