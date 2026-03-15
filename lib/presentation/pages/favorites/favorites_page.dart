import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/favorite_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/provider_card.dart';
import '../providers/provider_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  static const String routeName = '/favorites';

  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_primeFavorites());
  }

  Future<void> _primeFavorites() async {
    try {
      if (ProviderPostState.allPosts.value.isEmpty &&
          !ProviderPostState.allPostsLoading.value) {
        await ProviderPostState.refreshAllForLookup();
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    try {
      await ProviderPostState.refreshAllForLookup();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            children: [
              const _FavoritesHeaderCard(),
              const SizedBox(height: 14),
              Expanded(
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: FavoriteState.favoriteUids,
                  builder: (context, favorites, _) {
                    if (favorites.isEmpty) {
                      return const _FavoritesEmptyState();
                    }

                    return ValueListenableBuilder<bool>(
                      valueListenable: ProviderPostState.allPostsLoading,
                      builder: (context, isLoading, _) {
                        return ValueListenableBuilder<List<ProviderPostItem>>(
                          valueListenable: ProviderPostState.allPosts,
                          builder: (context, allPosts, _) {
                            final posts = allPosts.isNotEmpty
                                ? allPosts
                                : ProviderPostState.posts.value;
                            final favoriteProviders = _favoriteProviders(
                              posts: posts,
                              favorites: favorites,
                            );

                            if (favoriteProviders.isEmpty && isLoading) {
                              return const Center(
                                child: AppStatePanel.loading(
                                  title: 'Loading favorites',
                                  message:
                                      'Fetching the latest saved providers.',
                                ),
                              );
                            }

                            if (favoriteProviders.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: _handleRefresh,
                                color: AppColors.primary,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 8),
                                  children: const [
                                    AppStatePanel.empty(
                                      title: 'Saved providers unavailable',
                                      message:
                                          'Refresh to sync the latest provider listings.',
                                    ),
                                  ],
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: _handleRefresh,
                              color: AppColors.primary,
                              child: GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 0.62,
                                    ),
                                itemCount: favoriteProviders.length,
                                itemBuilder: (context, index) {
                                  final provider = favoriteProviders[index];
                                  final heroTag =
                                      'fav-provider-card-${provider.uid}';
                                  return ProviderCard(
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
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ProviderItem> _favoriteProviders({
    required List<ProviderPostItem> posts,
    required Set<String> favorites,
  }) {
    final latestByUid = <String, ProviderPostItem>{};
    for (final post in posts) {
      final uid = post.providerUid.trim();
      if (uid.isEmpty || !favorites.contains(uid)) continue;
      final current = latestByUid[uid];
      if (current == null || _isNewerPost(post, current)) {
        latestByUid[uid] = post;
      }
    }

    final providers =
        latestByUid.values.map(ProviderItem.fromPost).toList(growable: false)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return providers;
  }

  bool _isNewerPost(ProviderPostItem next, ProviderPostItem current) {
    final nextTime = next.updatedAt ?? next.createdAt;
    final currentTime = current.updatedAt ?? current.createdAt;
    if (nextTime == null && currentTime == null) {
      return next.id.compareTo(current.id) > 0;
    }
    if (nextTime == null) return false;
    if (currentTime == null) return true;
    return nextTime.isAfter(currentTime);
  }
}

class _FavoritesHeaderCard extends StatelessWidget {
  const _FavoritesHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
        children: [
          InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Favorite Providers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 30,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No favorites yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save providers to keep them in one place.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
