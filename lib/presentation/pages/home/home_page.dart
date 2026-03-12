import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/catalog_state.dart';
import '../../state/chat_state.dart';
import '../../state/profile_image_state.dart';
import '../../state/profile_settings_state.dart';
import '../../state/provider_post_state.dart';

import '../../widgets/category_chip.dart';
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

class HomePage extends StatefulWidget {
  static const String routeName = '/home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Duration _doublePullWindow = Duration(seconds: 2);
  DateTime? _lastPullAt;
  bool _refreshInProgress = false;

  Future<void> _handleRefresh() async {
    final now = DateTime.now();
    final last = _lastPullAt;
    final isSecondPull =
        last != null && now.difference(last) <= _doublePullWindow;

    if (!isSecondPull) {
      _lastPullAt = now;
      return;
    }

    _lastPullAt = null;
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      await Future.wait<void>([
        CatalogState.refresh(force: true),
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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const _TopHeader(),
            SliverPadding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.xl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SearchBar(),
                  const SizedBox(height: AppSpacing.md),
                  const _FeaturedBanner(),
                  const SizedBox(height: AppSpacing.lg),
                  SectionTitle(
                    title: 'Browse all categories',
                    actionLabel: 'View all',
                    onAction: () => Navigator.push(
                      context,
                      slideFadeRoute(const ProviderHomePage()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                            height: 135,
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
                                  const SizedBox(width: AppSpacing.md),
                              itemCount: categories.length,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionTitle(
                    title: 'Popular services',
                    actionLabel: 'See all',
                    onAction: () => Navigator.push(
                      context,
                      slideFadeRoute(const SearchPage()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                            height: 240,
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
                                  const SizedBox(width: AppSpacing.md),
                              itemCount: popular.length,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
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

  @override
  Widget build(BuildContext context) {
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
          return Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.splashStart, AppColors.splashEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 230),
                          shape: BoxShape.circle,
                        ),
                        child: ValueListenableBuilder(
                          valueListenable: ProfileImageState.listenableForRole(
                            isProvider: false,
                          ),
                          builder: (context, value, child) {
                            final image = ProfileImageState.avatarProvider(
                              isProvider: false,
                            );
                            return CircleAvatar(
                              radius: 19,
                              backgroundColor: AppColors.background,
                              backgroundImage: image,
                              child: image == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Finder',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PressableScale(
                        onTap: openChats,
                        child: InkWell(
                          onTap: openChats,
                          borderRadius: BorderRadius.circular(10),
                          child: ValueListenableBuilder<int>(
                            valueListenable: ChatState.unreadCount,
                            builder: (context, unreadThreads, _) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    height: 34,
                                    width: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x20000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.message_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  if (unreadThreads > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.2,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          unreadThreads > 99
                                              ? '99+'
                                              : '$unreadThreads',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 9,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      PressableScale(
                        onTap: openFavorites,
                        child: InkWell(
                          onTap: openFavorites,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x20000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_border_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.primaryDark,
                              ),
                        ),
                      ],
                    ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, slideFadeRoute(const SearchPage())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search services',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Limited offer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '25% off cleaning',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Book now and get fast support today.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Book now'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/plumber_category.jpg',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
        ],
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
          valueListenable: ProviderPostState.posts,
          builder: (context, posts, _) {
            if (posts.isEmpty && postLoading) {
              return const ProviderPostShimmerList();
            }
            if (posts.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                SectionTitle(
                  title: 'Latest provider posts',
                  actionLabel: 'View all',
                  onAction: () => Navigator.push(
                    context,
                    slideFadeRoute(const ProviderPostsPage()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...posts.take(3).map((item) => _ProviderPostTile(post: item)),
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
    return PressableScale(
      onTap: () => _openProfile(context),
      child: InkWell(
        onTap: () => _openProfile(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
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
                    color: AppColors.background,
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        if (post.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          post.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF59E0B),
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 12, color: Theme.of(context).dividerColor),
                        const SizedBox(width: 8),
                        Icon(
                          post.availableNow ? Icons.circle : Icons.circle_outlined,
                          size: 8,
                          color: post.availableNow ? const Color(0xFF10B981) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.availableNow ? "Available now" : "Currently closed",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: post.availableNow ? const Color(0xFF10B981) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _HomePostPill(text: post.category),
                              _HomePostPill(text: post.area),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Theme.of(context).dividerColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      slideFadeRoute(ProviderDetailPage(
        provider: _providerFromPost(post),
        heroTag: 'provider-post-${post.id}',
      )),
    );
  }

  ProviderItem _providerFromPost(ProviderPostItem seed) {
    final role = seed.category.trim().isEmpty ? 'Cleaner' : seed.category;
    final services = _servicesForProvider(seed);
    return ProviderItem(
      uid: seed.providerUid.trim(),
      name: seed.providerName.trim().isEmpty
          ? 'Service Provider'
          : seed.providerName.trim(),
      role: role,
      rating: seed.rating,
      imagePath: seed.avatarPath,
      accentColor: accentForCategory(role),
      services: services,
      blockedDates: seed.blockedDates,
    );
  }

  List<String> _servicesForProvider(ProviderPostItem seed) {
    final allPosts = ProviderPostState.allPosts.value;
    final lookupPosts = allPosts.isNotEmpty
        ? allPosts
        : ProviderPostState.posts.value;
    final seedUid = seed.providerUid.trim().toLowerCase();
    final seedName = seed.providerName.trim().toLowerCase();

    final values = <String>{};
    for (final item in lookupPosts) {
      final sameProvider = seedUid.isNotEmpty
          ? item.providerUid.trim().toLowerCase() == seedUid
          : item.providerName.trim().toLowerCase() == seedName;
      if (!sameProvider) continue;
      for (final service in item.serviceList) {
        final normalized = service.trim();
        if (normalized.isNotEmpty) values.add(normalized);
      }
    }

    if (values.isEmpty) {
      values.addAll(seed.serviceList);
    }
    final services = values.toList(growable: false)..sort();
    return services;
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
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
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
