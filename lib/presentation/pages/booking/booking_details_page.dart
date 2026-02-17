import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_calendar_picker.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/provider.dart';
import '../../state/booking_catalog_state.dart';
import '../../state/catalog_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';
import '../providers/provider_detail_page.dart';
import 'booking_service_fields_page.dart';

class BookingDetailsPage extends StatefulWidget {
  final BookingDraft draft;

  const BookingDetailsPage({super.key, required this.draft});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  late int _hours;
  late HomeType _homeType;
  late int _workers;
  late DateTime _preferredDate;
  late String _preferredTime;
  late String _selectedService;
  String? _serviceError;

  @override
  void initState() {
    super.initState();
    _hours = widget.draft.hours;
    _homeType = widget.draft.homeType;
    _workers = widget.draft.workers;
    _preferredDate = widget.draft.preferredDate;
    _preferredTime = widget.draft.preferredTimeSlot;
    _selectedService = widget.draft.serviceName;
    _applyGeneralDetailDefaultsForService();
    _validateService();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft.copyWith(
      hours: _hours,
      homeType: _homeType,
      workers: _workers,
      preferredDate: _preferredDate,
      preferredTimeSlot: _preferredTime,
      serviceName: _selectedService,
      serviceFields: BookingCatalogState.initialFieldValuesForService(
        _selectedService,
      ),
    );
    final categoryServices = _servicesForProvider(
      provider: draft.provider,
      categoryName: draft.categoryName,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            110,
          ),
          child: ListView(
            children: [
              AppTopBar(title: draft.categoryName),
              const SizedBox(height: 12),
              _ProviderCard(draft: draft),
              const SizedBox(height: 16),
              Text(
                'Service',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              _PickerField(
                label: _selectedService,
                icon: Icons.build_circle_outlined,
                onTap: () => _pickService(categoryServices),
              ),
              if (_serviceError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _serviceError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 16),
              _SectionHeader(title: 'Booking Schedule'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      label: _dateLabel(_preferredDate),
                      icon: Icons.calendar_today_outlined,
                      compact: true,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerField(
                      label: _preferredTime,
                      icon: Icons.access_time,
                      compact: true,
                      onTap: _pickTimeSlot,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'General Details'),
              const SizedBox(height: 8),
              Text(
                _hoursQuestionLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              _PickerField(
                label: '$_hours hour${_hours > 1 ? 's' : ''}',
                onTap: _pickHours,
              ),
              const SizedBox(height: 6),
              Text(
                _hoursHelpLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                _homeTypeQuestionLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              _PickerField(
                label: _homeTypeLabel(_homeType),
                onTap: _pickHomeType,
              ),
              if (_allowWorkersInput) ...[
                const SizedBox(height: 16),
                Text(
                  'How many workers do you need?*',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                _PickerField(
                  label: '$_workers worker${_workers > 1 ? 's' : ''}',
                  onTap: _pickWorkers,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total fee',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '\$${draft.total.toStringAsFixed(0)}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                iconTrailing: true,
                onPressed: _serviceError == null
                    ? () => Navigator.push(
                        context,
                        slideFadeRoute(BookingServiceFieldsPage(draft: draft)),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateService() {
    final providerCategory = CatalogState.categoryForProviderRole(
      widget.draft.provider.role,
    );
    final supportedServices = _servicesForProvider(
      provider: widget.draft.provider,
      categoryName: providerCategory,
    );
    final supported =
        supportedServices.isEmpty ||
        supportedServices.contains(_selectedService);
    _serviceError = supported
        ? null
        : '${widget.draft.provider.name} does not offer this service. Please choose another.';
  }

  List<String> _servicesForProvider({
    required ProviderItem provider,
    required String categoryName,
  }) {
    final direct = provider.services
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (direct.isNotEmpty) return direct;
    return CatalogState.servicesForCategory(categoryName);
  }

  bool get _isCleaningService {
    const cleaningServices = {
      'House Cleaning',
      'Office Cleaning',
      'Move-in Cleaning',
      'Move-in / Move-out Cleaning',
    };
    return cleaningServices.contains(_selectedService);
  }

  bool get _allowWorkersInput => widget.draft.provider.isCompany;

  int get _maxWorkerSelectable {
    final maxWorkers = widget.draft.provider.safeMaxWorkers;
    return maxWorkers < 1 ? 1 : maxWorkers;
  }

  String get _hoursQuestionLabel {
    return _isCleaningService
        ? 'How many hours do you need worker to stay?*'
        : 'Estimated service duration*';
  }

  String get _hoursHelpLabel {
    return _isCleaningService
        ? 'Unsure about the hours to choose? Click here.'
        : 'For most repair jobs, 1-2 hours is usually enough.';
  }

  String get _homeTypeQuestionLabel {
    return _isCleaningService
        ? 'What is the type of your home?*'
        : 'What is the property type?*';
  }

  void _applyGeneralDetailDefaultsForService() {
    if (_allowWorkersInput) {
      if (_workers < 1) _workers = 1;
      if (_workers > _maxWorkerSelectable) _workers = _maxWorkerSelectable;
    } else {
      _workers = 1;
    }
    if (_isCleaningService) return;
    if (_hours > 4) _hours = 2;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAppCalendarDatePicker(
      context,
      initialDate: _preferredDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Choose booking date',
    );
    if (picked == null) return;
    setState(() => _preferredDate = picked);
  }

  Future<void> _pickTimeSlot() async {
    final picked = await _showOptionSheet<String>(
      title: 'Choose time slot',
      options: BookingCatalogState.scheduleTimeOptions,
      selected: _preferredTime,
      labelBuilder: (item) => item,
      iconBuilder: (item) =>
          const Icon(Icons.access_time, size: 16, color: AppColors.primary),
    );
    if (picked == null) return;
    setState(() => _preferredTime = picked);
  }

  Future<void> _pickService(List<String> categoryServices) async {
    final picked = await _showOptionSheet<String>(
      title: 'Choose service',
      options: categoryServices,
      selected: _selectedService,
      labelBuilder: (item) => item,
      iconBuilder: (item) => const Icon(
        Icons.build_circle_outlined,
        size: 17,
        color: AppColors.primary,
      ),
    );
    if (picked == null) return;
    setState(() {
      _selectedService = picked;
      _applyGeneralDetailDefaultsForService();
      _validateService();
    });
  }

  Future<void> _pickHours() async {
    final picked = await _showOptionSheet<int>(
      title: 'How many hours?',
      options: _isCleaningService
          ? BookingCatalogState.bookingHourOptions
          : const [1, 2, 3, 4],
      selected: _hours,
      labelBuilder: (item) => '$item hour${item > 1 ? 's' : ''}',
      iconBuilder: (item) => const Icon(
        Icons.timelapse_rounded,
        size: 17,
        color: AppColors.primary,
      ),
    );
    if (picked == null) return;
    setState(() => _hours = picked);
  }

  Future<void> _pickHomeType() async {
    final picked = await _showOptionSheet<HomeType>(
      title: 'Home type',
      options: BookingCatalogState.homeTypeOptions,
      selected: _homeType,
      labelBuilder: _homeTypeLabel,
      iconBuilder: (item) => Icon(
        switch (item) {
          HomeType.apartment => Icons.apartment_rounded,
          HomeType.flat => Icons.location_city_outlined,
          HomeType.villa => Icons.villa_outlined,
          HomeType.office => Icons.business_outlined,
        },
        size: 17,
        color: AppColors.primary,
      ),
    );
    if (picked == null) return;
    setState(() => _homeType = picked);
  }

  Future<void> _pickWorkers() async {
    if (!_allowWorkersInput) return;
    final options = List<int>.generate(
      _maxWorkerSelectable,
      (index) => index + 1,
    );
    final selected = _workers.clamp(1, _maxWorkerSelectable);
    final picked = await _showOptionSheet<int>(
      title: 'How many workers?',
      options: options,
      selected: selected,
      labelBuilder: (item) => '$item worker${item > 1 ? 's' : ''}',
      iconBuilder: (item) =>
          const Icon(Icons.groups_outlined, size: 17, color: AppColors.primary),
    );
    if (picked == null) return;
    setState(() => _workers = picked);
  }

  Future<T?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T value) labelBuilder,
    required Widget Function(T value) iconBuilder,
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
                                  iconBuilder(option),
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
                      icon: Icons.check_rounded,
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

  String _dateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _homeTypeLabel(HomeType type) {
    switch (type) {
      case HomeType.apartment:
        return 'Apartment';
      case HomeType.flat:
        return 'Flat';
      case HomeType.villa:
        return 'Villa';
      case HomeType.office:
        return 'Office';
    }
  }
}

class _ProviderCard extends StatelessWidget {
  final BookingDraft draft;

  const _ProviderCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(draft.provider.imagePath),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.provider.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.primary),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      draft.provider.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              slideFadeRoute(ProviderDetailPage(provider: draft.provider)),
            ),
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool compact;

  const _PickerField({
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
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
