import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../state/catalog_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProviderPostPage extends StatefulWidget {
  static const String routeName = '/provider/post';

  const ProviderPostPage({super.key});

  @override
  State<ProviderPostPage> createState() => _ProviderPostPageState();
}

class _ProviderPostPageState extends State<ProviderPostPage> {
  late String _selectedCategory;
  final Set<String> _selectedServices = <String>{};
  final _priceController = TextEditingController(text: '12');
  final _areaController = TextEditingController(text: 'Phnom Penh, Cambodia');
  final _detailsController = TextEditingController();
  bool _availableNow = true;
  bool _posting = false;

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD3DDEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'Cleaner';
    CatalogState.categories.addListener(_syncSelectionFromCatalog);
    CatalogState.services.addListener(_syncSelectionFromCatalog);
    _syncSelectionFromCatalog();
  }

  @override
  void dispose() {
    CatalogState.categories.removeListener(_syncSelectionFromCatalog);
    CatalogState.services.removeListener(_syncSelectionFromCatalog);
    _priceController.dispose();
    _areaController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _syncSelectionFromCatalog() {
    final categories = CatalogState.categories.value;
    if (categories.isEmpty) return;
    final nextCategory =
        categories
            .where(
              (item) =>
                  item.name.trim().toLowerCase() ==
                  _selectedCategory.trim().toLowerCase(),
            )
            .isNotEmpty
        ? _selectedCategory
        : categories.first.name;
    final services = CatalogState.servicesForCategory(nextCategory);
    final selected = _selectedServices
        .where((item) => services.contains(item))
        .toSet();
    if (selected.isEmpty && services.isNotEmpty) {
      selected.add(services.first);
    }
    if (!mounted) {
      _selectedCategory = nextCategory;
      _selectedServices
        ..clear()
        ..addAll(selected);
      return;
    }
    final sameSelection =
        _selectedServices.length == selected.length &&
        _selectedServices.containsAll(selected);
    if (_selectedCategory == nextCategory && sameSelection) {
      return;
    }
    setState(() {
      _selectedCategory = nextCategory;
      _selectedServices
        ..clear()
        ..addAll(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const AppTopBar(title: 'Post', showBack: false),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What service can you offer?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a provider post so clients can find you faster.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel(label: 'Category*'),
                      _PickerField(
                        label: _selectedCategory,
                        onTap: _pickCategory,
                      ),
                      const SizedBox(height: 8),
                      _FieldLabel(label: 'Service*'),
                      _PickerField(
                        label: _selectedServiceLabel,
                        onTap: _pickService,
                      ),
                      const SizedBox(height: 8),
                      _FieldLabel(label: 'Rate per hour (USD)*'),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration(
                                hintText: 'Enter your hourly rate',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              '/hour',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _FieldLabel(label: 'Service area*'),
                      TextField(
                        controller: _areaController,
                        decoration: _fieldDecoration(
                          hintText: 'Example: Toul Kork, Phnom Penh',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _availableNow,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Available now'),
                        onChanged: (value) =>
                            setState(() => _availableNow = value),
                      ),
                      _FieldLabel(label: 'Post details*'),
                      TextField(
                        controller: _detailsController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: _fieldDecoration(
                          hintText:
                              'Example: Professional team, tools included, same-day support.',
                        ),
                      ),
                      const Spacer(),
                      PrimaryButton(
                        label: _posting ? 'Posting...' : 'Post',
                        onPressed: _posting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.post),
    );
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (_selectedCategory.isEmpty ||
        _selectedServices.isEmpty ||
        price <= 0 ||
        _areaController.text.trim().isEmpty ||
        _detailsController.text.trim().isEmpty) {
      AppToast.error(context, 'Please complete all fields.');
      return;
    }
    setState(() => _posting = true);
    try {
      final services = _selectedServices.toList(growable: false)..sort();
      for (final service in services) {
        await ProviderPostState.createProviderPost(
          category: _selectedCategory,
          service: service,
          area: _areaController.text.trim(),
          details: _detailsController.text.trim(),
          ratePerHour: price,
          availableNow: _availableNow,
        );
      }
      if (!mounted) return;
      _detailsController.clear();
      AppToast.success(
        context,
        services.length == 1
            ? 'Provider post published for ${services.first} (${price.toStringAsFixed(0)}/hour).'
            : 'Provider posts published for ${services.length} services.',
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  Future<void> _pickCategory() async {
    final List<String> categoryOptions = CatalogState.categories.value
        .map((item) => item.name)
        .toList(growable: false);
    if (categoryOptions.isEmpty) {
      AppToast.warning(context, 'No categories available yet.');
      return;
    }
    final picked = await _showOptionSheet<String>(
      title: 'Choose category',
      options: categoryOptions,
      selected: _selectedCategory,
      labelBuilder: (item) => item,
    );
    if (picked == null) return;
    final services = CatalogState.servicesForCategory(picked);
    setState(() {
      _selectedCategory = picked;
      _selectedServices
        ..clear()
        ..addAll(services.isNotEmpty ? <String>{services.first} : <String>{});
    });
  }

  Future<void> _pickService() async {
    final services = CatalogState.servicesForCategory(_selectedCategory);
    if (services.isEmpty) return;
    final picked = await _showMultiSelectServiceSheet(
      title: 'Choose service',
      options: services,
      selected: _selectedServices,
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      _selectedServices
        ..clear()
        ..addAll(picked);
    });
  }

  String get _selectedServiceLabel {
    if (_selectedServices.isEmpty) return '';
    final values = _selectedServices.toList(growable: false)..sort();
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values[0]}, ${values[1]}';
    return '${values.length} services selected';
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T value) labelBuilder,
  }) {
    T temp = selected;
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final active = option == temp;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setModalState(() => temp = option),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFEAF1FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: active ? 1.6 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 17,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      labelBuilder(option),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: active ? 1 : 0,
                                    child: const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Apply',
                      onPressed: () => Navigator.pop(context, temp),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Set<String>?> _showMultiSelectServiceSheet({
    required String title,
    required List<String> options,
    required Set<String> selected,
  }) {
    final temp = selected.toSet();
    return showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final active = temp.contains(option);
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setModalState(() {
                              if (active) {
                                temp.remove(option);
                              } else {
                                temp.add(option);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFEAF1FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: active ? 1.6 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 17,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: active ? 1 : 0,
                                    child: const Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Apply',
                      onPressed: temp.isEmpty
                          ? null
                          : () => Navigator.pop(context, temp),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PickerField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 17, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
