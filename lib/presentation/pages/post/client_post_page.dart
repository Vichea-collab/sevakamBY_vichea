import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_calendar_picker.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/auth_state.dart';
import '../../state/catalog_state.dart';
import '../../state/finder_post_state.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ClientPostPage extends StatefulWidget {
  static const String routeName = '/post';

  const ClientPostPage({super.key});

  @override
  State<ClientPostPage> createState() => _ClientPostPageState();
}

class _ClientPostPageState extends State<ClientPostPage> {
  static const String _fallbackLocation = 'Phnom Penh, Cambodia';

  late String _selectedCategory;
  final Set<String> _selectedServices = <String>{};
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));
  String? _editingPostId;
  bool _submitting = false;

  InputDecoration _fieldDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      alignLabelWithHint: true,
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
    _locationController.text = _preferredFinderLocation();
    CatalogState.categories.addListener(_syncSelectionFromCatalog);
    CatalogState.services.addListener(_syncSelectionFromCatalog);
    ProfileSettingsState.finderProfile.addListener(_syncLocationFromProfile);
    _syncSelectionFromCatalog();
    unawaited(FinderPostState.refreshAllForLookup(maxPages: 5));
  }

  @override
  void dispose() {
    CatalogState.categories.removeListener(_syncSelectionFromCatalog);
    CatalogState.services.removeListener(_syncSelectionFromCatalog);
    ProfileSettingsState.finderProfile.removeListener(_syncLocationFromProfile);
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _syncLocationFromProfile() {
    final current = _locationController.text.trim();
    if (current.isNotEmpty && current != _fallbackLocation) return;
    final next = _preferredFinderLocation();
    if (next == current) return;
    _locationController.text = next;
    _locationController.selection = TextSelection.collapsed(
      offset: next.length,
    );
  }

  String _preferredFinderLocation() {
    final city = ProfileSettingsState.finderProfile.value.city.trim();
    if (city.isNotEmpty) return city;
    return _fallbackLocation;
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
    final nextSelection = _selectedServices
        .where((item) => services.contains(item))
        .toSet();
    if (nextSelection.isEmpty && services.isNotEmpty) {
      nextSelection.add(services.first);
    }
    if (!mounted) {
      _selectedCategory = nextCategory;
      _selectedServices
        ..clear()
        ..addAll(nextSelection);
      return;
    }
    final sameSelection =
        _selectedServices.length == nextSelection.length &&
        _selectedServices.containsAll(nextSelection);
    if (_selectedCategory == nextCategory && sameSelection) {
      return;
    }
    _safeSetState(() {
      _selectedCategory = nextCategory;
      _selectedServices
        ..clear()
        ..addAll(nextSelection);
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              AppTopBar(
                title: 'Post',
                showBack: true,
                onBack: () => Navigator.pushReplacementNamed(context, '/home'),
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
                                'What service do you need?',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Share details so providers can contact you with the right offer.',
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
                              _FieldLabel(label: 'Location*'),
                              TextField(
                                controller: _locationController,
                                minLines: 1,
                                maxLines: 2,
                                decoration: _fieldDecoration(
                                  hintText: 'Enter your area',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _FieldLabel(label: 'Preferred date*'),
                              _PreferredDateField(
                                value: _preferredDate,
                                onTap: _pickPreferredDate,
                              ),
                              const SizedBox(height: 8),
                              _FieldLabel(label: 'Describe your problem*'),
                              TextField(
                                controller: _detailsController,
                                minLines: 4,
                                maxLines: 6,
                                decoration: _fieldDecoration(
                                  hintText:
                                      'Example: Pipe leaking under kitchen sink.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_editingPostId != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _submitting ? null : _cancelEdit,
                                    child: const Text('Cancel edit'),
                                  ),
                                ),
                              PrimaryButton(
                                label: _submitting
                                    ? (_editingPostId == null
                                          ? 'Posting...'
                                          : 'Updating...')
                                    : (_editingPostId == null
                                          ? 'Post'
                                          : 'Update post'),
                                onPressed: _submitting ? null : _submitPost,
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
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.post),
    );
  }

  Future<void> _submitPost() async {
    final details = _detailsController.text.trim();
    final typedLocation = _locationController.text.trim();
    final location = typedLocation.isEmpty
        ? _preferredFinderLocation()
        : typedLocation;
    if (_selectedCategory.isEmpty ||
        _selectedServices.isEmpty ||
        location.isEmpty ||
        details.isEmpty) {
      AppToast.error(context, 'Please complete all fields.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final services = _selectedServices.toList(growable: false)..sort();
      final editingPostId = _editingPostId;
      if (editingPostId == null) {
        await FinderPostState.createFinderRequest(
          category: _selectedCategory,
          services: services,
          location: location,
          message: details,
          preferredDate: _preferredDate,
        );
      } else {
        await FinderPostState.updateFinderRequest(
          postId: editingPostId,
          category: _selectedCategory,
          services: services,
          location: location,
          message: details,
          preferredDate: _preferredDate,
        );
      }
      if (!mounted) return;
      _editingPostId = null;
      _detailsController.clear();
      final successMessage = editingPostId == null
          ? (services.length == 1
                ? 'Your request for ${services.first} is now live in $location.'
                : 'Your request for ${services.length} services is now live in $location.')
          : 'Your post was updated successfully.';
      await _showPostSubmitResultSheet(
        success: true,
        title: editingPostId == null ? 'Post Published' : 'Post Updated',
        message: successMessage,
        actionLabel: 'Go to Home',
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
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
        setState(() => _submitting = false);
      }
    }
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
    final selectedServices = post.serviceList.toSet();
    setState(() {
      _editingPostId = post.id;
      _selectedCategory = post.category;
      _selectedServices
        ..clear()
        ..addAll(selectedServices);
      _locationController.text = post.location;
      _detailsController.text = post.message;
      _preferredDate =
          post.preferredDate ?? DateTime.now().add(const Duration(days: 1));
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
        content: Text('Delete "${post.serviceLabel}" request?'),
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
    if (_selectedServices.isEmpty) return 'Select service(s)';
    final values = _selectedServices.toList(growable: false)..sort();
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values[0]}, ${values[1]}';
    return '${values.length} services selected';
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final picked = await showAppCalendarDatePicker(
      context,
      initialDate: _preferredDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Choose preferred date',
    );
    if (picked == null) return;
    setState(() => _preferredDate = picked);
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

class _PreferredDateField extends StatelessWidget {
  final DateTime value;
  final VoidCallback onTap;

  const _PreferredDateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = MaterialLocalizations.of(context).formatMediumDate(value);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Provider will prioritize this date',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
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
