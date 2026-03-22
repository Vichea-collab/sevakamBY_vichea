import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/support_ticket_options.dart';
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
    final statusColor = _statusColor(widget.ticket.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFF1F5FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -30,
              child: _ChatBackgroundGlow(
                size: 210,
                color: const Color(0x332563EB),
              ),
            ),
            SafeArea(
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
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFFDCE4F2)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F0F172A),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF1FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Conversation',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.support_agent_rounded,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.ticket.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _MetaPill(
                                              text: _prettyStatus(
                                                widget.ticket.status,
                                              ),
                                              color: statusColor,
                                            ),
                                            _MetaPill(
                                              text: supportTicketCategoryLabel(
                                                widget.ticket.category,
                                              ),
                                              color: AppColors.primary,
                                            ),
                                            if (widget.ticket.priority.isNotEmpty)
                                              _MetaPill(
                                                text: _prettyPriority(
                                                  widget.ticket.priority,
                                                ),
                                                color: _priorityColor(
                                                  widget.ticket.priority,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFDCE6F7),
                                  ),
                                ),
                                child: Text(
                                  widget.ticket.message,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFDCE4F2)),
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
                                      message:
                                          'Please reopen this chat in a moment.',
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
                                  return Column(
                                    children: [
                                      Expanded(
                                        child: ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          itemCount: messages.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) {
                                            final item = messages[index];
                                            final fromAdmin =
                                                item.senderRole.toLowerCase() ==
                                                'admin';
                                            final isAutoReply =
                                                item.type.toLowerCase() ==
                                                'auto_reply';
                                            return _ChatBubble(
                                              message: item,
                                              fromAdmin: fromAdmin,
                                              isAutoReply: isAutoReply,
                                              timeLabel: _formatDate(
                                                item.createdAt,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (pagination.totalPages > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
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
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFDCE4F2)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reply to support',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
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

  String _prettyPriority(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return 'High priority';
      case 'low':
        return 'Low priority';
      default:
        return 'Normal priority';
    }
  }

  Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'low':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      case 'waiting_on_user':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _prettyStatus(String value) {
    switch (value.toLowerCase()) {
      case 'waiting_on_admin':
        return 'Waiting for admin';
      case 'waiting_on_user':
        return 'Waiting for your reply';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final HelpTicketMessage message;
  final bool fromAdmin;
  final bool isAutoReply;
  final String timeLabel;

  const _ChatBubble({
    required this.message,
    required this.fromAdmin,
    required this.isAutoReply,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = isAutoReply
        ? Alignment.centerLeft
        : (fromAdmin ? Alignment.centerLeft : Alignment.centerRight);
    final background = isAutoReply
        ? const Color(0xFFF7FAFF)
        : (fromAdmin
              ? const Color(0xFFF2F6FC)
              : AppColors.primary.withValues(alpha: 0.12));
    final border = isAutoReply
        ? const Color(0xFFBFDBFE)
        : (fromAdmin
              ? const Color(0xFFD8E2F3)
              : AppColors.primary.withValues(alpha: 0.28));
    final nameColor = isAutoReply
        ? AppColors.primary
        : (fromAdmin ? AppColors.textSecondary : AppColors.primaryDark);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAutoReply ? 'Support assistant' : message.senderName,
              style: TextStyle(
                color: nameColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBackgroundGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _ChatBackgroundGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;
  final Color color;

  const _MetaPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
