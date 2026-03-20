import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/constants/location_options.dart';
import 'package:servicefinder/core/constants/app_spacing.dart';
import 'package:servicefinder/core/utils/app_calendar_picker.dart';
import 'package:servicefinder/core/utils/app_toast.dart';
import 'package:servicefinder/domain/entities/provider_portal.dart';
import 'package:servicefinder/presentation/state/auth_state.dart';
import 'package:servicefinder/presentation/state/catalog_state.dart';
import 'package:servicefinder/presentation/state/finder_post_state.dart';
import 'package:servicefinder/presentation/widgets/app_top_bar.dart';
import 'package:servicefinder/presentation/widgets/primary_button.dart';
import 'package:servicefinder/presentation/pages/main_shell_page.dart';
import 'package:servicefinder/presentation/widgets/app_bottom_nav.dart';

class ClientPostPage extends StatefulWidget {
  static const String routeName = '/post';

  const ClientPostPage({super.key});

  @override
  State<ClientPostPage> createState() => _ClientPostPageState();
}

class _ClientPostPageState extends State<ClientPostPage> {
  late String _selectedCategory;
  late String _selectedService;
  final _messageController = TextEditingController();
  final _cityController = TextEditingController(
    text: LocationOptions.defaultCity,
  );
  final _districtController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _preferredDate;
  String? _editingPostId;
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
    _selectedService = 'House Cleaning';
    CatalogState.categories.addListener(_syncSelectionFromCatalog);
    CatalogState.services.addListener(_syncSelectionFromCatalog);
    _syncSelectionFromCatalog();
    unawaited(FinderPostState.refreshAllForLookup(maxPages: 5));
  }

  @override
  void dispose() {
    CatalogState.categories.removeListener(_syncSelectionFromCatalog);
    CatalogState.services.removeListener(_syncSelectionFromCatalog);
    _messageController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<String> get _districtsForSelectedCity {
    return LocationOptions.districtsForCity(_cityController.text.trim());
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
    final nextService = services.contains(_selectedService)
        ? _selectedService
        : (services.isNotEmpty ? services.first : '');
    if (!mounted) {
      _selectedCategory = nextCategory;
      _selectedService = nextService;
      return;
    }
    if (_selectedCategory == nextCategory && _selectedService == nextService) {
      return;
    }
    _safeSetState(() {
      _selectedCategory = nextCategory;
      _selectedService = nextService;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              AppTopBar(
                title: 'Post Service',
                showBack: true,
                onBack: () => MainShellPage.activeTab.value = AppBottomTab.home,
                actions: [
                  TextButton.icon(
                    onPressed: _openManageSheet,
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
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
                                'What do you need help with?',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Describe your needs so providers can reach out to you.',
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
                                label: _selectedService,
                                onTap: _pickService,
                              ),
                              const SizedBox(height: 8),
                              _FieldLabel(label: 'Preferred Date (Optional)'),
                              _PickerField(
                                label: _preferredDate == null
                                    ? 'Select date'
                                    : '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}',
                                onTap: _pickDate,
                              ),
                              const SizedBox(height: 8),
                              _FieldLabel(label: 'Your Location*'),
                              _PickerField(
                                label: _selectedDistrictLabel,
                                onTap: _pickDistrict,
                              ),
                              const SizedBox(height: 8),
                              _FieldLabel(label: 'Description*'),
                              TextField(
                                controller: _messageController,
                                minLines: 4,
                                maxLines: 6,
                                decoration: _fieldDecoration(
                                  hintText:
                                      'Example: I need 2 people to clean my house tomorrow morning. Total 3 bedrooms.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_editingPostId != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _posting ? null : _cancelEdit,
                                    child: const Text('Cancel edit'),
                                  ),
                                ),
                              PrimaryButton(
                                label: _posting
                                    ? (_editingPostId == null
                                          ? 'Posting...'
                                          : 'Updating...')
                                    : (_editingPostId == null
                                          ? 'Post Now'
                                          : 'Update Post'),
                                onPressed: _posting ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Future<void> _submit() async {
    _syncLocationFromDistrict();
    if (_selectedCategory.isEmpty ||
        _selectedService.isEmpty ||
        _messageController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      AppToast.error(context, 'Please complete all fields.');
      return;
    }
    setState(() => _posting = true);
    try {
      final preferredDate =
          _preferredDate ?? DateTime.now().add(const Duration(days: 1));
      if (_editingPostId == null) {
        await FinderPostState.createFinderRequest(
          category: _selectedCategory,
          services: [_selectedService],
          message: _messageController.text.trim(),
          location: _locationController.text.trim(),
          preferredDate: preferredDate,
        );
      } else {
        await FinderPostState.updateFinderRequest(
          postId: _editingPostId!,
          category: _selectedCategory,
          services: [_selectedService],
          message: _messageController.text.trim(),
          location: _locationController.text.trim(),
          preferredDate: preferredDate,
        );
      }
      if (!mounted) return;
      _editingPostId = null;
      _messageController.clear();
      _preferredDate = null;
      AppToast.success(
        context,
        'Your request is now live for providers to see.',
      );
      MainShellPage.activeTab.value = AppBottomTab.home;
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  Future<void> _openManageSheet() async {
    await FinderPostState.refreshAllForLookup(maxPages: 5);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ValueListenableBuilder<List<FinderPostItem>>(
          valueListenable: FinderPostState.allPosts,
          builder: (context, allPosts, _) {
            final uid = AuthState.currentUser.value?.uid.trim() ?? '';
            final ownPosts = allPosts
                .where((item) => uid.isNotEmpty && item.finderUid.trim() == uid)
                .toList(growable: false);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage my posts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ownPosts.isEmpty
                          ? const Center(
                              child: Text('No posts available to edit yet.'),
                            )
                          : ListView.separated(
                              itemCount: ownPosts.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final post = ownPosts[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  title: Text(post.serviceLabel),
                                  subtitle: Text(
                                    '${post.category} • ${post.location}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (action) async {
                                      if (action == 'edit') {
                                        Navigator.pop(sheetContext);
                                        _beginEdit(post);
                                        return;
                                      }
                                      if (action == 'delete') {
                                        final deleted = await _deletePost(post);
                                        if (!deleted) return;
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
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

  void _beginEdit(FinderPostItem post) {
    setState(() {
      _editingPostId = post.id;
      _selectedCategory = post.category;
      _selectedService = post.service;
      _messageController.text = post.message;
      _cityController.text = LocationOptions.defaultCity;
      _districtController.text = LocationOptions.districtFromArea(
        post.location,
      );
      _locationController.text = post.location;
      _preferredDate = post.preferredDate;
    });
  }

  void _cancelEdit() {
    setState(() => _editingPostId = null);
  }

  Future<bool> _deletePost(FinderPostItem post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post'),
        content: Text('Delete "${post.serviceLabel}" post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await FinderPostState.deleteFinderRequest(postId: post.id);
      if (!mounted) return false;
      if (_editingPostId == post.id) {
        setState(() => _editingPostId = null);
      }
      AppToast.success(context, 'Post deleted.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      AppToast.error(context, error.toString());
      return false;
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
    setState(() {
      _selectedCategory = picked;
      final services = CatalogState.servicesForCategory(picked);
      _selectedService = services.isNotEmpty ? services.first : '';
    });
  }

  Future<void> _pickService() async {
    final services = CatalogState.servicesForCategory(_selectedCategory);
    if (services.isEmpty) return;
    final picked = await _showOptionSheet<String>(
      title: 'Choose service',
      options: services,
      selected: _selectedService,
      labelBuilder: (item) => item,
    );
    if (picked == null) return;
    setState(() => _selectedService = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAppCalendarDatePicker(
      context,
      initialDate: _preferredDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Choose preferred date',
    );
    if (picked == null) return;
    setState(() => _preferredDate = picked);
  }

  String get _selectedDistrictLabel {
    final district = _districtController.text.trim();
    return district.isEmpty ? 'Select district' : district;
  }

  void _syncLocationFromDistrict() {
    final district = _districtController.text.trim();
    _locationController.text = district.isEmpty
        ? ''
        : LocationOptions.areaFromDistrict(
            district,
            city: _cityController.text.trim(),
          );
  }

  Future<void> _pickDistrict() async {
    if (_cityController.text.trim().isEmpty) {
      _cityController.text = LocationOptions.defaultCity;
    }

    final options = _districtsForSelectedCity;
    if (options.isEmpty) {
      AppToast.warning(context, 'No district options available for this city.');
      return;
    }

    final picked = await _showOptionSheet<String>(
      title: 'Select your district',
      options: options,
      selected: _districtController.text.trim(),
      labelBuilder: (item) => item,
    );
    if (picked == null) return;
    setState(() {
      _districtController.text = picked;
      _syncLocationFromDistrict();
    });
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
