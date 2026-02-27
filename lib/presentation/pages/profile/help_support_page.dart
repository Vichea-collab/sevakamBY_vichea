import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/profile_settings.dart';
import 'help_support_chat_page.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
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
  Timer? _pollTimer;
  int _activePage = 1;
  bool _sending = false;
  bool _paging = false;

  @override
  void initState() {
    super.initState();
    _activePage = 1;
    unawaited(
      ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage),
    );
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
              AppTopBar(title: 'Help & support', actions: const []),
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
                    AppTextField(
                      hint: 'Enter the title of your issue',
                      controller: _titleController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Write in below box',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      hint: 'Write here..',
                      controller: _messageController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Message is required';
                        }
                        return null;
                      },
                      minLines: 4,
                      maxLines: 4,
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD5DFF0)),
                ),
                child: const Text(
                  'Open any ticket below to chat directly with admin support.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<HelpSupportTicket>>(
                valueListenable: ProfileSettingsState.isProvider
                    ? ProfileSettingsState.providerHelpTickets
                    : ProfileSettingsState.finderHelpTickets,
                builder: (context, tickets, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: ProfileSettingsState.isProvider
                        ? ProfileSettingsState.providerHelpTicketsLoading
                        : ProfileSettingsState.finderHelpTicketsLoading,
                    builder: (context, loading, _) {
                      return ValueListenableBuilder<PaginationMeta>(
                        valueListenable: ProfileSettingsState.isProvider
                            ? ProfileSettingsState.providerHelpTicketsPagination
                            : ProfileSettingsState.finderHelpTicketsPagination,
                        builder: (context, pagination, _) {
                          final Widget ticketBody;
                          if (loading && tickets.isEmpty) {
                            ticketBody = const SizedBox(
                              height: 320,
                              child: Center(
                                child: AppStatePanel.loading(
                                  title: 'Loading support tickets',
                                ),
                              ),
                            );
                          } else if (tickets.isEmpty) {
                            ticketBody = const AppStatePanel.empty(
                              title: 'No support tickets yet',
                              message:
                                  'Your submitted support requests will appear here.',
                            );
                          } else {
                            ticketBody = Container(
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
                                    'Support tickets (${pagination.totalItems})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...tickets.map(_buildTicketCard),
                                  if (pagination.totalPages > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: PaginationBar(
                                        currentPage: _normalizedPage(
                                          pagination.page,
                                        ),
                                        totalPages: pagination.totalPages,
                                        loading: _paging,
                                        onPageSelected: _goToPage,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: ticketBody,
                          );
                        },
                      );
                    },
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
    final created = await ProfileSettingsState.addCurrentHelpTicket(
      HelpSupportTicket(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _activePage = 1;
    await ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage);
    if (!mounted) return;
    setState(() => _sending = false);
    _titleController.clear();
    _messageController.clear();
    AppToast.success(context, 'Your request has been saved.');
    await _openChat(created);
  }

  Future<void> _goToPage(int page) async {
    final targetPage = _normalizedPage(page);
    final currentPage = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTicketsPagination.value.page
        : ProfileSettingsState.finderHelpTicketsPagination.value.page;
    if (_paging || targetPage == currentPage) return;
    setState(() => _paging = true);
    try {
      _activePage = targetPage;
      await ProfileSettingsState.refreshCurrentHelpTickets(page: targetPage);
    } finally {
      if (mounted) {
        setState(() => _paging = false);
      }
    }
  }

  int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }

  Widget _buildTicketCard(HelpSupportTicket ticket) {
    final normalized = ticket.status.toLowerCase();
    final statusColor = switch (normalized) {
      'resolved' => AppColors.success,
      'closed' => AppColors.textSecondary,
      _ => AppColors.warning,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openChat(ticket),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD7E1F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      normalized.isEmpty ? 'open' : normalized,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ticket.lastMessageText.isEmpty
                    ? ticket.message
                    : ticket.lastMessageText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(ticket.lastMessageAt ?? ticket.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openChat(ticket),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Open chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat(HelpSupportTicket ticket) async {
    if (ticket.id.isEmpty) {
      AppToast.info(
        context,
        'Ticket is syncing. Pull to refresh then open chat.',
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HelpSupportChatPage(ticket: ticket),
      ),
    );
    if (!mounted) return;
    unawaited(
      ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage),
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted || _sending || _paging) return;
      final isLoading = ProfileSettingsState.isProvider
          ? ProfileSettingsState.providerHelpTicketsLoading.value
          : ProfileSettingsState.finderHelpTicketsLoading.value;
      if (isLoading) return;
      try {
        await ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage);
      } catch (_) {
        // Background refresh failure should not interrupt typing.
      }
    });
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}
