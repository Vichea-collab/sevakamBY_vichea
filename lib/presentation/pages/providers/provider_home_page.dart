import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/provider_card.dart';
import '../../widgets/shimmer_loading.dart';
import 'provider_category_page.dart';
import 'provider_detail_page.dart';

class ProviderHomePage extends StatefulWidget {
  static const String routeName = '/providers';

  const ProviderHomePage({super.key});

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> {
  late final TextEditingController _searchController;
  String _query = '';
  Timer? _searchDebounce;
  List<ProviderPostItem>? _cachedPosts;
  List<ProviderSection> _cachedSections = const <ProviderSection>[];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    unawaited(_primeProviderPosts());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      await ProviderPostState.refresh(page: 1);
      await ProviderPostState.refreshAllForLookup();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ProviderPostState.loading,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<List<ProviderPostItem>>(
          valueListenable: ProviderPostState.allPosts,
          builder: (context, allPosts, _) {
            return ValueListenableBuilder<List<ProviderPostItem>>(
              valueListenable: ProviderPostState.posts,
              builder: (context, pagedPosts, _) {
                final posts = allPosts.isNotEmpty ? allPosts : pagedPosts;
                final allSections = _sectionsFromPostsCached(posts);
                final sections = _filterSections(allSections, _query.trim());
                final hasQuery = _query.trim().isNotEmpty;
                final providerCount = sections.fold<int>(
                  0,
                  (sum, section) => sum + section.providers.length,
                );

                return Scaffold(
                  backgroundColor: const Color(0xFFF3F6FB),
                  body: SafeArea(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProviderDirectoryHero(
                              controller: _searchController,
                              query: _query,
                              onChanged: _onSearchChanged,
                              onBack: () => Navigator.pop(context),
                              onClear: () {
                                _searchDebounce?.cancel();
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                            if (hasQuery) ...[
                              const SizedBox(height: 18),
                              _SearchInsightBar(
                                query: _query.trim(),
                                providerCount: providerCount,
                                sectionCount: sections.length,
                              ),
                            ],
                            const SizedBox(height: 22),
                            if (isLoading && sections.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 18),
                                child: Column(
                                  children: [
                                    CategoryShimmerList(),
                                    SizedBox(height: 20),
                                    CategoryShimmerList(),
                                  ],
                                ),
                              ),
                            if (!isLoading && sections.isEmpty)
                              _ProviderEmptyState(
                                hasQuery: hasQuery,
                                query: _query.trim(),
                              ),
                            for (final section in sections) ...[
                              _ProviderSectionHeader(
                                title: section.title,
                                onAction: () => Navigator.push(
                                  context,
                                  slideFadeRoute(
                                    ProviderCategoryPage(section: section),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 324,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  cacheExtent: 800,
                                  itemBuilder: (context, index) {
                                    final provider = section.providers[index];
                                    final heroTag =
                                        'provider-card-${section.category}-${provider.uid}';
                                    return SizedBox(
                                      width: 196,
                                      child: ProviderCard(
                                        provider: provider,
                                        heroTag: heroTag,
                                        onDetails: () => Navigator.push(
                                          context,
                                          slideFadeRoute(
                                            ProviderDetailPage(
                                              provider: provider,
                                              heroTag: heroTag,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: AppSpacing.md),
                                  itemCount: section.providers.length,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _primeProviderPosts() async {
    try {
      if (ProviderPostState.posts.value.isEmpty &&
          !ProviderPostState.loading.value) {
        await ProviderPostState.refresh(page: 1);
      }
      await ProviderPostState.refreshAllForLookup();
    } catch (_) {
      // Keep page usable with partial data if lookup sync fails.
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || _query == value) return;
      setState(() => _query = value);
    });
  }

  List<ProviderSection> _sectionsFromPostsCached(List<ProviderPostItem> posts) {
    if (identical(_cachedPosts, posts)) {
      return _cachedSections;
    }
    _cachedPosts = posts;
    _cachedSections = _sectionsFromPosts(posts);
    return _cachedSections;
  }

  List<ProviderSection> _filterSections(
    List<ProviderSection> sections,
    String query,
  ) {
    final normalized = query.toLowerCase();
    if (normalized.isEmpty) return sections;

    final filtered = <ProviderSection>[];
    for (final section in sections) {
      final categoryMatch = section.category.toLowerCase().contains(normalized);
      final providers = section.providers
          .where((provider) {
            if (categoryMatch) return true;
            if (provider.name.toLowerCase().contains(normalized)) return true;
            if (provider.role.toLowerCase().contains(normalized)) return true;
            return provider.services.any(
              (service) => service.toLowerCase().contains(normalized),
            );
          })
          .toList(growable: false);
      if (providers.isEmpty) continue;
      filtered.add(
        ProviderSection(
          title: section.title,
          category: section.category,
          providers: providers,
        ),
      );
    }
    return filtered;
  }

  List<ProviderSection> _sectionsFromPosts(List<ProviderPostItem> posts) {
    final grouped = <String, Map<String, _ProviderAggregate>>{};

    for (final post in posts) {
      final category = post.category.trim().isEmpty ? 'General' : post.category;
      final providerKey = _providerKey(post);
      final categoryMap = grouped.putIfAbsent(
        category,
        () => <String, _ProviderAggregate>{},
      );
      final existing = categoryMap[providerKey];
      if (existing == null) {
        categoryMap[providerKey] = _ProviderAggregate.fromPost(post);
      } else {
        existing.absorb(post);
      }
    }

    final sections =
        grouped.entries
            .map((entry) {
              final providers =
                  entry.value.values
                      .map((aggregate) => _providerFromAggregate(aggregate))
                      .toList(growable: false)
                    ..sort((a, b) => a.name.compareTo(b.name));
              return ProviderSection(
                title: '${entry.key} Providers',
                category: entry.key,
                providers: providers,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => a.category.compareTo(b.category));

    return sections;
  }

  String _providerKey(ProviderPostItem post) {
    final uid = post.providerUid.trim().toLowerCase();
    if (uid.isNotEmpty) return uid;
    return post.providerName.trim().toLowerCase();
  }

  ProviderItem _providerFromAggregate(_ProviderAggregate item) {
    final role = item.category.trim().isEmpty
        ? 'Service'
        : item.category.trim();
    return ProviderItem(
      uid: item.providerUid.trim(),
      name: item.providerName.trim().isEmpty
          ? 'Service Provider'
          : item.providerName.trim(),
      role: role,
      rating: item.rating,
      imagePath: item.avatarPath,
      accentColor: _accentFromCategory(role),
      services: item.services.toList(growable: false)..sort(),
      isVerified: item.isVerified,
      subscriptionTier: item.subscriptionTier,
      blockedDates: item.blockedDates,
      portfolioPhotos: item.portfolioPhotos,
    );
  }

  Color _accentFromCategory(String category) {
    final value = category.trim().toLowerCase();
    if (value.contains('plumb')) return const Color(0xFF0E8AD6);
    if (value.contains('electric')) return const Color(0xFFF59E0B);
    if (value.contains('clean')) return const Color(0xFF10B981);
    if (value.contains('appliance')) return const Color(0xFF6366F1);
    return AppColors.primary;
  }
}

class _ProviderDirectoryHero extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onClear;

  const _ProviderDirectoryHero({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onBack,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5BCD), Color(0xFF5B72F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 30,
            spreadRadius: -14,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -22,
            right: -18,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -46,
            left: -10,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Service Providers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          hintText: 'Search provider, category, or service',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    if (query.trim().isNotEmpty)
                      GestureDetector(
                        onTap: onClear,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _SearchInsightBar extends StatelessWidget {
  final String query;
  final int providerCount;
  final int sectionCount;

  const _SearchInsightBar({
    required this.query,
    required this.providerCount,
    required this.sectionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Showing $providerCount providers in $sectionCount categories for "$query".',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderEmptyState extends StatelessWidget {
  final bool hasQuery;
  final String query;

  const _ProviderEmptyState({required this.hasQuery, required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasQuery ? 'No providers match yet' : 'No provider offers yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Try another keyword for "$query" or browse a different service category.'
                : 'Provider offers will appear here once service providers publish their listings.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ProviderSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAction;

  const _ProviderSectionHeader({required this.title, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View all',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderAggregate {
  final String providerUid;
  final String providerName;
  final String category;
  final String avatarPath;
  final Set<String> services;
  final List<DateTime> blockedDates;
  final List<String> portfolioPhotos;
  String subscriptionTier;
  double rating;
  bool isVerified;

  _ProviderAggregate({
    required this.providerUid,
    required this.providerName,
    required this.category,
    required this.avatarPath,
    required this.services,
    this.portfolioPhotos = const [],
    this.subscriptionTier = 'basic',
    this.blockedDates = const [],
    this.rating = 0,
    this.isVerified = false,
  });

  factory _ProviderAggregate.fromPost(ProviderPostItem post) {
    return _ProviderAggregate(
      providerUid: post.providerUid.trim(),
      providerName: post.providerName.trim(),
      category: post.category.trim(),
      avatarPath: post.avatarPath,
      services: post.serviceList
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet(),
      portfolioPhotos: List<String>.from(post.portfolioPhotos),
      subscriptionTier: post.subscriptionTier,
      blockedDates: post.blockedDates,
      rating: post.rating,
      isVerified: post.isVerified,
    );
  }

  void absorb(ProviderPostItem post) {
    for (final service in post.serviceList) {
      final normalized = service.trim();
      if (normalized.isNotEmpty) {
        services.add(normalized);
      }
    }
    if (_tierWeight(post.subscriptionTier) > _tierWeight(subscriptionTier)) {
      subscriptionTier = post.subscriptionTier;
    }
    rating = post.rating;
    if (post.isVerified) isVerified = true;

    for (final photo in post.portfolioPhotos) {
      if (!portfolioPhotos.contains(photo)) {
        portfolioPhotos.add(photo);
      }
    }
  }

  int _tierWeight(String tier) {
    final normalized = tier.toLowerCase().trim();
    if (normalized == 'elite') return 2;
    if (normalized == 'professional') return 1;
    return 0;
  }
}
