import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/provider_card.dart';
import '../../widgets/section_title.dart';
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
                return Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.splashStart,
                                  AppColors.splashEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Service Providers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.search,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: _onSearchChanged,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            isDense: true,
                                            hintText:
                                                'Live provider list from posted offers',
                                            hintStyle: TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_query.trim().isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            _searchDebounce?.cancel();
                                            _searchController.clear();
                                            setState(() => _query = '');
                                          },
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (isLoading && sections.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 18),
                              child: Center(
                                child: AppStatePanel.loading(
                                  title: 'Loading providers',
                                ),
                              ),
                            ),
                          if (!isLoading && sections.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Text(
                                hasQuery
                                    ? 'No providers found for "${_query.trim()}".'
                                    : 'No provider offers available yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          for (final section in sections) ...[
                            SectionTitle(
                              title: section.title,
                              actionLabel: 'View all',
                              onAction: () => Navigator.push(
                                context,
                                slideFadeRoute(
                                  ProviderCategoryPage(section: section),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              height: 278,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  final provider = section.providers[index];
                                  return SizedBox(
                                    width: 178,
                                    child: ProviderCard(
                                      provider: provider,
                                      onDetails: () => Navigator.push(
                                        context,
                                        slideFadeRoute(
                                          ProviderDetailPage(
                                            provider: provider,
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
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                  ),
                  bottomNavigationBar: const AppBottomNav(
                    current: AppBottomTab.home,
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
      rating: 4.8,
      imagePath: item.avatarPath,
      accentColor: _accentFromCategory(role),
      services: item.services.toList(growable: false)..sort(),
      providerType: item.providerType,
      companyName: item.providerCompanyName,
      maxWorkers: item.providerMaxWorkers,
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

class _ProviderAggregate {
  final String providerUid;
  final String providerName;
  final String category;
  final String avatarPath;
  String providerType;
  String providerCompanyName;
  int providerMaxWorkers;
  final Set<String> services;

  _ProviderAggregate({
    required this.providerUid,
    required this.providerName,
    required this.category,
    required this.avatarPath,
    required this.providerType,
    required this.providerCompanyName,
    required this.providerMaxWorkers,
    required this.services,
  });

  factory _ProviderAggregate.fromPost(ProviderPostItem post) {
    final imagePath = post.avatarPath.startsWith('assets/')
        ? post.avatarPath
        : 'assets/images/profile.jpg';
    return _ProviderAggregate(
      providerUid: post.providerUid.trim(),
      providerName: post.providerName.trim(),
      category: post.category.trim(),
      avatarPath: imagePath,
      providerType: post.providerType,
      providerCompanyName: post.providerCompanyName.trim(),
      providerMaxWorkers: post.providerMaxWorkers < 1
          ? 1
          : post.providerMaxWorkers,
      services: post.serviceList
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet(),
    );
  }

  void absorb(ProviderPostItem post) {
    for (final service in post.serviceList) {
      final normalized = service.trim();
      if (normalized.isNotEmpty) {
        services.add(normalized);
      }
    }
    if (post.providerType.trim().toLowerCase() == 'company') {
      providerType = 'company';
      if (post.providerCompanyName.trim().isNotEmpty) {
        providerCompanyName = post.providerCompanyName.trim();
      }
      final maxWorkers = post.providerMaxWorkers < 1
          ? 1
          : post.providerMaxWorkers;
      if (maxWorkers > providerMaxWorkers) {
        providerMaxWorkers = maxWorkers;
      }
    }
  }
}
