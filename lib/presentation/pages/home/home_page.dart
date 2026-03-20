import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/location_options.dart';
import '../../../domain/entities/home_promotion.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/catalog_state.dart';
import '../../state/chat_state.dart';
import '../../state/home_promotion_state.dart';
import '../../state/profile_image_state.dart';
import '../../state/profile_settings_state.dart';
import '../../state/provider_post_state.dart';
import '../../../domain/entities/subscription.dart';

import '../../widgets/category_chip.dart';
import '../../widgets/premium_outline.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/section_title.dart';
import '../../widgets/service_card.dart';
import '../chat/chat_list_page.dart';
import '../favorites/favorites_page.dart';
import '../providers/provider_home_page.dart';
import '../providers/provider_detail_page.dart';
import '../providers/provider_posts_page.dart';
import '../search/search_page.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/subscription_badge.dart';
import '../../widgets/verified_badge.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _refreshInProgress = false;

  Future<void> _handleRefresh() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      await Future.wait<void>([
        CatalogState.refresh(force: true),
        HomePromotionState.refresh(
          city: ProfileSettingsState.finderProfile.value.city,
        ),
        ProviderPostState.refresh(page: 1),
        ProviderPostState.refreshAllForLookup(maxPages: 3),
        ChatState.refreshUnreadCount(),
      ]);
    } catch (_) {
      // Keep current data when refresh fails.
    } finally {
      _refreshInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const _TopHeader(),
            SliverPadding(
              padding: EdgeInsets.only(
                top: rs.space(AppSpacing.lg),
                left: rs.space(AppSpacing.lg),
                right: rs.space(AppSpacing.lg),
                bottom: rs.space(AppSpacing.xl),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SearchBar(),
                  SizedBox(height: rs.space(AppSpacing.md)),
                  const _FeaturedBanner(),
                  SizedBox(height: rs.space(AppSpacing.lg)),
                  SectionTitle(
                    title: 'Browse all categories',
                    actionLabel: 'View all',
                    onAction: () => Navigator.push(
                      context,
                      slideFadeRoute(const ProviderHomePage()),
                    ),
                  ),
                  SizedBox(height: rs.space(AppSpacing.md)),
                  ValueListenableBuilder<bool>(
                    valueListenable: CatalogState.loading,
                    builder: (context, catalogLoading, _) {
                      return ValueListenableBuilder(
                        valueListenable: CatalogState.categories,
                        builder: (context, categories, _) {
                          if (categories.isEmpty && catalogLoading) {
                            return const CategoryShimmerList();
                          }
                          if (categories.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            height: rs.dimension(154),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              cacheExtent: 500,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return CategoryChip(
                                  category: category,
                                  onTap: () => Navigator.push(
                                    context,
                                    slideFadeRoute(
                                      SearchPage(
                                        initialCategory: category.name,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (_, _) =>
                                  SizedBox(width: rs.space(12)),
                              itemCount: categories.length,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: rs.space(AppSpacing.lg)),
                  SectionTitle(
                    title: 'Popular services',
                    actionLabel: 'See all',
                    onAction: () => Navigator.push(
                      context,
                      slideFadeRoute(const SearchPage()),
                    ),
                  ),
                  SizedBox(height: rs.space(AppSpacing.md)),
                  ValueListenableBuilder<bool>(
                    valueListenable: CatalogState.loading,
                    builder: (context, catalogLoading, _) {
                      return ValueListenableBuilder(
                        valueListenable: CatalogState.services,
                        builder: (context, services, child) {
                          final popular = CatalogState.popularServices(
                            limit: 6,
                          );
                          if (popular.isEmpty && catalogLoading) {
                            return const ServiceCardShimmerList();
                          }
                          if (popular.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            height: rs.dimension(240),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              cacheExtent: 500,
                              itemBuilder: (context, index) {
                                final service = popular[index];
                                return ServiceCard(
                                  item: service,
                                  onTap: () => Navigator.push(
                                    context,
                                    slideFadeRoute(
                                      SearchPage(
                                        initialQuery: service.title,
                                        initialCategory: service.category,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (_, _) =>
                                  SizedBox(width: rs.space(AppSpacing.md)),
                              itemCount: popular.length,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: rs.space(AppSpacing.lg)),
                  const _EliteProvidersSection(),
                  SizedBox(height: rs.space(AppSpacing.lg)),
                  const _ProviderPostSection(),
                  Center(
                    child: PressableScale(
                      onTap: () => Navigator.push(
                        context,
                        slideFadeRoute(const SearchPage()),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          slideFadeRoute(const SearchPage()),
                        ),
                        borderRadius: BorderRadius.circular(rs.radius(10)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: rs.space(8),
                            vertical: rs.space(4),
                          ),
                          child: Text(
                            "Don't see what you are looking for?\nView all services",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatefulWidget {
  const _TopHeader();

  @override
  State<_TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends State<_TopHeader> {
  Timer? _chatRefreshTimer;
  bool _syncingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
      unawaited(_syncProfile());
    });
    _chatRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
    });
  }

  @override
  void dispose() {
    _chatRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncProfile() async {
    if (mounted) {
      setState(() => _syncingProfile = true);
    }
    await ProfileSettingsState.syncRoleProfileFromBackend(isProvider: false);
    if (mounted) {
      setState(() => _syncingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;

    Future<void> openChats() async {
      await Navigator.push(context, slideFadeRoute(const ChatListPage()));
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
    }

    Future<void> openFavorites() async {
      await Navigator.push(context, slideFadeRoute(const FavoritesPage()));
    }

    return SliverToBoxAdapter(
      child: ValueListenableBuilder<ProfileFormData>(
        valueListenable: ProfileSettingsState.finderProfile,
        builder: (context, profile, _) {
          final displayName = profile.name.trim().isEmpty
              ? 'Service Finder'
              : profile.name.trim();
          final city = profile.city.trim().isEmpty
              ? 'Phnom Penh'
              : profile.city.trim();
          final hasProfileContent =
              profile.name.trim().isNotEmpty || profile.city.trim().isNotEmpty;
          return Container(
            padding: rs.only(left: 20, top: 14, right: 20, bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.splashStart, AppColors.splashEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(rs.radius(20)),
                bottomRight: Radius.circular(rs.radius(20)),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 28),
                  blurRadius: rs.space(18),
                  offset: Offset(0, rs.space(8)),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: _syncingProfile && !hasProfileContent
                  ? const _FinderHeaderLoading()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: rs.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 230),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 64),
                                ),
                              ),
                              child: ValueListenableBuilder(
                                valueListenable:
                                    ProfileImageState.listenableForRole(
                                      isProvider: false,
                                    ),
                                builder: (context, value, child) {
                                  final image =
                                      ProfileImageState.avatarProvider(
                                        isProvider: false,
                                      );
                                  return CircleAvatar(
                                    radius: rs.dimension(22),
                                    backgroundColor: AppColors.background,
                                    backgroundImage: image,
                                    child: image == null
                                        ? Icon(
                                            Icons.person_rounded,
                                            color: AppColors.primary,
                                            size: rs.icon(22),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                            rs.gapW(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Finder',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 220,
                                          ),
                                        ),
                                  ),
                                  rs.gapH(2),
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  rs.gapH(8),
                                  _HeaderLocationPill(city: city),
                                ],
                              ),
                            ),
                            rs.gapW(12),
                            Column(
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: ChatState.unreadCount,
                                  builder: (context, unreadThreads, _) {
                                    return _HeaderActionButton(
                                      icon: Icons.message_outlined,
                                      onTap: openChats,
                                      badgeText: unreadThreads > 0
                                          ? (unreadThreads > 99
                                                ? '99+'
                                                : '$unreadThreads')
                                          : null,
                                    );
                                  },
                                ),
                                rs.gapH(10),
                                _HeaderActionButton(
                                  icon: Icons.favorite_border_rounded,
                                  onTap: openFavorites,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(rs.radius(16)),
      onTap: () => Navigator.push(context, slideFadeRoute(const SearchPage())),
      child: Container(
        padding: rs.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(rs.radius(16)),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
              blurRadius: rs.space(12),
              offset: Offset(0, rs.space(4)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: rs.dimension(36),
              width: rs.dimension(36),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 20),
                borderRadius: BorderRadius.circular(rs.radius(12)),
              ),
              child: Icon(Icons.search, color: Colors.white, size: rs.icon(20)),
            ),
            rs.gapW(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search services',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  rs.gapH(2),
                  Text(
                    'Providers, categories, or tasks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            rs.gapW(10),
            Container(
              height: rs.dimension(36),
              width: rs.dimension(36),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 20),
                borderRadius: BorderRadius.circular(rs.radius(12)),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 38),
                ),
              ),
              child: Icon(Icons.tune, color: Colors.white, size: rs.icon(18)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatefulWidget {
  const _FeaturedBanner();

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  static const _fallbackPromotions = <HomePromotion>[
    HomePromotion(
      id: 'fallback_cleaning',
      placement: 'finder_home',
      badgeLabel: 'Limited offer',
      title: 'House Cleaning this week',
      description: 'Book trusted house cleaning with faster response today.',
      imageUrl: 'assets/images/cleaning/house-cleaning.jpg',
      ctaLabel: 'Book cleaning',
      targetType: HomePromotionTargetType.service,
      targetValue: 'House Cleaning',
      query: 'House Cleaning',
      category: 'Cleaner',
      sortOrder: 0,
    ),
    HomePromotion(
      id: 'fallback_plumber',
      placement: 'finder_home',
      badgeLabel: 'Fast response',
      title: 'Pipe leaks fixed today',
      description: 'Find plumbers for urgent pipe leaks around your area.',
      imageUrl: 'assets/images/plumber/pipe-leak.jpg',
      ctaLabel: 'Find plumber',
      targetType: HomePromotionTargetType.service,
      targetValue: 'Pipe leaks',
      query: 'Pipe leaks',
      category: 'Plumber',
      sortOrder: 1,
    ),
    HomePromotion(
      id: 'fallback_appliance',
      placement: 'finder_home',
      badgeLabel: 'Home comfort',
      title: 'Air Conditioner Repair',
      description: 'Keep your home cool with quick repair this week.',
      imageUrl: 'assets/images/home_appliance_repair/ac-repair.jpg',
      ctaLabel: 'Explore repair',
      targetType: HomePromotionTargetType.service,
      targetValue: 'Air Conditioner Repair',
      query: 'Air Conditioner Repair',
      category: 'Home Appliance',
      sortOrder: 2,
    ),
    HomePromotion(
      id: 'fallback_electrician',
      placement: 'finder_home',
      badgeLabel: 'Popular now',
      title: 'Power Outage Fixes',
      description: 'Restore power safely with electricians available now.',
      imageUrl: 'assets/images/electrician/power-outages-fix.jpg',
      ctaLabel: 'View electricians',
      targetType: HomePromotionTargetType.service,
      targetValue: 'Power Outage Fixes',
      query: 'Power Outage Fixes',
      category: 'Electrician',
      sortOrder: 3,
    ),
    HomePromotion(
      id: 'fallback_maintenance',
      placement: 'finder_home',
      badgeLabel: 'Weekend ready',
      title: 'Furniture Fixing made easy',
      description: 'Quick help for shelves, doors, and furniture repairs.',
      imageUrl: 'assets/images/home_maintenance/furniture-repair.jpg',
      ctaLabel: 'See options',
      targetType: HomePromotionTargetType.service,
      targetValue: 'Furniture Fixing',
      query: 'Furniture Fixing',
      category: 'Home Maintenance',
      sortOrder: 4,
    ),
  ];

  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1,
      initialPage: _fallbackPromotions.length * 200,
    );
    _startAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        HomePromotionState.refresh(
          city: ProfileSettingsState.finderProfile.value.city,
        ),
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = _pageController.page!.round() + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HomePromotion>>(
      valueListenable: HomePromotionState.promotions,
      builder: (context, promotions, _) {
        final slides = promotions.isEmpty ? _fallbackPromotions : promotions;
        final currentIndex = slides.isEmpty ? 0 : _currentIndex % slides.length;
        return SizedBox(
          height: 278,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    final nextIndex = page % slides.length;
                    if (_currentIndex != nextIndex) {
                      setState(() => _currentIndex = nextIndex);
                    }
                  },
                  itemBuilder: (context, page) {
                    final promo = slides[page % slides.length];
                    return _PromoBannerCard(
                      slide: promo,
                      onTap: () => unawaited(_openPromotion(promo)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => _PromoDot(active: index == currentIndex),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPromotion(HomePromotion promo) async {
    switch (promo.targetType) {
      case HomePromotionTargetType.provider:
        final post = await ProviderPostState.findLatestByUid(promo.targetValue);
        if (!mounted) return;
        if (post != null) {
          await Navigator.push(
            context,
            slideFadeRoute(
              ProviderDetailPage(provider: ProviderItem.fromPost(post)),
            ),
          );
          return;
        }
        await Navigator.push(
          context,
          slideFadeRoute(
            SearchPage(
              initialQuery: promo.query.isEmpty
                  ? promo.targetValue
                  : promo.query,
              initialCategory: promo.category.isEmpty ? null : promo.category,
            ),
          ),
        );
        return;
      case HomePromotionTargetType.category:
        await Navigator.push(
          context,
          slideFadeRoute(SearchPage(initialCategory: promo.targetValue)),
        );
        return;
      case HomePromotionTargetType.post:
        await Navigator.push(
          context,
          slideFadeRoute(
            ProviderPostsPage(
              initialQuery: promo.query.isEmpty
                  ? promo.targetValue
                  : promo.query,
              initialCategory: promo.category.isEmpty ? null : promo.category,
            ),
          ),
        );
        return;
      case HomePromotionTargetType.page:
        final page = promo.targetValue.trim().toLowerCase();
        if (page == 'favorites') {
          await Navigator.push(context, slideFadeRoute(const FavoritesPage()));
          return;
        }
        if (page == 'providers') {
          await Navigator.push(
            context,
            slideFadeRoute(const ProviderHomePage()),
          );
          return;
        }
        await Navigator.push(context, slideFadeRoute(const SearchPage()));
        return;
      case HomePromotionTargetType.service:
      case HomePromotionTargetType.search:
        await Navigator.push(
          context,
          slideFadeRoute(
            SearchPage(
              initialQuery: promo.query.isEmpty
                  ? promo.targetValue
                  : promo.query,
              initialCategory: promo.category.isEmpty ? null : promo.category,
            ),
          ),
        );
        return;
    }
  }
}

class _PromoBannerCard extends StatelessWidget {
  final HomePromotion slide;
  final VoidCallback onTap;

  const _PromoBannerCard({required this.slide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: const Color(0xFF10203A),
      fontWeight: FontWeight.w800,
      height: 1.0,
      letterSpacing: -0.7,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 0.42;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _paletteForPromotion(slide),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 16),
                blurRadius: 20,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    _PromoImage(
                      promotion: slide,
                      width: imageWidth,
                      height: double.infinity,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE17A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          slide.badgeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        slide.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1656E8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            slide.ctaLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromoImage extends StatelessWidget {
  final HomePromotion promotion;
  final double width;
  final double height;

  const _PromoImage({
    required this.promotion,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackAsset = _promotionFallbackAsset(promotion);
    final primarySource = promotion.imageUrl.trim().isNotEmpty
        ? promotion.imageUrl.trim()
        : fallbackAsset;
    final fallbackWidget = fallbackAsset.isNotEmpty
        ? SafeImage(
            source: fallbackAsset,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: _promoImagePlaceholder(width),
          )
        : _promoImagePlaceholder(width);

    return SafeImage(
      source: primarySource,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: fallbackWidget,
      errorBuilder: fallbackWidget,
    );
  }
}

class _PromoDot extends StatelessWidget {
  final bool active;

  const _PromoDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: active ? 22 : 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : const Color(0xFFD1D9E7),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

List<Color> _paletteForPromotion(HomePromotion promotion) {
  final key = promotion.category.trim().toLowerCase().isNotEmpty
      ? promotion.category.trim().toLowerCase()
      : promotion.targetType.name;
  switch (key) {
    case 'cleaner':
      return const [Color(0xFFE8F0FF), Color(0xFF4D7CFE)];
    case 'plumber':
      return const [Color(0xFFEFFBF6), Color(0xFF18B77A)];
    case 'electrician':
      return const [Color(0xFFFFF3E8), Color(0xFFFF9A3C)];
    case 'home appliance':
      return const [Color(0xFFF2F0FF), Color(0xFF7C5CFF)];
    case 'home maintenance':
      return const [Color(0xFFFFF8E8), Color(0xFFE6B325)];
    default:
      return const [Color(0xFFEAF2FF), Color(0xFF3B82F6)];
  }
}

String _promotionFallbackAsset(HomePromotion promotion) {
  final category = promotion.category.trim().toLowerCase();
  final targetValue = promotion.targetValue.trim().toLowerCase();
  final query = promotion.query.trim().toLowerCase();
  final haystack = '$category $targetValue $query';

  if (haystack.contains('house cleaning')) {
    return 'assets/images/cleaning/house-cleaning.jpg';
  }
  if (haystack.contains('move-in') || haystack.contains('move out')) {
    return 'assets/images/cleaning/move-in-out-cleaning.jpg';
  }
  if (haystack.contains('office cleaning')) {
    return 'assets/images/cleaning/office-cleaning.jpg';
  }
  if (haystack.contains('pipe leak')) {
    return 'assets/images/plumber/pipe-leak.jpg';
  }
  if (haystack.contains('toilet')) {
    return 'assets/images/plumber/toilet-repair.jpg';
  }
  if (haystack.contains('water installation')) {
    return 'assets/images/plumber/water-installation.jpg';
  }
  if (haystack.contains('power outage')) {
    return 'assets/images/electrician/power-outages-fix.jpg';
  }
  if (haystack.contains('fan') || haystack.contains('light')) {
    return 'assets/images/electrician/fan-installation.jpg';
  }
  if (haystack.contains('wiring')) {
    return 'assets/images/electrician/wiring-repair.jpg';
  }
  if (haystack.contains('air conditioner')) {
    return 'assets/images/home_appliance_repair/ac-repair.jpg';
  }
  if (haystack.contains('washing machine')) {
    return 'assets/images/home_appliance_repair/washing-machine-repair.jpg';
  }
  if (haystack.contains('refrigerator')) {
    return 'assets/images/home_appliance_repair/refrigerator-repair.jpg';
  }
  if (haystack.contains('furniture')) {
    return 'assets/images/home_maintenance/furniture-repair.jpg';
  }
  if (haystack.contains('shelf') || haystack.contains('curtain')) {
    return 'assets/images/home_maintenance/shelf-curtain-installation.jpg';
  }
  if (haystack.contains('door') || haystack.contains('window')) {
    return 'assets/images/home_maintenance/doorwindow-repair.jpg';
  }

  switch (category) {
    case 'cleaner':
      return 'assets/images/cleaning/house-cleaning.jpg';
    case 'plumber':
      return 'assets/images/plumber/pipe-leak.jpg';
    case 'electrician':
      return 'assets/images/electrician/power-outages-fix.jpg';
    case 'home appliance':
      return 'assets/images/home_appliance_repair/ac-repair.jpg';
    case 'home maintenance':
      return 'assets/images/home_maintenance/furniture-repair.jpg';
    default:
      return '';
  }
}

Widget _promoImagePlaceholder(double width) {
  return DecoratedBox(
    decoration: const BoxDecoration(color: Color(0xFFE5EDF8)),
    child: SizedBox(
      width: width,
      child: const Center(
        child: Icon(Icons.campaign_rounded, color: AppColors.primary, size: 34),
      ),
    ),
  );
}

class _FinderHeaderLoading extends StatelessWidget {
  const _FinderHeaderLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerPlaceholder.circular(size: 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerPlaceholder(width: 110, height: 14, borderRadius: 999),
              SizedBox(height: 8),
              ShimmerPlaceholder(width: 160, height: 22, borderRadius: 999),
              SizedBox(height: 10),
              ShimmerPlaceholder(width: 120, height: 28, borderRadius: 999),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: const [
            ShimmerPlaceholder(width: 40, height: 40, borderRadius: 12),
            SizedBox(height: 10),
            ShimmerPlaceholder(width: 40, height: 40, borderRadius: 12),
          ],
        ),
      ],
    );
  }
}

class _HeaderLocationPill extends StatelessWidget {
  final String city;

  const _HeaderLocationPill({required this.city});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFEEF4FF).withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 230),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 6),
          Text(
            city,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badgeText;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 36),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 52),
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : AppColors.primaryDark,
                size: 20,
              ),
            ),
            if (badgeText != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeText!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderPostSection extends StatelessWidget {
  const _ProviderPostSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ProviderPostState.loading,
      builder: (context, postLoading, _) {
        return ValueListenableBuilder<List<ProviderPostItem>>(
          valueListenable: ProviderPostState.allPosts,
          builder: (context, allPosts, _) {
            // Priority: use allPosts for better lookup if available
            final rawPosts = allPosts.isNotEmpty
                ? allPosts
                : ProviderPostState.posts.value;
            final posts = _newestPostPerProvider(rawPosts);

            if (posts.isEmpty && postLoading) {
              return const ProviderPostShimmerList();
            }
            if (posts.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                SectionTitle(
                  title: 'Top Recommendations',
                  actionLabel: 'View all',
                  onAction: () => Navigator.push(
                    context,
                    slideFadeRoute(const ProviderPostsPage()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...posts.take(6).map((item) => _ProviderPostTile(post: item)),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProviderPostTile extends StatelessWidget {
  final ProviderPostItem post;

  const _ProviderPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tierStr = post.subscriptionTier.toLowerCase().trim();
    final isElite = tierStr == 'elite';
    final isProfessional = tierStr == 'professional';
    final accentColor = isElite
        ? const Color(0xFFF59E0B)
        : (isProfessional ? const Color(0xFF3B82F6) : null);

    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isElite
            ? (isDark ? const Color(0xFF2A2112) : const Color(0xFFFFF8EC))
            : accentColor != null
            ? accentColor.withValues(alpha: isDark ? 0.12 : 0.04)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isElite
                ? Colors.black.withValues(alpha: 0.04)
                : accentColor != null
                ? accentColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isElite
            ? null
            : Border.all(
                color: accentColor != null
                    ? accentColor.withValues(alpha: 0.5)
                    : theme.dividerColor.withValues(alpha: 0.5),
                width: isProfessional ? 1.5 : 1,
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'provider-post-${post.id}',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162133) : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: post.avatarPath.trim().isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: AppColors.primary,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeImage(
                        isAvatar: true,
                        source: post.avatarPath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (post.isVerified ||
                    post.subscriptionTier.toLowerCase().trim() != 'basic') ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (post.isVerified) const VerifiedBadge(size: 11),
                      if (post.subscriptionTier.toLowerCase().trim() != 'basic')
                        SubscriptionBadge.fromString(
                          post.subscriptionTier,
                          size: 14,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: Theme.of(context).dividerColor,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      post.availableNow ? Icons.circle : Icons.circle_outlined,
                      size: 8,
                      color: post.availableNow
                          ? const Color(0xFF10B981)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.availableNow ? "Available now" : "Currently closed",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: post.availableNow
                            ? const Color(0xFF10B981)
                            : theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _HomePostPill(text: post.category),
                    const SizedBox(width: 8),
                    _HomePostPill(
                      text: LocationOptions.districtFromArea(post.area),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return PressableScale(
      onTap: () => _openProfile(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openProfile(context),
          borderRadius: BorderRadius.circular(16),
          child: isElite
              ? PremiumOutline(radius: 16, borderWidth: 2, child: card)
              : card,
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    final provider = ProviderItem.fromPost(post);
    Navigator.push(
      context,
      slideFadeRoute(ProviderDetailPage(provider: provider)),
    );
  }
}

List<ProviderPostItem> _newestPostPerProvider(List<ProviderPostItem> source) {
  final latestByProvider = <String, ProviderPostItem>{};
  for (final post in source) {
    final key = _providerKey(post);
    final existing = latestByProvider[key];
    if (existing == null || _isNewerProviderPost(post, existing)) {
      latestByProvider[key] = post;
    }
  }
  final deduped = latestByProvider.values.toList(growable: false);
  deduped.sort(_compareHomePosts);
  return deduped;
}

String _providerKey(ProviderPostItem post) {
  final uid = post.providerUid.trim().toLowerCase();
  if (uid.isNotEmpty) return uid;
  final name = post.providerName.trim().toLowerCase();
  if (name.isNotEmpty) return name;
  return post.id;
}

bool _isNewerProviderPost(ProviderPostItem left, ProviderPostItem right) {
  final leftAt =
      left.updatedAt ??
      left.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final rightAt =
      right.updatedAt ??
      right.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
  final byTime = leftAt.compareTo(rightAt);
  if (byTime != 0) return byTime > 0;
  return left.id.compareTo(right.id) > 0;
}

int _compareHomePosts(ProviderPostItem a, ProviderPostItem b) {
  final tierA = _homeTierPriority(a.subscriptionTier);
  final tierB = _homeTierPriority(b.subscriptionTier);
  if (tierA != tierB) return tierB.compareTo(tierA);

  if (a.availableNow != b.availableNow) {
    return a.availableNow ? -1 : 1;
  }

  final right =
      b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final left =
      a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final byTime = right.compareTo(left);
  if (byTime != 0) return byTime;
  return a.id.compareTo(b.id);
}

int _homeTierPriority(String? tier) {
  final normalized = (tier ?? '').toLowerCase().trim();
  if (normalized == 'elite') return 2;
  if (normalized == 'professional') return 1;
  return 0;
}

class _EliteProvidersSection extends StatelessWidget {
  const _EliteProvidersSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ProviderPostState.loading,
      builder: (context, loading, _) {
        return ValueListenableBuilder<List<ProviderPostItem>>(
          valueListenable: ProviderPostState.allPosts,
          builder: (context, allPosts, _) {
            // Priority: use allPosts for better lookup if available
            final rawPosts = allPosts.isNotEmpty
                ? allPosts
                : ProviderPostState.posts.value;
            final elitePosts = _newestPostPerProvider(
              rawPosts
                  .where(
                    (p) => p.subscriptionTier.toLowerCase().trim() == 'elite',
                  )
                  .toList(growable: false),
            );

            if (elitePosts.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: 'Top Tier Providers',
                  actionLabel: 'See all',
                  onAction: () => Navigator.push(
                    context,
                    slideFadeRoute(const SearchPage()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 208,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: elitePosts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _EliteProviderCard(post: elitePosts[index]);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EliteProviderCard extends StatelessWidget {
  final ProviderPostItem post;

  const _EliteProviderCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    const accentColor = Color(0xFFF59E0B); // Gold for Elite
    final card = Container(
      width: rs.dimension(200),
      padding: rs.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(rs.radius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: rs.dimension(20),
                backgroundColor: AppColors.background,
                backgroundImage: post.avatarPath.isNotEmpty
                    ? safeImageProvider(post.avatarPath)
                    : null,
                child: post.avatarPath.isEmpty
                    ? Icon(Icons.person, color: accentColor, size: rs.icon(20))
                    : null,
              ),
              rs.gapW(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.providerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    rs.gapH(4),
                    Wrap(
                      spacing: rs.space(8),
                      runSpacing: rs.space(6),
                      children: [
                        if (post.isVerified) const VerifiedBadge(size: 10),
                        const SubscriptionBadge(
                          tier: SubscriptionTier.elite,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          rs.gapH(10),
          Text(
            post.details,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.star_rounded, size: rs.icon(14), color: accentColor),
              rs.gapW(4),
              Text(
                post.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                post.availableNow ? "Online" : "Away",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: post.availableNow ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return PressableScale(
      onTap: () => _openProfile(context),
      child: PremiumOutline(radius: 16, borderWidth: 2, child: card),
    );
  }

  void _openProfile(BuildContext context) {
    final provider = ProviderItem.fromPost(post);
    Navigator.push(
      context,
      slideFadeRoute(ProviderDetailPage(provider: provider)),
    );
  }
}

class _HomePostPill extends StatelessWidget {
  final String text;

  const _HomePostPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
