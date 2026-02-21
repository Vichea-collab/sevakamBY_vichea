import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/order.dart';
import '../../state/order_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/booking_step_progress.dart';
import '../../widgets/primary_button.dart';
import 'address_map_picker_page.dart';
import 'booking_details_page.dart';

class BookingAddressPage extends StatefulWidget {
  final BookingDraft draft;

  const BookingAddressPage({super.key, required this.draft});

  @override
  State<BookingAddressPage> createState() => _BookingAddressPageState();
}

class _BookingAddressPageState extends State<BookingAddressPage> {
  late List<HomeAddress> _addresses;
  String? _selectedId;
  bool _loadingAddresses = false;

  @override
  void initState() {
    super.initState();
    _addresses = const <HomeAddress>[];
    _selectedId = widget.draft.address?.id;
    unawaited(_loadSavedAddresses());
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
                title: 'Home Address',
                actions: [
                  TextButton.icon(
                    onPressed: _addAddressSheet,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const BookingStepProgress(currentStep: BookingFlowStep.address),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _loadingAddresses && _addresses.isEmpty
                      ? const AppStatePanel.loading(
                          title: 'Loading saved addresses',
                        )
                      : _addresses.isEmpty
                      ? const AppStatePanel.empty(
                          title: 'No saved address yet',
                          message: 'Tap Add to save your first address.',
                        )
                      : ListView.separated(
                          key: ValueKey<String>(
                            'address_list_${_addresses.length}_${_selectedId ?? ''}',
                          ),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            final selected = _selectedId == address.id;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  setState(() => _selectedId = address.id),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFEFF4FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.home_outlined, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            address.label,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            address.street,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          Text(
                                            address.city,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              PrimaryButton(
                label: 'Select Address',
                icon: Icons.my_location_rounded,
                onPressed: _selectedId == null || _addresses.isEmpty
                    ? null
                    : _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goNext() {
    final selectedIndex = _addresses.indexWhere(
      (item) => item.id == _selectedId,
    );
    final selected = selectedIndex >= 0
        ? _addresses[selectedIndex]
        : _addresses.first;
    Navigator.push(
      context,
      slideFadeRoute(
        BookingDetailsPage(draft: widget.draft.copyWith(address: selected)),
      ),
    );
  }

  Future<void> _addAddressSheet() async {
    final labelController = TextEditingController();
    final mapLinkController = TextEditingController();
    final streetController = TextEditingController();
    final additionalController = TextEditingController();
    var pickedCity = 'Phnom Penh';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F4FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A0F172A),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Add Address',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pick location from Google Map',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked =
                                  await Navigator.push<PickedMapLocation>(
                                    context,
                                    slideFadeRoute(
                                      const AddressMapPickerPage(),
                                    ),
                                  );
                              if (picked == null || !context.mounted) return;
                              pickedCity = picked.city.trim().isEmpty
                                  ? 'Phnom Penh'
                                  : picked.city.trim();
                              labelController.text = picked.label;
                              mapLinkController.text = picked.mapLink;
                              streetController.text = picked.street.isEmpty
                                  ? picked.streetHint
                                  : picked.street;
                              additionalController.text =
                                  picked.additionalDetails;
                            },
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      textInputAction: TextInputAction.next,
                      decoration: _sheetInputDecoration('Label'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mapLinkController,
                      textInputAction: TextInputAction.next,
                      readOnly: true,
                      decoration: _sheetInputDecoration(
                        'Address link from Google Map',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: streetController,
                      textInputAction: TextInputAction.next,
                      decoration: _sheetInputDecoration('Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: additionalController,
                      textInputAction: TextInputAction.done,
                      decoration: _sheetInputDecoration(
                        'Additional details (optional)',
                      ),
                      onSubmitted: (_) {
                        unawaited(
                          _saveAddressFromSheet(
                            labelController: labelController,
                            mapLinkController: mapLinkController,
                            streetController: streetController,
                            additionalController: additionalController,
                            pickedCity: pickedCity,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Save Changes',
                      icon: Icons.save_outlined,
                      onPressed: () async {
                        await _saveAddressFromSheet(
                          labelController: labelController,
                          mapLinkController: mapLinkController,
                          streetController: streetController,
                          additionalController: additionalController,
                          pickedCity: pickedCity,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _sheetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: const Color(0xFF4C4B57),
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.divider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _saveAddressFromSheet({
    required TextEditingController labelController,
    required TextEditingController mapLinkController,
    required TextEditingController streetController,
    required TextEditingController additionalController,
    required String pickedCity,
  }) async {
    if (labelController.text.trim().isEmpty ||
        streetController.text.trim().isEmpty) {
      AppToast.error(context, 'Label and address are required.');
      return;
    }
    final additional = additionalController.text.trim();
    final resolvedStreet = additional.isEmpty
        ? streetController.text.trim()
        : '${streetController.text.trim()}, $additional';
    final draftAddress = HomeAddress(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: labelController.text.trim(),
      mapLink: mapLinkController.text.trim(),
      street: resolvedStreet,
      city: pickedCity.trim().isEmpty ? 'Phnom Penh' : pickedCity.trim(),
      isDefault: _addresses.isEmpty,
    );
    try {
      final saved = await OrderState.createSavedAddress(address: draftAddress);
      if (!mounted) return;
      setState(() {
        _addresses = [
          saved,
          ..._addresses.where((item) => item.id != saved.id),
        ];
        _selectedId = saved.id;
      });
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error.toString());
    }
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final loaded = await OrderState.fetchSavedAddresses();
      if (!mounted) return;

      final draftSelectedId = widget.draft.address?.id;
      final selectedId =
          (draftSelectedId != null &&
              loaded.any((item) => item.id == draftSelectedId))
          ? draftSelectedId
          : _firstPreferredAddressId(loaded);
      setState(() {
        _addresses = loaded;
        _selectedId = selectedId;
      });
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingAddresses = false);
      }
    }
  }

  String? _firstPreferredAddressId(List<HomeAddress> items) {
    if (items.isEmpty) return null;
    final defaultIndex = items.indexWhere((item) => item.isDefault);
    if (defaultIndex >= 0) return items[defaultIndex].id;
    return items.first.id;
  }
}
