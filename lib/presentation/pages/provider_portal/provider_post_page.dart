import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/constants/location_options.dart';
import 'package:servicefinder/core/constants/app_spacing.dart';
import 'package:servicefinder/core/theme/app_theme_tokens.dart';
import 'package:servicefinder/core/utils/app_toast.dart';
import 'package:servicefinder/domain/entities/provider_portal.dart';
import 'package:servicefinder/presentation/state/auth_state.dart';
import 'package:servicefinder/presentation/state/catalog_state.dart';
import 'package:servicefinder/presentation/state/provider_post_state.dart';
import 'package:servicefinder/presentation/widgets/app_top_bar.dart';
import 'package:servicefinder/presentation/widgets/primary_button.dart';
import 'package:servicefinder/presentation/pages/main_shell_page.dart';
import 'package:servicefinder/presentation/widgets/app_bottom_nav.dart';
import 'package:servicefinder/presentation/widgets/post_composer_ui.dart';

class ProviderPostPage extends StatefulWidget {
  static const String routeName = '/provider/post';

  const ProviderPostPage({super.key});

  @override
  State<ProviderPostPage> createState() => _ProviderPostPageState();
}

class _ProviderPostPageState extends State<ProviderPostPage> {
  late String _selectedCategory;
  final Set<String> _selectedServices = <String>{};
  final _cityController = TextEditingController(
    text: LocationOptions.defaultCity,
  );
  final _districtController = TextEditingController();
  final _areaController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _editingPostId;
  bool _availableNow = true;
  bool _posting = false;

  bool get _isStandaloneRoute =>
      ModalRoute.of(context)?.settings.name == ProviderPostPage.routeName;

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppThemeTokens.mutedSurface(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppThemeTokens.outline(context)),
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
    unawaited(ProviderPostState.refreshAllForLookup(maxPages: 5));
  }

  @override
  void dispose() {
    CatalogState.categories.removeListener(_syncSelectionFromCatalog);
    CatalogState.services.removeListener(_syncSelectionFromCatalog);
    _cityController.dispose();
    _districtController.dispose();
    _areaController.dispose();
    _detailsController.dispose();
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
    _safeSetState(() {
      _selectedCategory = nextCategory;
      _selectedServices
        ..clear()
        ..addAll(selected);
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
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppThemeTokens.surface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppThemeTokens.outline(context)),
                  boxShadow: AppThemeTokens.cardShadow(context),
                ),
                child: AppTopBar(
                  title: 'Offer Service',
                  showBack: true,
                  onBack: _handleBackNavigation,
                  actions: [
                    TextButton.icon(
                      onPressed: _openManageSheet,
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRect(
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      overscroll: false,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
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
                                color: AppThemeTokens.surface(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppThemeTokens.outline(context),
                                ),
                                boxShadow: AppThemeTokens.cardShadow(context),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const PostComposerHeaderCard(
                                icon: Icons.storefront_rounded,
                                accentColor: Color(0xFF117A5A),
                                eyebrow: 'Provider offer',
                                title: 'Publish a clear service offer',
                                subtitle:
                                    'Show your service, district, and readiness so finders can understand your offer at a glance.',
                                highlights: [
                                  'Multi-service support',
                                  'Service district',
                                  'Availability status',
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_editingPostId != null) ...[
                                PostComposerEditingBanner(
                                  message: 'You are editing an active offer.',
                                  onCancel: _cancelEdit,
                                  enabled: !_posting,
                                ),
                                const SizedBox(height: 12),
                              ],
                              const PostComposerSectionHeader(
                                title: 'Service setup',
                                subtitle:
                                    'Choose the category and the services you can take on.',
                              ),
                              PostComposerSectionCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const PostComposerFieldLabel(
                                      label: 'Category*',
                                    ),
                                    PostComposerPickerField(
                                      label: _selectedCategory,
                                      icon: Icons.category_rounded,
                                      onTap: _pickCategory,
                                    ),
                                    const SizedBox(height: 10),
                                    const PostComposerFieldLabel(
                                      label: 'Service*',
                                    ),
                                    PostComposerPickerField(
                                      label: _selectedServiceLabel,
                                      icon: Icons.design_services_rounded,
                                      onTap: _pickService,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const PostComposerSectionHeader(
                                title: 'Coverage and timing',
                                subtitle:
                                    'Set where you work and whether you can take jobs right away.',
                              ),
                              PostComposerSectionCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const PostComposerFieldLabel(
                                      label: 'Service area*',
                                    ),
                                    PostComposerPickerField(
                                      label: _selectedDistrictLabel,
                                      icon: Icons.location_on_outlined,
                                      onTap: _pickDistrict,
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppThemeTokens.surface(context),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppThemeTokens.outline(context),
                                        ),
                                      ),
                                      child: SwitchListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                        value: _availableNow,
                                        activeThumbColor: AppColors.primary,
                                        title: const Text('Available now'),
                                        subtitle: Text(
                                          _availableNow
                                              ? 'Clients can see you are ready for nearby work.'
                                              : 'Clients will still see the offer, but not as immediate availability.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                        ),
                                        onChanged: (value) => setState(
                                          () => _availableNow = value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const PostComposerSectionHeader(
                                title: 'Offer details',
                                subtitle:
                                    'Summarize your tools, strengths, or response speed.',
                              ),
                              PostComposerSectionCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const PostComposerFieldLabel(
                                      label: 'Post details*',
                                    ),
                                    TextField(
                                      controller: _detailsController,
                                      minLines: 4,
                                      maxLines: 6,
                                      decoration: _fieldDecoration(
                                        hintText:
                                            'Example: Professional team, tools included, same-day support.',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              PrimaryButton(
                                label: _posting
                                    ? (_editingPostId == null
                                          ? 'Posting...'
                                          : 'Updating...')
                                    : (_editingPostId == null
                                          ? 'Post'
                                          : 'Update post'),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _syncAreaFromDistrict();
    if (_selectedCategory.isEmpty ||
        _selectedServices.isEmpty ||
        _areaController.text.trim().isEmpty ||
        _detailsController.text.trim().isEmpty) {
      AppToast.error(context, 'Please complete all fields.');
      return;
    }
    setState(() => _posting = true);
    try {
      final services = _selectedServices.toList(growable: false)..sort();
      final editingPostId = _editingPostId;
      if (editingPostId == null) {
        await ProviderPostState.createProviderPost(
          category: _selectedCategory,
          services: services,
          area: _areaController.text.trim(),
          details: _detailsController.text.trim(),
          availableNow: _availableNow,
        );
      } else {
        await ProviderPostState.updateProviderPost(
          postId: editingPostId,
          category: _selectedCategory,
          services: services,
          area: _areaController.text.trim(),
          details: _detailsController.text.trim(),
          availableNow: _availableNow,
        );
      }
      if (!mounted) return;
      setState(_resetComposer);
      final successMessage = editingPostId == null
          ? (services.length == 1
                ? 'Your offer for ${services.first} is now live.'
                : 'Your offer for ${services.length} services is now live.')
          : 'Your provider post was updated successfully.';
      await _showPostSubmitResultSheet(
        success: true,
        title: editingPostId == null ? 'Post Published' : 'Post Updated',
        message: successMessage,
        actionLabel: _isStandaloneRoute ? 'Back' : 'Go to Home',
      );
      if (!mounted) return;
      if (_isStandaloneRoute) {
        Navigator.pop(context, true);
      } else {
        MainShellPage.activeTab.value = AppBottomTab.home;
      }
    } catch (error) {
      if (!mounted) return;
      await _showPostSubmitResultSheet(
        success: false,
        title: 'Post Failed',
        message: error.toString(),
        actionLabel: 'Try Again',
      );
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  void _handleBackNavigation() {
    if (_isStandaloneRoute && Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }
    MainShellPage.activeTab.value = AppBottomTab.home;
  }

  Future<void> _showPostSubmitResultSheet({
    required bool success,
    required String title,
    required String message,
    required String actionLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostSubmitResultSheet(
        success: success,
        title: title,
        message: message,
        actionLabel: actionLabel,
      ),
    );
  }

  Future<void> _openManageSheet() async {
    await ProviderPostState.refreshAllForLookup(maxPages: 5);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppThemeTokens.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ValueListenableBuilder<List<ProviderPostItem>>(
          valueListenable: ProviderPostState.allPosts,
          builder: (context, allPosts, _) {
            final uid = AuthState.currentUser.value?.uid.trim() ?? '';
            final ownPosts = allPosts
                .where(
                  (item) => uid.isNotEmpty && item.providerUid.trim() == uid,
                )
                .toList(growable: false);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PostManageSheetHeader(
                      title: 'Manage my offers',
                      subtitle:
                          'Review your active offers and update them when your services change.',
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
                              final chips = <String>[
                                post.category,
                                post.area,
                                post.availableNow
                                    ? 'Available now'
                                    : 'Scheduled availability',
                              ];
                              return PostManageCard(
                                icon: Icons.storefront_rounded,
                                accentColor: const Color(0xFF117A5A),
                                title: post.serviceLabel,
                                subtitle: 'Offer visible in ${post.area}',
                                body: post.details,
                                chips: chips,
                                onEdit: () {
                                  Navigator.pop(sheetContext);
                                  _beginEdit(post);
                                },
                                onDelete: () async {
                                  final deleted = await _deletePost(post);
                                  if (!deleted) return;
                                },
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

  void _beginEdit(ProviderPostItem post) {
    setState(() {
      _editingPostId = post.id;
      _selectedCategory = post.category;
      _selectedServices
        ..clear()
        ..addAll(post.serviceList.toSet());
      _cityController.text = LocationOptions.defaultCity;
      _districtController.text = LocationOptions.districtFromArea(post.area);
      _areaController.text = post.area;
      _detailsController.text = post.details;
      _availableNow = post.availableNow;
    });
  }

  void _cancelEdit() {
    setState(_resetComposer);
  }

  Future<bool> _deletePost(ProviderPostItem post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post'),
        content: Text('Delete "${post.serviceLabel}" offer?'),
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
      await ProviderPostState.deleteProviderPost(postId: post.id);
      if (!mounted) return false;
      if (_editingPostId == post.id) {
        setState(_resetComposer);
      }
      AppToast.success(context, 'Post deleted.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      AppToast.error(context, error.toString());
      return false;
    }
  }

  void _resetComposer() {
    _editingPostId = null;
    _selectedCategory = 'Cleaner';
    _selectedServices
      ..clear()
      ..add('House Cleaning');
    _cityController.text = LocationOptions.defaultCity;
    _districtController.clear();
    _areaController.clear();
    _detailsController.clear();
    _availableNow = true;
    _syncSelectionFromCatalog();
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

  String get _selectedDistrictLabel {
    final district = _districtController.text.trim();
    return district.isEmpty ? 'Select district' : district;
  }

  void _syncAreaFromDistrict() {
    final district = _districtController.text.trim();
    _areaController.text = district.isEmpty
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
      title: 'Select service district',
      options: options,
      selected: _districtController.text.trim(),
      labelBuilder: (item) => item,
    );
    if (picked == null) return;
    setState(() {
      _districtController.text = picked;
      _syncAreaFromDistrict();
    });
  }

  String get _selectedServiceLabel {
    if (_selectedServices.isEmpty) return 'Select service(s)';
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
      backgroundColor: AppThemeTokens.surface(context),
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
                        color: AppThemeTokens.textPrimary(context),
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
                                    : AppThemeTokens.surface(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppThemeTokens.outline(context),
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
                                            color: AppThemeTokens.textPrimary(
                                              context,
                                            ),
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
      backgroundColor: AppThemeTokens.surface(context),
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
                        color: AppThemeTokens.textPrimary(context),
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
                                    : AppThemeTokens.surface(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppThemeTokens.outline(context),
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
                                            color: AppThemeTokens.textPrimary(
                                              context,
                                            ),
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

class _PostSubmitResultSheet extends StatelessWidget {
  final bool success;
  final String title;
  final String message;
  final String actionLabel;

  const _PostSubmitResultSheet({
    required this.success,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    final accent = success ? AppColors.success : AppColors.danger;
    final background = success
        ? const Color(0xFFF0FFF4)
        : const Color(0xFFFFF1F2);
    final gradient = success
        ? const [Color(0xFF059669), Color(0xFF10B981)]
        : const [Color(0xFFDC2626), Color(0xFFEF4444)];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppThemeTokens.cardShadow(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 34, color: accent),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemeTokens.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemeTokens.textSecondary(context),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(actionLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
