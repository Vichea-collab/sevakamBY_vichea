import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/mock/mock_data.dart';
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
  late String _selectedCategory;
  late String _selectedService;
  final TextEditingController _locationController = TextEditingController(
    text: 'Phnom Penh, Cambodia',
  );
  final TextEditingController _detailsController = TextEditingController();
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = MockData.categories.first.name;
    _selectedService = MockData.servicesForCategory(_selectedCategory).first;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
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
              ),
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
                        'What service do you need?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        label: _selectedService,
                        onTap: _pickService,
                      ),
                      const SizedBox(height: 8),
                      _FieldLabel(label: 'Location*'),
                      TextField(
                        controller: _locationController,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Enter your area',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _FieldLabel(label: 'Preferred date'),
                      _PickerField(
                        label: _dateLabel(_preferredDate),
                        onTap: _pickPreferredDate,
                      ),
                      const SizedBox(height: 8),
                      _FieldLabel(label: 'Describe your problem*'),
                      TextField(
                        controller: _detailsController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Example: Pipe leaking under kitchen sink.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const Spacer(),
                      PrimaryButton(
                        label: _submitting ? 'Posting...' : 'Post',
                        onPressed: _submitting ? null : _submitPost,
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

  Future<void> _submitPost() async {
    final details = _detailsController.text.trim();
    final location = _locationController.text.trim();
    if (_selectedCategory.isEmpty ||
        _selectedService.isEmpty ||
        location.isEmpty ||
        details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _detailsController.clear();
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request posted for $_selectedService in $location.'),
      ),
    );
  }

  Future<void> _pickCategory() async {
    final picked = await _showOptionSheet<String>(
      title: 'Choose category',
      options: MockData.categories.map((item) => item.name).toList(),
      selected: _selectedCategory,
      labelBuilder: (item) => item,
    );
    if (picked == null) return;
    final services = MockData.servicesForCategory(picked);
    setState(() {
      _selectedCategory = picked;
      _selectedService = services.isNotEmpty ? services.first : '';
    });
  }

  Future<void> _pickService() async {
    final services = MockData.servicesForCategory(_selectedCategory);
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

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: 'Preferred date',
    );
    if (picked == null) return;
    setState(() => _preferredDate = picked);
  }

  String _dateLabel(DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
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
