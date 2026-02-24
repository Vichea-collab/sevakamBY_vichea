import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/service.dart';
import '../../state/catalog_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/pressable_scale.dart';
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

enum _SortOption { popular, rating, priceHigh, priceLow }

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
      case _SortOption.priceHigh:
        filteredPopular.sort(
          (a, b) =>
              _extractPrice(b.subtitle).compareTo(_extractPrice(a.subtitle)),
        );
        break;
      case _SortOption.priceLow:
        filteredPopular.sort(
          (a, b) =>
              _extractPrice(a.subtitle).compareTo(_extractPrice(b.subtitle)),
        );
        break;
      case _SortOption.popular:
      case null:
        break;
    }
    final visibleServices = filteredPopular.take(_visibleCount).toList();

    return Scaffold(
      body: SafeArea(
        child: _bootstrapping && providerPosts.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppStatePanel.loading(title: 'Loading search data'),
              )
            : Column(
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
                    child: ListView(
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
                                onPressed: () =>
                                    setState(_recentSearches.clear),
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
                        if (_query.trim().isNotEmpty ||
                            _selectedCategory != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
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
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              return CategoryChip(
                                category: category,
                                onTap: () => _toggleCategory(category.name),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.md),
                            itemCount: filteredCategories.length,
                          ),
                        ),
                        if (filteredCategories.isEmpty)
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
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
                        ...visibleServices.map(
                          (item) => _ServiceListTile(
                            item: item,
                            providerName: _findMatchedProvider(
                              item.category,
                              item.title,
                              query,
                            )?.name,
                            onTap: () => _openServiceResult(item, query),
                          ),
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
      case _SortOption.priceHigh:
        return 'Price (High to Low)';
      case _SortOption.priceLow:
        return 'Price (Low to High)';
      case _SortOption.popular:
        return 'Most Popular';
    }
  }

  int _extractPrice(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
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
                  _SortOptionTile(
                    icon: Icons.payments_outlined,
                    label: 'Price (High to Low)',
                    selected: selectedSort == _SortOption.priceHigh,
                    onTap: () => modalSetState(
                      () => selectedSort = _SortOption.priceHigh,
                    ),
                  ),
                  _SortOptionTile(
                    icon: Icons.payments_outlined,
                    label: 'Price (Low to High)',
                    selected: selectedSort == _SortOption.priceLow,
                    onTap: () => modalSetState(
                      () => selectedSort = _SortOption.priceLow,
                    ),
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

  ProviderSection? _providerSectionForCategory({
    required String category,
    required String serviceFilter,
    required String query,
  }) {
    final normalizedCategory = category.trim().toLowerCase();
    if (normalizedCategory.isEmpty) return null;
    final normalizedService = _normalizeKey(serviceFilter);
    final normalizedQuery = query.trim().toLowerCase();

    final providersByKey = <String, _ProviderAggregate>{};
    for (final post in _providerPostsForLookup) {
      if (post.category.trim().toLowerCase() != normalizedCategory) continue;
      final providerKey = post.providerUid.trim().isNotEmpty
          ? post.providerUid.trim().toLowerCase()
          : post.providerName.trim().toLowerCase();
      final existing = providersByKey[providerKey];
      if (existing == null) {
        providersByKey[providerKey] = _ProviderAggregate.fromPost(post);
      } else {
        existing.absorb(post);
      }
    }

    var providers = providersByKey.values
        .map(_providerFromAggregate)
        .toList(growable: false);
    if (normalizedService.isNotEmpty) {
      providers = providers
          .where(
            (provider) => provider.services.any(
              (service) => _normalizeKey(service) == normalizedService,
            ),
          )
          .toList(growable: false);
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

  ProviderItem _providerFromAggregate(_ProviderAggregate value) {
    final role = value.category.trim().isEmpty ? 'Cleaner' : value.category;
    return ProviderItem(
      uid: value.providerUid,
      name: value.providerName.isEmpty
          ? 'Service Provider'
          : value.providerName,
      role: role,
      rating: 4.8,
      imagePath: value.avatarPath,
      accentColor: _accentFromCategory(role),
      services: value.services.toList(growable: false)..sort(),
      providerType: value.providerType,
      companyName: value.providerCompanyName,
      maxWorkers: value.providerMaxWorkers,
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.divider,
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
            border: Border.all(color: AppColors.divider),
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
  final String? providerName;
  final VoidCallback onTap;

  const _ServiceListTile({
    required this.item,
    this.providerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 89)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(item.imagePath),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (providerName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              providerName!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.location} • ${item.available ? "Available" : "Closed"} • ${item.etaHours} hrs',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Service Timing: ${item.serviceTime}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
                size: 20,
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: active ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: active ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more,
                size: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: onClear,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(30),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
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
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: 12),
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
