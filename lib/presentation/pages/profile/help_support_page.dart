import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/primary_button.dart';

class HelpSupportPage extends StatefulWidget {
  static const String routeName = '/profile/help';

  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            10,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTopBar(
                title: 'Help & support',
                actions: [
                  TextButton(
                    onPressed: () {
                      AppToast.info(
                        context,
                        'Live chat integration is coming next.',
                      );
                    },
                    child: const Text('Live chat'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    size: 62,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Hello, how can we assist you?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Title',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'Enter the title of your issue',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Write in below box',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _messageController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Message is required';
                        }
                        return null;
                      },
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write here..',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _sending ? 'Sending...' : 'Send',
                onPressed: _sending ? null : _sendTicket,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppToast.info(
                      context,
                      'Live chat integration is coming next.',
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Live chat'),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder(
                valueListenable: ProfileSettingsState.isProvider
                    ? ProfileSettingsState.providerHelpTickets
                    : ProfileSettingsState.finderHelpTickets,
                builder: (context, tickets, _) {
                  if (tickets.isEmpty) return const SizedBox.shrink();
                  final recent = tickets.first;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last submitted',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recent.title,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recent.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendTicket() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _sending = true);
    await ProfileSettingsState.addCurrentHelpTicket(
      HelpSupportTicket(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    _titleController.clear();
    _messageController.clear();
    AppToast.success(context, 'Your request has been saved.');
  }
}
