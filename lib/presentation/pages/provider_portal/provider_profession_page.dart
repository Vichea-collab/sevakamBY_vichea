import 'package:flutter/material.dart';
import '../../../core/constants/app_spacing.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class ProviderProfessionPage extends StatefulWidget {
  static const String routeName = '/provider/profession';

  const ProviderProfessionPage({super.key});

  @override
  State<ProviderProfessionPage> createState() => _ProviderProfessionPageState();
}

class _ProviderProfessionPageState extends State<ProviderProfessionPage> {
  final _serviceName = TextEditingController(text: 'Cleaner');
  final _expertIn = TextEditingController(text: 'Home clean, lawn clean, washing');
  final _from = TextEditingController(text: '9:00 AM');
  final _to = TextEditingController(text: '10:00 PM');
  final _years = TextEditingController(text: '4');
  final _area = TextEditingController(text: 'PP, Cambodia');

  @override
  void dispose() {
    _serviceName.dispose();
    _expertIn.dispose();
    _from.dispose();
    _to.dispose();
    _years.dispose();
    _area.dispose();
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
                  const Expanded(
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _area,
                decoration: const InputDecoration(labelText: 'Service area'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Save',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
