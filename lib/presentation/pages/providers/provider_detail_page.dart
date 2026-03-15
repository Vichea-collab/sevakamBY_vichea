import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../../domain/entities/provider_profile.dart';
import '../../state/favorite_state.dart';
import '../../state/chat_state.dart';
import '../../state/booking_catalog_state.dart';
import '../../state/order_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/subscription_badge.dart';
import '../../widgets/verified_badge.dart';
import '../booking/booking_address_page.dart';
import '../chat/chat_conversation_page.dart';
import '../chat/chat_list_page.dart';

enum _ProviderContentTab { companyInfo, portfolio, reviews }

class ProviderDetailPage extends StatefulWidget {
  final ProviderItem provider;
  final String? heroTag;

  const ProviderDetailPage({super.key, required this.provider, this.heroTag});

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  _ProviderContentTab _contentTab = _ProviderContentTab.companyInfo;
  ReviewRange _reviewRange = ReviewRange.last120;
  ProviderReviewSummary? _reviewSummary;
  List<ProviderPostItem> _providerPosts = const [];
  bool _loadingReviews = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _reviewSummary = OrderState.peekProviderReviewSummary(
      providerUid: widget.provider.uid,
    );
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loadingProfile = true);
    try {
      await Future.wait([_loadProviderReviews(), _loadProviderPosts()]);
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  Future<void> _loadProviderPosts() async {
    final uid = widget.provider.uid.trim();
    if (uid.isEmpty) return;
    final matched = await ProviderPostState.findAllByUid(uid);
    if (mounted) setState(() => _providerPosts = matched);
  }

  @override
  void didUpdateWidget(covariant ProviderDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.uid.trim() != widget.provider.uid.trim()) {
      _reviewSummary = OrderState.peekProviderReviewSummary(
        providerUid: widget.provider.uid,
      );
      unawaited(_loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _buildProfile(
      widget.provider,
      summary: _reviewSummary,
      matchedPosts: _providerPosts,
      heroTag: widget.heroTag,
    );
    final reviews = _reviewsByRange(profile.reviews, _reviewRange);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AppTopBar(
                title: widget.provider.name,
                actions: [
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: FavoriteState.favoriteUids,
                    builder: (context, favorites, _) {
                      final isFav = favorites.contains(widget.provider.uid);
                      return IconButton(
                        onPressed: () =>
                            FavoriteState.toggleFavorite(widget.provider.uid),
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? AppColors.danger : AppColors.primary,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      slideFadeRoute(const ChatListPage()),
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.divider),
            Expanded(
              child: _loadingProfile && _providerPosts.isEmpty
                  ? const Center(
                      child: AppStatePanel.loading(title: 'Loading profile'),
                    )
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        children: [
                          _ProviderSummaryCard(
                            profile: profile,
                            totalReviewCount: _reviewSummary?.totalReviews,
                          ),
                          const SizedBox(height: 12),
                          _ContactSwitcher(
                            onBookTap: () => Navigator.push(
                              context,
                              slideFadeRoute(
                                BookingAddressPage(
                                  draft:
                                      BookingCatalogState.defaultBookingDraft(
                                        provider: profile.provider,
                                        serviceName:
                                            profile.provider.services.isNotEmpty
                                            ? profile.provider.services.first
                                            : null,
                                      ),
                                ),
                              ),
                            ),
                            onChatTap: () {
                              _openProviderChat();
                            },
                          ),
                          const SizedBox(height: 12),
                          _ContentTabs(
                            activeTab: _contentTab,
                            onChanged: (tab) =>
                                setState(() => _contentTab = tab),
                          ),
                          const SizedBox(height: 12),
                          if (_contentTab == _ProviderContentTab.companyInfo)
                            _CompanyInfoSection(
                              title: 'Bio',
                              content: profile.about,
                            )
                          else if (_contentTab == _ProviderContentTab.portfolio)
                            _PortfolioSection(
                              photos: profile.provider.portfolioPhotos,
                            )
                          else
                            _ReviewsSection(
                              reviews: reviews,
                              selectedRange: _reviewRange,
                              onRangeTap: _openReviewFilterSheet,
                              loading: _loadingReviews,
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadProviderReviews() async {
    final providerUid = widget.provider.uid.trim();
    if (providerUid.isEmpty) return;
    final shouldShowLoading = _reviewSummary == null;
    if (mounted) {
      setState(() => _loadingReviews = shouldShowLoading);
    }
    try {
      final summary = await OrderState.fetchProviderReviewSummary(
        providerUid: providerUid,
        limit: 50,
      );
      if (!mounted) return;
      setState(() => _reviewSummary = summary);
    } catch (_) {
      // Keep the latest known summary on transient fetch failures.
    } finally {
      if (mounted) {
        setState(() => _loadingReviews = false);
      }
    }
  }

  void _openReviewFilterSheet() {
    var selected = _reviewRange;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reviews',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final item in ReviewRange.values)
                    _ReviewRangeTile(
                      label: item.label,
                      selected: selected == item,
                      onTap: () => setModalState(() => selected = item),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.splashEnd],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _reviewRange = selected);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openProviderChat() async {
    final providerUid = widget.provider.uid.trim();
    if (providerUid.isEmpty) {
      AppToast.info(context, 'Live chat opens after provider accepts booking.');
      return;
    }
    try {
      final thread = await ChatState.openDirectThread(
        peerUid: providerUid,
        peerName: widget.provider.name,
        peerIsProvider: true,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        slideFadeRoute(ChatConversationPage(thread: thread)),
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to open live chat.');
    }
  }

  ProviderProfile _buildProfile(
    ProviderItem provider, {
    ProviderReviewSummary? summary,
    List<ProviderPostItem> matchedPosts = const [],
    String? heroTag,
  }) {
    final providerUid = provider.uid.trim().toLowerCase();
    final providerName = provider.name.trim().toLowerCase();

    // Aggregate all relevant posts
    final posts = <ProviderPostItem>[...matchedPosts];
    if (posts.isEmpty) {
      final allCached = ProviderPostState.allPosts.value;
      final cachedList = allCached.isNotEmpty
          ? allCached
          : ProviderPostState.posts.value;
      for (final post in cachedList) {
        final sameUid =
            providerUid.isNotEmpty &&
            providerUid == post.providerUid.trim().toLowerCase();
        final sameName = providerName == post.providerName.trim().toLowerCase();
        if (!sameUid && !sameName) continue;

        posts.add(post);
      }
    }

    final services = <String>{
      ...provider.services
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
      for (final post in posts)
        ...post.serviceList
            .map((service) => service.trim())
            .where((item) => item.isNotEmpty),
    }.toList(growable: false)..sort();

    final portfolioPhotos = <String>{
      ...provider.portfolioPhotos,
      for (final post in posts) ...post.portfolioPhotos,
    }.toList(growable: false);

    final hasProviderUid = provider.uid.trim().isNotEmpty;
    final averageRating = (summary?.averageRating ?? 0) > 0
        ? summary!.averageRating
        : provider.rating;

    // Use latest post for primary details like location/availability
    ProviderPostItem? latestPost;
    for (final post in posts) {
      if (latestPost == null) {
        latestPost = post;
        continue;
      }
      final latestAt =
          latestPost.updatedAt ??
          latestPost.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final currentAt =
          post.updatedAt ??
          post.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (currentAt.isAfter(latestAt)) {
        latestPost = post;
      }
    }

    final mergedProvider = ProviderItem(
      uid: provider.uid,
      name: provider.name,
      role: provider.role,
      bio: provider.bio.trim().isNotEmpty
          ? provider.bio
          : (latestPost?.providerBio ?? ''),
      rating: averageRating,
      imagePath: provider.imagePath.trim().isNotEmpty
          ? provider.imagePath
          : (latestPost?.avatarPath ?? ''),
      accentColor: provider.accentColor,
      services: services,
      isVerified: provider.isVerified || (latestPost?.isVerified ?? false),
      subscriptionTier:
          provider.subscriptionTier.trim().toLowerCase() != 'basic'
          ? provider.subscriptionTier
          : (latestPost?.subscriptionTier ?? provider.subscriptionTier),
      latitude: provider.latitude ?? latestPost?.latitude,
      longitude: provider.longitude ?? latestPost?.longitude,
      blockedDates: provider.blockedDates,
      portfolioPhotos: portfolioPhotos,
    );

    return ProviderProfile(
      provider: mergedProvider,
      location: latestPost?.area.trim().isNotEmpty == true
          ? latestPost!.area.trim()
          : 'Phnom Penh, Cambodia',
      available: latestPost?.availableNow ?? true,
      completedJobs: summary?.completedJobs ?? (hasProviderUid ? 0 : 42),
      about: provider.bio.trim().isNotEmpty
          ? provider.bio.trim()
          : (latestPost?.details.trim().isNotEmpty == true
                ? latestPost!.details.trim()
                : 'Trusted service provider ready to help with fast and quality work.'),
      reviews:
          summary?.reviews ??
          (hasProviderUid ? const [] : _seedReviews(provider)),
      portfolioPhotos: portfolioPhotos,
      heroTag: heroTag,
    );
  }

  List<ProviderReview> _seedReviews(ProviderItem provider) {
    final base = provider.rating <= 0 ? 4.7 : provider.rating;
    return <ProviderReview>[
      ProviderReview(
        reviewerName: 'Sokha',
        reviewerInitials: 'S',
        rating: base,
        daysAgo: 7,
        comment: 'Professional and on time. Great service quality.',
      ),
      ProviderReview(
        reviewerName: 'Dara',
        reviewerInitials: 'D',
        rating: (base - 0.1).clamp(1, 5).toDouble(),
        daysAgo: 19,
        comment: 'Clear communication and great results.',
      ),
      ProviderReview(
        reviewerName: 'Nary',
        reviewerInitials: 'N',
        rating: (base - 0.2).clamp(1, 5).toDouble(),
        daysAgo: 33,
        comment: 'Job completed well. Will book again.',
      ),
      ProviderReview(
        reviewerName: 'Vanna',
        reviewerInitials: 'V',
        rating: (base - 0.1).clamp(1, 5).toDouble(),
        daysAgo: 58,
        comment: 'Quick response and tidy work.',
      ),
      ProviderReview(
        reviewerName: 'Malis',
        reviewerInitials: 'M',
        rating: (base - 0.3).clamp(1, 5).toDouble(),
        daysAgo: 92,
        comment: 'Good result overall and respectful team.',
      ),
    ];
  }

  List<ProviderReview> _reviewsByRange(
    List<ProviderReview> reviews,
    ReviewRange range,
  ) {
    return reviews
        .where((review) => review.daysAgo <= range.maxDays)
        .toList(growable: false);
  }
}

class _ProviderSummaryCard extends StatelessWidget {
  final ProviderProfile profile;
  final int? totalReviewCount;

  const _ProviderSummaryCard({required this.profile, this.totalReviewCount});

  @override
  Widget build(BuildContext context) {
    final imagePath = profile.provider.imagePath.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: profile.heroTag ?? 'provider-${profile.provider.uid}',
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.background,
                  backgroundImage: imagePath.isNotEmpty
                      ? safeImageProvider(imagePath)
                      : null,
                  child: imagePath.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  profile.provider.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (profile.provider.isVerified)
                    const VerifiedBadge(size: 11),
                  SubscriptionBadge.fromString(
                    profile.provider.subscriptionTier,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                '${profile.averageRating.toStringAsFixed(1)} (${totalReviewCount ?? profile.reviews.length} Reviews)',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.location} • ${profile.available ? "Available" : "Closed"}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (profile.provider.services.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Services: ${profile.provider.services.join(' • ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${profile.completedJobs} similar jobs completed near you',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ContactSwitcher extends StatelessWidget {
  final VoidCallback onBookTap;
  final VoidCallback onChatTap;

  const _ContactSwitcher({required this.onBookTap, required this.onChatTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: onBookTap,
            child: InkWell(
              onTap: onBookTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PressableScale(
            onTap: onChatTap,
            child: InkWell(
              onTap: onChatTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Chat',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentTabs extends StatelessWidget {
  final _ProviderContentTab activeTab;
  final ValueChanged<_ProviderContentTab> onChanged;

  const _ContentTabs({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab({required String label, required _ProviderContentTab tab}) {
      final selected = activeTab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(tab),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.primary : const Color(0xFF64748B),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          tab(label: 'Company', tab: _ProviderContentTab.companyInfo),
          tab(label: 'Portfolio', tab: _ProviderContentTab.portfolio),
          tab(label: 'Reviews', tab: _ProviderContentTab.reviews),
        ],
      ),
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  final List<String> photos;

  const _PortfolioSection({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No portfolio photos yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () => _showFullscreenImage(context, photo),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SafeImage(source: photo, fit: BoxFit.cover),
          ),
        );
      },
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
}

class _CompanyInfoSection extends StatelessWidget {
  final String title;
  final String content;

  const _CompanyInfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(content, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final List<ProviderReview> reviews;
  final ReviewRange selectedRange;
  final VoidCallback onRangeTap;
  final bool loading;

  const _ReviewsSection({
    required this.reviews,
    required this.selectedRange,
    required this.onRangeTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${reviews.length} Reviews',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            PressableScale(
              onTap: onRangeTap,
              child: InkWell(
                onTap: onRangeTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedRange.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.expand_more,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading && reviews.isEmpty) ...[
          const Center(child: AppStatePanel.loading(title: 'Loading reviews')),
          const SizedBox(height: 12),
        ],
        if (!loading && reviews.isEmpty)
          Text(
            'No reviews yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ...reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ProviderReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final photoUrl = review.reviewerPhotoUrl.trim();
    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasPhoto)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.background,
                  backgroundImage: safeImageProvider(photoUrl),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    review.reviewerInitials,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _reviewTimestamp(review),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF334155),
              height: 1.5,
            ),
          ),
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SafeImage(
                      source: review.photoUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _reviewTimestamp(ProviderReview review) {
    final reviewedAt = review.reviewedAt;
    if (reviewedAt != null) {
      final local = reviewedAt.toLocal();
      const months = <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[(local.month - 1).clamp(0, 11)];
      final hour24 = local.hour;
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final meridiem = hour24 >= 12 ? 'PM' : 'AM';
      return '$month ${local.day}, ${local.year} • $hour12:$minute $meridiem';
    }
    if (review.daysAgo <= 0) return 'Today';
    if (review.daysAgo == 1) return '1 day ago';
    return '${review.daysAgo} days ago';
  }
}

class _ReviewRangeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReviewRangeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
