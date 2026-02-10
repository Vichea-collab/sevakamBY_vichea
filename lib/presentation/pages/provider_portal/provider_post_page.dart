import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/mock/mock_data.dart';
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
  late String _selectedService;
  final _priceController = TextEditingController(text: '12');
  final _areaController = TextEditingController(text: 'Phnom Penh, Cambodia');
  final _detailsController = TextEditingController();
  bool _availableNow = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'Cleaner';
    _selectedService = MockData.servicesForCategory(_selectedCategory).first;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _areaController.dispose();
    _detailsController.dispose();
    super.dispose();
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
                        label: _selectedService,
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
                              decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
                        decoration: const InputDecoration(
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
        _selectedService.isEmpty ||
        price <= 0 ||
        _areaController.text.trim().isEmpty ||
        _detailsController.text.trim().isEmpty) {
      AppToast.error(context, 'Please complete all fields.');
      return;
    }
    setState(() => _posting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _detailsController.clear();
    setState(() => _posting = false);
    AppToast.success(
      context,
      'Provider post published for $_selectedService (${price.toStringAsFixed(0)}/hour).',
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
