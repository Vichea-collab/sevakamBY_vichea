import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/primary_button.dart';

class HelpSupportChatPage extends StatefulWidget {
  final HelpSupportTicket ticket;

  const HelpSupportChatPage({super.key, required this.ticket});

  @override
  State<HelpSupportChatPage> createState() => _HelpSupportChatPageState();
}

class _HelpSupportChatPageState extends State<HelpSupportChatPage> {
  final TextEditingController _composerController = TextEditingController();
  Timer? _pollTimer;
  int _currentPage = 1;
  bool _sending = false;
  bool _paging = false;

  @override
  void initState() {
    super.initState();
    if (widget.ticket.id.isNotEmpty) {
      _currentPage = 1;
      unawaited(
        ProfileSettingsState.refreshCurrentHelpTicketMessages(
          ticketId: widget.ticket.id,
          page: _currentPage,
        ),
      );
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageListenable = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTicketMessages
        : ProfileSettingsState.finderHelpTicketMessages;
    final paginationListenable = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTicketMessagesPagination
        : ProfileSettingsState.finderHelpTicketMessagesPagination;
    final loadingListenable = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTicketMessagesLoading
        : ProfileSettingsState.finderHelpTicketMessagesLoading;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                10,
                AppSpacing.lg,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppTopBar(title: 'Support chat'),
                  const SizedBox(height: 8),
                  Text(
                    widget.ticket.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusPill(status: widget.ticket.status),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ticket ID: ${widget.ticket.id.isEmpty ? 'Pending sync' : widget.ticket.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ValueListenableBuilder<List<HelpTicketMessage>>(
                  valueListenable: messageListenable,
                  builder: (context, messages, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: loadingListenable,
                      builder: (context, loading, _) {
                        return ValueListenableBuilder<PaginationMeta>(
                          valueListenable: paginationListenable,
                          builder: (context, pagination, _) {
                            if (widget.ticket.id.isEmpty) {
                              return const AppStatePanel.empty(
                                title: 'Ticket is syncing',
                                message: 'Please reopen this chat in a moment.',
                              );
                            }
                            if (loading && messages.isEmpty) {
                              return const Center(
                                child: AppStatePanel.loading(
                                  title: 'Loading support messages',
                                ),
                              );
                            }
                            if (messages.isEmpty) {
                              return const AppStatePanel.empty(
                                title: 'No messages yet',
                                message: 'Start chatting with support.',
                              );
                            }
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Column(
                                key: ValueKey<String>(
                                  'support_messages_${messages.length}_${pagination.page}',
                                ),
                                children: [
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: messages.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = messages[index];
                                        final fromAdmin =
                                            item.senderRole.toLowerCase() ==
                                            'admin';
                                        return Align(
                                          alignment: fromAdmin
                                              ? Alignment.centerLeft
                                              : Alignment.centerRight,
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: 320,
                                            ),
                                            padding: const EdgeInsets.fromLTRB(
                                              10,
                                              8,
                                              10,
                                              8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: fromAdmin
                                                  ? const Color(0xFFF3F6FC)
                                                  : AppColors.primary
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: fromAdmin
                                                    ? const Color(0xFFD8E2F3)
                                                    : AppColors.primary
                                                          .withValues(
                                                            alpha: 0.30,
                                                          ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.senderName,
                                                  style: TextStyle(
                                                    color: fromAdmin
                                                        ? AppColors
                                                              .textSecondary
                                                        : AppColors.primaryDark,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.text,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDate(item.createdAt),
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (pagination.totalPages > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
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
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                10,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  AppTextField(
                    hint: 'Type your message to support...',
                    controller: _composerController,
                    minLines: 1,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: _sending ? 'Sending...' : 'Send message',
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToPage(int page) async {
    if (_paging || widget.ticket.id.isEmpty) return;
    final targetPage = _normalizedPage(page);
    setState(() => _paging = true);
    try {
      _currentPage = targetPage;
      await ProfileSettingsState.refreshCurrentHelpTicketMessages(
        ticketId: widget.ticket.id,
        page: _currentPage,
      );
    } finally {
      if (mounted) {
        setState(() => _paging = false);
      }
    }
  }

  Future<void> _send() async {
    if (widget.ticket.id.isEmpty) {
      AppToast.error(context, 'Ticket not synced yet. Please re-open chat.');
      return;
    }
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ProfileSettingsState.sendCurrentHelpTicketMessage(
        ticketId: widget.ticket.id,
        text: text,
      );
      _composerController.clear();
      _currentPage = 1;
      await ProfileSettingsState.refreshCurrentHelpTicketMessages(
        ticketId: widget.ticket.id,
        page: _currentPage,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to send message.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || _sending || _paging || widget.ticket.id.isEmpty) return;
      final isLoading = ProfileSettingsState.isProvider
          ? ProfileSettingsState.providerHelpTicketMessagesLoading.value
          : ProfileSettingsState.finderHelpTicketMessagesLoading.value;
      if (isLoading) return;
      try {
        await ProfileSettingsState.refreshCurrentHelpTicketMessages(
          ticketId: widget.ticket.id,
          page: _currentPage,
        );
      } catch (_) {
        // Ignore poll failures and keep the current chat view stable.
      }
    });
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase().trim();
    final color = switch (normalized) {
      'resolved' => AppColors.success,
      'closed' => AppColors.textSecondary,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.isEmpty ? 'open' : normalized,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
