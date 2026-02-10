import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../data/mock/mock_data.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';
import 'booking_payment_page.dart';

class BookingServiceFieldsPage extends StatefulWidget {
  final BookingDraft draft;

  const BookingServiceFieldsPage({super.key, required this.draft});

  @override
  State<BookingServiceFieldsPage> createState() =>
      _BookingServiceFieldsPageState();
}

class _BookingServiceFieldsPageState extends State<BookingServiceFieldsPage> {
  late Map<String, dynamic> _serviceFields;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _serviceFields = Map<String, dynamic>.from(widget.draft.serviceFields);
    _ensureFieldDefaults();
  }

  @override
  Widget build(BuildContext context) {
    final fieldDefs = MockData.bookingFieldsForService(
      widget.draft.serviceName,
    );
    final draft = widget.draft.copyWith(serviceFields: _serviceFields);
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
              AppTopBar(title: '${widget.draft.categoryName} Details'),
              const SizedBox(height: 8),
              Text(
                widget.draft.serviceName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              ...fieldDefs.map((field) => _buildDynamicField(field)),
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
                onPressed: () => _goNext(fieldDefs, draft),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicField(BookingFieldDef field) {
    final title = field.required ? '${field.label}*' : field.label;
    final value = _serviceFields[field.key];
    final errorText = _fieldErrors[field.key];
    switch (field.type) {
      case BookingFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              _PickerField(
                label: (() {
                  final stringValue = value as String?;
                  if (stringValue != null && stringValue.isNotEmpty) {
                    return stringValue;
                  }
                  return field.options.isNotEmpty ? field.options.first : '';
                })(),
                onTap: () => _pickDynamicOption(field),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  errorText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        );
      case BookingFieldType.toggle:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SwitchListTile(
            value: value == true,
            title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            activeThumbColor: AppColors.primary,
            onChanged: (newValue) => setState(() {
              _serviceFields[field.key] = newValue;
              if (_fieldErrors.containsKey(field.key)) {
                _fieldErrors = Map<String, String>.from(_fieldErrors)
                  ..remove(field.key);
              }
            }),
          ),
        );
      case BookingFieldType.number:
      case BookingFieldType.text:
      case BookingFieldType.multiline:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: (value ?? '').toString(),
                keyboardType: field.type == BookingFieldType.number
                    ? TextInputType.number
                    : TextInputType.text,
                minLines: field.type == BookingFieldType.multiline ? 3 : 1,
                maxLines: field.type == BookingFieldType.multiline ? 5 : 1,
                decoration: InputDecoration(
                  hintText: field.type == BookingFieldType.number
                      ? 'Enter number'
                      : 'Enter ${field.label.toLowerCase()}',
                  errorText: errorText,
                ),
                onChanged: (newValue) => setState(() {
                  _serviceFields[field.key] = newValue;
                  if (_fieldErrors.containsKey(field.key)) {
                    _fieldErrors = Map<String, String>.from(_fieldErrors)
                      ..remove(field.key);
                  }
                }),
              ),
            ],
          ),
        );
      case BookingFieldType.photo:
        final uploaded = value == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() {
                  _serviceFields[field.key] = !uploaded;
                  if (_fieldErrors.containsKey(field.key)) {
                    _fieldErrors = Map<String, String>.from(_fieldErrors)
                      ..remove(field.key);
                  }
                }),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: uploaded ? const Color(0xFFE8F5EE) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: uploaded ? AppColors.success : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        uploaded
                            ? Icons.check_circle
                            : Icons.camera_alt_outlined,
                        color: uploaded ? AppColors.success : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          uploaded ? '${field.label} added' : field.label,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        uploaded ? 'Change' : 'Upload',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  errorText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        );
    }
  }

  void _ensureFieldDefaults() {
    final defaults = MockData.initialFieldValuesForService(
      widget.draft.serviceName,
    );
    for (final entry in defaults.entries) {
      _serviceFields.putIfAbsent(entry.key, () => entry.value);
    }
  }

  Future<void> _pickDynamicOption(BookingFieldDef field) async {
    if (field.options.isEmpty) return;
    final selected = (_serviceFields[field.key] as String?)?.isNotEmpty == true
        ? _serviceFields[field.key] as String
        : field.options.first;
    final picked = await _showOptionSheet<String>(
      title: field.label,
      options: field.options,
      selected: selected,
      labelBuilder: (item) => item,
    );
    if (picked == null) return;
    setState(() {
      _serviceFields[field.key] = picked;
      if (_fieldErrors.containsKey(field.key)) {
        _fieldErrors = Map<String, String>.from(_fieldErrors)
          ..remove(field.key);
      }
    });
  }

  void _goNext(List<BookingFieldDef> fieldDefs, BookingDraft draft) {
    final errors = <String, String>{};
    for (final field in fieldDefs) {
      final error = _validateField(field);
      if (error != null) {
        errors[field.key] = error;
      }
    }
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      AppToast.error(context, 'Please complete all required fields.');
      return;
    }
    Navigator.push(context, slideFadeRoute(BookingPaymentPage(draft: draft)));
  }

  String? _validateField(BookingFieldDef field) {
    final value = _serviceFields[field.key];
    final text = (value ?? '').toString().trim();

    if (field.required) {
      switch (field.type) {
        case BookingFieldType.photo:
          if (value != true) return '${field.label} is required';
          break;
        case BookingFieldType.toggle:
          if (value != true) return '${field.label} is required';
          break;
        case BookingFieldType.text:
        case BookingFieldType.multiline:
        case BookingFieldType.dropdown:
        case BookingFieldType.number:
          if (text.isEmpty) return '${field.label} is required';
          break;
      }
    }

    if (field.type == BookingFieldType.number && text.isNotEmpty) {
      final parsed = int.tryParse(text);
      if (parsed == null || parsed <= 0) {
        return '${field.label} must be a positive number';
      }
    }
    return null;
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
            const Icon(Icons.tune_rounded, size: 17, color: AppColors.primary),
            const SizedBox(width: 10),
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
