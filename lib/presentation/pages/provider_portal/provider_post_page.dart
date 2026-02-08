import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
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
  final _serviceController = TextEditingController(text: 'Cleaner');
  final _priceController = TextEditingController(text: '4');
  final _areaController = TextEditingController(text: 'PP, Cambodia');
  bool _posting = false;

  @override
  void dispose() {
    _serviceController.dispose();
    _priceController.dispose();
    _areaController.dispose();
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
              const AppTopBar(
                title: 'Post',
                showBack: false,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _serviceController,
                decoration: const InputDecoration(labelText: 'Service name'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rate price'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    margin: const EdgeInsets.only(top: 24),
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
              const SizedBox(height: 14),
              TextField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Service Area'),
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
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.post),
    );
  }

  Future<void> _submit() async {
    if (_serviceController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _areaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }
    setState(() => _posting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _posting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Provider post published.')),
    );
  }
}
