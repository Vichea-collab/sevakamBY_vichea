import 'package:flutter/material.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../../core/constants/app_spacing.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProviderProfessionPage extends StatefulWidget {
  static const String routeName = '/provider/profession';

  const ProviderProfessionPage({super.key});

  @override
  State<ProviderProfessionPage> createState() => _ProviderProfessionPageState();
}

class _ProviderProfessionPageState extends State<ProviderProfessionPage> {
  final _serviceName = TextEditingController();
  final _expertIn = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _years = TextEditingController();
  final _area = TextEditingController();
  final _companyName = TextEditingController();
  final _maxWorkers = TextEditingController();
  String _providerType = 'individual';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bindProfession(ProfileSettingsState.providerProfession.value);
    _loadProfession();
  }

  @override
  void dispose() {
    _serviceName.dispose();
    _expertIn.dispose();
    _from.dispose();
    _to.dispose();
    _years.dispose();
    _area.dispose();
    _companyName.dispose();
    _maxWorkers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              const AppTopBar(title: 'Profession'),
              if (_loading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _serviceName,
                decoration: const InputDecoration(labelText: 'Service name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _expertIn,
                decoration: const InputDecoration(labelText: 'Expert in'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _from,
                      decoration: const InputDecoration(labelText: 'From'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _to,
                      decoration: const InputDecoration(labelText: 'To'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _years,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Experience in years',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _area,
                decoration: const InputDecoration(labelText: 'Service area'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _providerType,
                decoration: const InputDecoration(labelText: 'Provider type'),
                items: const [
                  DropdownMenuItem(
                    value: 'individual',
                    child: Text('Individual'),
                  ),
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _providerType = value;
                    if (_providerType == 'individual') {
                      _companyName.clear();
                      _maxWorkers.text = '1';
                    }
                  });
                },
              ),
              if (_providerType == 'company') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _companyName,
                  decoration: const InputDecoration(labelText: 'Company name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _maxWorkers,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum workers per booking',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _saving ? 'Saving...' : 'Save',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadProfession() async {
    setState(() => _loading = true);
    final success =
        await ProfileSettingsState.syncProviderProfessionFromBackend();
    if (!mounted) return;
    _bindProfession(ProfileSettingsState.providerProfession.value);
    setState(() => _loading = false);
    if (!success) {
      AppToast.warning(context, 'Using local profession data.');
    }
  }

  Future<void> _save() async {
    final providerType = _providerType == 'company' ? 'company' : 'individual';
    final maxWorkersText = providerType == 'company'
        ? _maxWorkers.text.trim()
        : '1';
    final companyNameText = providerType == 'company'
        ? _companyName.text.trim()
        : '';

    final payload = ProviderProfessionData(
      serviceName: _serviceName.text.trim(),
      expertIn: _expertIn.text.trim(),
      availableFrom: _from.text.trim(),
      availableTo: _to.text.trim(),
      experienceYears: _years.text.trim(),
      serviceArea: _area.text.trim(),
      providerType: providerType,
      companyName: companyNameText,
      maxWorkers: maxWorkersText,
    );

    if (payload.serviceName.isEmpty ||
        payload.expertIn.isEmpty ||
        payload.availableFrom.isEmpty ||
        payload.availableTo.isEmpty ||
        payload.experienceYears.isEmpty ||
        payload.serviceArea.isEmpty) {
      AppToast.warning(context, 'Please fill all profession fields.');
      return;
    }
    if (payload.providerType == 'company' && payload.companyName.isEmpty) {
      AppToast.warning(context, 'Company name is required.');
      return;
    }
    final parsedMaxWorkers = int.tryParse(payload.maxWorkers);
    if (parsedMaxWorkers == null || parsedMaxWorkers < 1) {
      AppToast.warning(context, 'Max workers must be at least 1.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ProfileSettingsState.saveProviderProfession(payload);
      if (!mounted) return;
      AppToast.success(context, 'Profession updated successfully.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update profession.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _bindProfession(ProviderProfessionData value) {
    _serviceName.text = value.serviceName;
    _expertIn.text = value.expertIn;
    _from.text = value.availableFrom;
    _to.text = value.availableTo;
    _years.text = value.experienceYears;
    _area.text = value.serviceArea;
    _providerType = value.providerType.trim().toLowerCase() == 'company'
        ? 'company'
        : 'individual';
    _companyName.text = _providerType == 'company' ? value.companyName : '';
    _maxWorkers.text = _providerType == 'company'
        ? (value.maxWorkers.trim().isEmpty ? '1' : value.maxWorkers)
        : '1';
  }
}
