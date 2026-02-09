import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/order.dart';
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
      serviceFields: MockData.initialFieldValuesForService(_selectedService),
    );
    final categoryServices = MockData.servicesForCategory(draft.categoryName);

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
                label: 'Next',
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
    final supported = MockData.providerSupportsService(
      widget.draft.provider,
      _selectedService,
    );
    _serviceError = supported
        ? null
        : '${widget.draft.provider.name} does not offer this service. Please choose another.';
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

  bool get _allowWorkersInput => _isCleaningService;

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
    if (_isCleaningService) {
      if (_workers < 1) _workers = 1;
      return;
    }
    if (_hours > 4) _hours = 2;
    _workers = 1;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final options = List<DateTime>.generate(
      30,
      (index) => DateTime(now.year, now.month, now.day + index),
    );
    DateTime temp = _preferredDate;
    final picked = await showModalBottomSheet<DateTime>(
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
                      'Choose booking date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 124,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final date = options[index];
                          final selected = _sameDate(temp, date);
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setModalState(() => temp = date),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 88,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFEAF1FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  width: selected ? 1.6 : 1,
                                ),
                                boxShadow: selected
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x181D4ED8),
                                          blurRadius: 14,
                                          offset: Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _weekdayShort(date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    '${date.day}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 28,
                                        ),
                                  ),
                                  Text(
                                    _monthShort(date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Apply Date',
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
    if (picked == null) return;
    setState(() => _preferredDate = picked);
  }

  Future<void> _pickTimeSlot() async {
    final picked = await _showOptionSheet<String>(
      title: 'Choose time slot',
      options: MockData.scheduleTimeOptions,
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
          ? MockData.bookingHourOptions
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
      options: MockData.homeTypeOptions,
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
    final picked = await _showOptionSheet<int>(
      title: 'How many workers?',
      options: MockData.workerCountOptions,
      selected: _workers,
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

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayShort(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }

  String _monthShort(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[date.month - 1];
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
