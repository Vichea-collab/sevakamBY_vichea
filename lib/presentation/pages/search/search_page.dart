import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/service.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/pressable_scale.dart';

class SearchPage extends StatefulWidget {
  static const String routeName = '/search';

  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum _SortOption { popular, rating, priceHigh, priceLow }

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  _SortOption? _sortOption;
  int _visibleCount = 10;
  final List<String> _recentSearches = List<String>.from(MockData.recentSearches);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filteredCategories = query.isEmpty
        ? MockData.categories
        : MockData.categories
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();
    final filteredPopular = query.isEmpty
        ? List<ServiceItem>.from(MockData.services)
        : MockData.services
            .where((s) =>
                s.title.toLowerCase().contains(query) ||
                s.subtitle.toLowerCase().contains(query) ||
                s.category.toLowerCase().contains(query))
            .toList();

    switch (_sortOption) {
      case _SortOption.rating:
        filteredPopular.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.priceHigh:
        filteredPopular.sort(
          (a, b) => _extractPrice(b.subtitle).compareTo(_extractPrice(a.subtitle)),
        );
        break;
      case _SortOption.priceLow:
        filteredPopular.sort(
          (a, b) => _extractPrice(a.subtitle).compareTo(_extractPrice(b.subtitle)),
        );
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      Text('Recently',
                          style: Theme.of(context).textTheme.titleMedium),
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
                  if (_query.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        '${filteredPopular.length} results for "${_query.trim()}" around Phnom Penh',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Browse all categories',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return CategoryChip(
                          category: filteredCategories[index],
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
                  Text('Available Skills',
                      style: Theme.of(context).textTheme.titleMedium),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...visibleServices.map((item) => _ServiceListTile(item: item)),
                  if (filteredPopular.length > _visibleCount)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _visibleCount += 10),
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
                  Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  _SortOptionTile(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Most Popular',
                    selected: selectedSort == _SortOption.popular,
                    onTap: () => modalSetState(() => selectedSort = _SortOption.popular),
                  ),
                  _SortOptionTile(
                    icon: Icons.star_border_rounded,
                    label: 'Ratings',
                    selected: selectedSort == _SortOption.rating,
                    onTap: () => modalSetState(() => selectedSort = _SortOption.rating),
                  ),
                  _SortOptionTile(
                    icon: Icons.payments_outlined,
                    label: 'Price (High to Low)',
                    selected: selectedSort == _SortOption.priceHigh,
                    onTap: () => modalSetState(() => selectedSort = _SortOption.priceHigh),
                  ),
                  _SortOptionTile(
                    icon: Icons.payments_outlined,
                    label: 'Price (Low to High)',
                    selected: selectedSort == _SortOption.priceLow,
                    onTap: () => modalSetState(() => selectedSort = _SortOption.priceLow),
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
      _recentSearches.removeWhere((item) => item.toLowerCase() == text.toLowerCase());
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
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Search for "Indoor Cleaning"',
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _ServiceListTile extends StatelessWidget {
  final ServiceItem item;

  const _ServiceListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.star,
                        size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 14, color: AppColors.textSecondary),
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
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.textSecondary),
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
        ],
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

  const _ActiveSortPill({
    required this.label,
    required this.onClear,
  });

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
