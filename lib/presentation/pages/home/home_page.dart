import 'package:flutter/material.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/catalog_state.dart';
import '../../state/profile_image_state.dart';
import '../../state/profile_settings_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/section_title.dart';
import '../../widgets/service_card.dart';
import '../chat/chat_list_page.dart';
import '../providers/provider_home_page.dart';
import '../providers/provider_detail_page.dart';
import '../providers/provider_posts_page.dart';
import '../search/search_page.dart';

class HomePage extends StatelessWidget {
  static const String routeName = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _TopHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _SearchBar(),
                  const SizedBox(height: AppSpacing.md),
                  const _FeaturedBanner(),
                  const SizedBox(height: AppSpacing.lg),
                  const _ProviderPostSection(),
                  SectionTitle(
                    title: 'Browse all categories',
                    actionLabel: 'View all',
                    onAction: () => Navigator.push(
                      context,
                      slideFadeRoute(const ProviderHomePage()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ValueListenableBuilder(
                    valueListenable: CatalogState.categories,
                    builder: (context, categories, _) {
                      if (categories.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return CategoryChip(
                              category: category,
                              onTap: () => Navigator.push(
                                context,
                                slideFadeRoute(
                                  SearchPage(initialCategory: category.name),
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
                  ValueListenableBuilder(
                    valueListenable: CatalogState.services,
                    builder: (context, services, child) {
                      final popular = CatalogState.popularServices(limit: 6);
                      if (popular.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return SizedBox(
                        height: 230,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
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
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionTitle(title: 'For your home'),
                  const SizedBox(height: AppSpacing.md),
                  const _HomeGrid(),
                  const SizedBox(height: AppSpacing.lg),
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
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.home),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProfileFormData>(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          backgroundColor: const Color(0xFFEAF1FF),
                          backgroundImage: image,
                          child: image == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 18,
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
                          'Welcome back',
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
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const ChatListPage()),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        slideFadeRoute(const ChatListPage()),
                      ),
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
                          Icons.message_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
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
    return ValueListenableBuilder<List<ProviderPostItem>>(
      valueListenable: ProviderPostState.posts,
      builder: (context, posts, _) {
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(post.avatarPath),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.providerName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '\$${post.ratePerHour.toStringAsFixed(0)}/hr',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${post.service} • ${post.timeLabel}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                post.details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _HomePostPill(text: post.category),
                  _HomePostPill(text: post.area),
                  if (post.availableNow)
                    const _HomePostPill(text: 'Available now'),
                ],
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
      slideFadeRoute(ProviderDetailPage(provider: _providerFromPost(post))),
    );
  }

  ProviderItem _providerFromPost(ProviderPostItem seed) {
    final role = seed.category.trim().isEmpty ? 'Cleaner' : seed.category;
    final imagePath = seed.avatarPath.startsWith('assets/')
        ? seed.avatarPath
        : 'assets/images/profile.jpg';
    final services = _servicesForProvider(seed);
    return ProviderItem(
      uid: seed.providerUid.trim(),
      name: seed.providerName.trim().isEmpty
          ? 'Service Provider'
          : seed.providerName.trim(),
      role: role,
      rating: 4.8,
      imagePath: imagePath,
      accentColor: _accentFromCategory(role),
      services: services,
      providerType: seed.providerType,
      companyName: seed.providerCompanyName.trim(),
      maxWorkers: seed.providerMaxWorkers < 1 ? 1 : seed.providerMaxWorkers,
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
      final service = item.service.trim();
      if (service.isNotEmpty) values.add(service);
    }

    if (values.isEmpty && seed.service.trim().isNotEmpty) {
      values.add(seed.service.trim());
    }
    final services = values.toList(growable: false)..sort();
    return services;
  }

  Color _accentFromCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'plumber':
        return const Color(0xFF0E8AD6);
      case 'electrician':
        return const Color(0xFFF59E0B);
      case 'cleaner':
        return const Color(0xFF10B981);
      case 'home appliance':
      case 'appliance':
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
    }
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
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomeGrid extends StatelessWidget {
  const _HomeGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ImageTile(
            title: 'Interior painting',
            color: Color(0xFFEF4444),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ImageTile(title: 'House Painting', color: Color(0xFF22C55E)),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String title;
  final Color color;

  const _ImageTile({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 217), color.withValues(alpha: 166)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
