import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/service.dart';
import '../../state/catalog_state.dart';
import '../../state/favorite_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/shimmer_loading.dart';
import '../providers/provider_category_page.dart';
import '../providers/provider_posts_page.dart';

class SearchPage extends StatefulWidget {
  static const String routeName = '/search';
  final String initialQuery;
  final String? initialCategory;

  const SearchPage({super.key, this.initialQuery = '', this.initialCategory});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum _SortOption { popular, rating }

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  _SortOption? _sortOption;
  int _visibleCount = 10;
  bool _bootstrapping = true;
  final List<String> _recentSearches = List<String>.from(
    CatalogState.defaultRecentSearches,
  );

  @override
  void initState() {
    super.initState();
    CatalogState.categories.addListener(_onLiveDataChanged);
    CatalogState.services.addListener(_onLiveDataChanged);
    ProviderPostState.posts.addListener(_onLiveDataChanged);
    ProviderPostState.allPosts.addListener(_onLiveDataChanged);
    ProviderPostState.allPostsLoading.addListener(_onLiveDataChanged);
    _query = widget.initialQuery.trim();
    _selectedCategory = widget.initialCategory;
    unawaited(_primeData());
    if (_query.isNotEmpty) {
      _controller.text = _query;
      _controller.selection = TextSelection.collapsed(offset: _query.length);
    }
  }

  @override
  void dispose() {
    CatalogState.categories.removeListener(_onLiveDataChanged);
    CatalogState.services.removeListener(_onLiveDataChanged);
    ProviderPostState.posts.removeListener(_onLiveDataChanged);
    ProviderPostState.allPosts.removeListener(_onLiveDataChanged);
    ProviderPostState.allPostsLoading.removeListener(_onLiveDataChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onLiveDataChanged() {
    if (!mounted) return;
    _safeSetState(() {});
  }

  Future<void> _primeData() async {
    try {
      if (CatalogState.services.value.isEmpty && !CatalogState.loading.value) {
        await CatalogState.refresh();
      }
      if (ProviderPostState.posts.value.isEmpty &&
          !ProviderPostState.loading.value) {
        await ProviderPostState.refresh(page: 1);
      }
      await ProviderPostState.refreshAllForLookup();
    } catch (_) {
      // Keep page usable with partial data on transient failures.
    } finally {
      if (mounted) {
        _safeSetState(() => _bootstrapping = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      await Future.wait([
        CatalogState.refresh(force: true),
        ProviderPostState.refresh(page: 1),
        ProviderPostState.refreshAllForLookup(),
      ]);
    } catch (_) {}
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.postFrameCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
      return;
    }
    setState(fn);
  }

  List<ProviderPostItem> get _providerPostsForLookup {
    final all = ProviderPostState.allPosts.value;
    if (all.isNotEmpty) return all;
    return ProviderPostState.posts.value;
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredCategories = CatalogState.categories.value;
    final providerPosts = _providerPostsForLookup;
    final filteredPopular = CatalogState.services.value.where((service) {
      final serviceKey = _normalizeKey(service.title);
      final matchesProviderName =
          query.isEmpty ||
          providerPosts.any(
            (post) =>
                post.category.toLowerCase() == service.category.toLowerCase() &&
                post.providerName.toLowerCase().contains(query) &&
                post.serviceList.any(
                  (item) => _normalizeKey(item) == serviceKey,
                ),
          );
      final matchesQuery =
          query.isEmpty ||
          service.title.toLowerCase().contains(query) ||
          service.subtitle.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query) ||
          matchesProviderName;
      final matchesCategory =
          _selectedCategory == null || service.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case _SortOption.rating:
        filteredPopular.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.popular:
      case null:
        break;
    }
    final visibleServices = filteredPopular.take(_visibleCount).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: _SearchField(
                      controller: _controller,
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSearchSubmitted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  cacheExtent: 1000,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Recently',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (_recentSearches.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(_recentSearches.clear),
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _recentSearches
                          .map(
                            (label) => _SearchChip(
                              label: label,
                              onTap: () => _useRecentSearch(label),
                            ),
                          )
                          .toList(),
                    ),
                    if (_query.trim().isNotEmpty || _selectedCategory != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Text(
                          _selectedCategory == null
                              ? '${filteredPopular.length} results for "${_query.trim()}" around Phnom Penh'
                              : '${filteredPopular.length} results in "$_selectedCategory" around Phnom Penh',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Browse all categories',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: CatalogState.loading,
                      builder: (context, loading, _) {
                        if (loading && filteredCategories.isEmpty) {
                          return const CategoryShimmerList();
                        }
                        return SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            cacheExtent: 500,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              return CategoryChip(
                                category: category,
                                onTap: () => _toggleCategory(category.name),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSpacing.md),
                            itemCount: filteredCategories.length,
                          ),
                        );
                      },
                    ),
                    if (filteredCategories.isEmpty && !_bootstrapping)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'No categories found.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Provider posts',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _openAllProviderPosts,
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse all live provider posts in one screen.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Available Providers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SortPill(
                          label: 'Filter',
                          onTap: _openSortSheet,
                          active: false,
                          icon: Icons.tune,
                        ),
                        if (_sortOption != null)
                          _ActiveSortPill(
                            label: _sortLabel(_sortOption!),
                            onClear: () => setState(() {
                              _sortOption = null;
                              _visibleCount = 10;
                            }),
                          ),
                        if (_selectedCategory != null)
                          _ActiveSortPill(
                            label: _selectedCategory!,
                            onClear: () => setState(() {
                              _selectedCategory = null;
                              _visibleCount = 10;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_bootstrapping || (CatalogState.loading.value && visibleServices.isEmpty))
                      const SearchServiceShimmerList()
                    else ...[
                      ...visibleServices.map(
                        (item) {
                          final matchedProvider = _findMatchedProvider(
                            item.category,
                            item.title,
                            query,
                          );
                          return _ServiceListTile(
                            item: item,
                            providerUid: matchedProvider?.uid,
                            providerName: matchedProvider?.name,
                            providerRating: matchedProvider?.rating,
                            onTap: () => _openServiceResult(item, query),
                          );
                        },
                      ),
                      if (filteredPopular.length > _visibleCount)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 8),
                          child: Center(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _visibleCount += 10),
                              child: const Text('Load more'),
                            ),
                          ),
                        ),
                      if (filteredPopular.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No services found.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(_SortOption value) {
    switch (value) {
      case _SortOption.rating:
        return 'Ratings';
      case _SortOption.popular:
        return 'Most Popular';
    }
  }

  void _openSortSheet() {
    var selectedSort = _sortOption ?? _SortOption.popular;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  _SortOptionTile(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Most Popular',
                    selected: selectedSort == _SortOption.popular,
                    onTap: () =>
                        modalSetState(() => selectedSort = _SortOption.popular),
                  ),
                  _SortOptionTile(
                    icon: Icons.star_border_rounded,
                    label: 'Ratings',
                    selected: selectedSort == _SortOption.rating,
                    onTap: () =>
                        modalSetState(() => selectedSort = _SortOption.rating),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.splashEnd],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sortOption = selectedSort;
                            _visibleCount = 10;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
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

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _visibleCount = 10;
    });
  }

  void _onSearchSubmitted(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    setState(() {
      _query = text;
      _visibleCount = 10;
      _recentSearches.removeWhere(
        (item) => item.toLowerCase() == text.toLowerCase(),
      );
      _recentSearches.insert(0, text);
      if (_recentSearches.length > 8) {
        _recentSearches.removeLast();
      }
    });
  }

  void _useRecentSearch(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _onSearchSubmitted(text);
  }

  void _toggleCategory(String category) {
    setState(() {
      _visibleCount = 10;
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
  }

  void _openAllProviderPosts() {
    Navigator.push(
      context,
      slideFadeRoute(
        ProviderPostsPage(
          initialQuery: _query.trim(),
          initialCategory: _selectedCategory,
        ),
      ),
    );
  }

  void _openServiceResult(ServiceItem item, String query) {
    final section = _providerSectionForCategory(
      category: item.category,
      serviceFilter: item.title,
      query: query,
    );
    if (section == null || section.providers.isEmpty) {
      AppToast.info(
        context,
        'No provider found for ${item.title} yet. Try another service.',
      );
      return;
    }
    Navigator.push(
      context,
      slideFadeRoute(ProviderCategoryPage(section: section)),
    );
  }

  ProviderItem? _findMatchedProvider(
    String category,
    String serviceName,
    String query,
  ) {
    final exactSection = _providerSectionForCategory(
      category: category,
      serviceFilter: serviceName,
      query: query,
    );
    if (exactSection != null && exactSection.providers.isNotEmpty) {
      return exactSection.providers.first;
    }
    return null;
  }

  ProviderSection? _providerSectionForCategory({
    required String category,
    required String serviceFilter,
    required String query,
  }) {
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory.isEmpty) return null;
    final normalizedService = _normalizeKey(serviceFilter);
    final normalizedQuery = query.trim().toLowerCase();

    final providersByKey = <String, List<ProviderPostItem>>{};
    for (final post in _providerPostsForLookup) {
      if (post.category.trim().toLowerCase() != normalizedCategory) continue;
      final providerKey = post.providerUid.trim().isNotEmpty
          ? post.providerUid.trim().toLowerCase()
          : post.providerName.trim().toLowerCase();
      providersByKey.putIfAbsent(providerKey, () => []).add(post);
    }

    var providers = providersByKey.values
        .map((posts) => ProviderItem.fromPost(posts.first))
        .toList(growable: false);

    if (normalizedService.isNotEmpty) {
      providers = providers.where((provider) {
        final key = provider.uid.trim().isNotEmpty 
            ? provider.uid.trim().toLowerCase() 
            : provider.name.trim().toLowerCase();
        final posts = providersByKey[key] ?? [];
        return posts.any((post) => post.serviceList.any((s) => _normalizeKey(s) == normalizedService));
      }).toList(growable: false);
    }
    if (normalizedQuery.isNotEmpty) {
      providers = providers
          .where((provider) {
            final inName = provider.name.toLowerCase().contains(
              normalizedQuery,
            );
            final inService = provider.services.any(
              (service) => service.toLowerCase().contains(normalizedQuery),
            );
            return inName || inService;
          })
          .toList(growable: false);
    }
    if (providers.isEmpty) return null;

    providers.sort((a, b) => a.name.compareTo(b.name));
    return ProviderSection(
      title: '${category.trim()} Providers',
      category: category.trim(),
      providers: providers,
    );
  }

  String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: focused ? AppColors.primary : Theme.of(context).dividerColor,
          width: focused ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                hintText: 'Search name, category, or service',
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SearchChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _ServiceListTile extends StatelessWidget {
  final ServiceItem item;
  final String? providerUid;
  final String? providerName;
  final double? providerRating;
  final VoidCallback onTap;

  const _ServiceListTile({
    required this.item,
    this.providerUid,
    this.providerName,
    this.providerRating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayRating = providerRating ?? item.rating;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
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
                tag: 'service-${item.title}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SafeImage(
                      source: item.imagePath,
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
                            item.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (providerUid != null)
                          ValueListenableBuilder<Set<String>>(
                            valueListenable: FavoriteState.favoriteUids,
                            builder: (context, favorites, _) {
                              final isFav = favorites.contains(providerUid!);
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => FavoriteState.toggleFavorite(providerUid!),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isFav
                                          ? AppColors.danger.withValues(alpha: 0.1)
                                          : Theme.of(context).dividerColor.withValues(alpha: 0.05),
                                    ),
                                    child: Icon(
                                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: isFav ? AppColors.danger : AppColors.textSecondary,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          displayRating.toStringAsFixed(1),
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
                          item.available ? Icons.circle : Icons.circle_outlined,
                          size: 8,
                          color: item.available ? const Color(0xFF10B981) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.available ? "Available Now" : "Currently Closed",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.available ? const Color(0xFF10B981) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (providerName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 10,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              providerName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.location} • ${item.etaHours}h arrival',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
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
}

class _SortPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;
  final IconData? icon;

  const _SortPill({
    required this.label,
    required this.onTap,
    required this.active,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : Theme.of(context).dividerColor,
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: active ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: active ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: active ? Colors.white : AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSortPill extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _ActiveSortPill({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.splashEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 10),
          PressableScale(
            onTap: onClear,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.icon,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).hintColor),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
