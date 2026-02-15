import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../../domain/entities/provider_profile.dart';
import '../../state/chat_state.dart';
import '../../state/booking_catalog_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../booking/booking_address_page.dart';
import '../chat/chat_conversation_page.dart';
import '../chat/chat_list_page.dart';

enum _ProviderContentTab { companyInfo, reviews }

class ProviderDetailPage extends StatefulWidget {
  final ProviderItem provider;

  const ProviderDetailPage({super.key, required this.provider});

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  _ProviderContentTab _contentTab = _ProviderContentTab.companyInfo;
  ReviewRange _reviewRange = ReviewRange.last120;

  @override
  Widget build(BuildContext context) {
    final profile = _buildProfile(widget.provider);
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  _ProviderSummaryCard(profile: profile),
                  const SizedBox(height: 12),
                  _ContactSwitcher(
                    onBookTap: () => Navigator.push(
                      context,
                      slideFadeRoute(
                        BookingAddressPage(
                          draft: BookingCatalogState.defaultBookingDraft(
                            provider: widget.provider,
                            serviceName: widget.provider.services.isNotEmpty
                                ? widget.provider.services.first
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
                    onChanged: (tab) => setState(() => _contentTab = tab),
                  ),
                  const SizedBox(height: 12),
                  if (_contentTab == _ProviderContentTab.companyInfo)
                    _CompanyInfoSection(profile: profile)
                  else
                    _ReviewsSection(
                      reviews: reviews,
                      selectedRange: _reviewRange,
                      onRangeTap: _openReviewFilterSheet,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  ProviderProfile _buildProfile(ProviderItem provider) {
    final posts = ProviderPostState.posts.value;
    ProviderPostItem? matched;
    for (final post in posts) {
      final sameUid =
          provider.uid.trim().isNotEmpty &&
          provider.uid.trim() == post.providerUid.trim();
      final sameName =
          provider.name.trim().toLowerCase() ==
          post.providerName.trim().toLowerCase();
      if (sameUid || sameName) {
        matched = post;
        break;
      }
    }

    return ProviderProfile(
      provider: provider,
      location: matched?.area.trim().isNotEmpty == true
          ? matched!.area.trim()
          : 'Phnom Penh, Cambodia',
      available: matched?.availableNow ?? true,
      completedJobs: 42,
      about: matched?.details.trim().isNotEmpty == true
          ? matched!.details.trim()
          : 'Trusted service provider ready to help with fast and quality work.',
      projectImages: const <String>[
        'assets/images/plumber_category.jpg',
        'assets/images/plumber_category.jpg',
        'assets/images/plumber_category.jpg',
      ],
      reviews: _seedReviews(provider),
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
        comment: 'Clear communication and fair pricing.',
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

  const _ProviderSummaryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
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
              CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(profile.provider.imagePath),
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
              const Icon(Icons.verified, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                '${profile.averageRating.toStringAsFixed(1)} (${profile.reviews.length} Reviews)',
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
        child: PressableScale(
          onTap: () => onChanged(tab),
          child: InkWell(
            onTap: () => onChanged(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(label: 'Company info', tab: _ProviderContentTab.companyInfo),
        tab(label: 'Reviews', tab: _ProviderContentTab.reviews),
      ],
    );
  }
}

class _CompanyInfoSection extends StatelessWidget {
  final ProviderProfile profile;

  const _CompanyInfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${profile.provider.name}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(profile.about, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Projects', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profile.projectImages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  profile.projectImages[index],
                  width: 120,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final List<ProviderReview> reviews;
  final ReviewRange selectedRange;
  final VoidCallback onRangeTap;

  const _ReviewsSection({
    required this.reviews,
    required this.selectedRange,
    required this.onRangeTap,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 26),
                child: Text(
                  review.reviewerInitials,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                review.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${review.daysAgo} days ago',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
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
