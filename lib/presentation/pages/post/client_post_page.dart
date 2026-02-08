import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
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
  final TextEditingController _postController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _postController.dispose();
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
                        'Write in bellow box',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _postController,
                        minLines: 5,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          hintText: 'Write here...',
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
    final text = _postController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please write your post.')));
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _postController.clear();
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your post has been published.')),
    );
  }
}
