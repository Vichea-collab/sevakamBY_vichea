import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/support_ticket_options.dart';
import '../../../core/firebase/firebase_storage_service.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/safe_image_provider.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _pollTimer;
  int _currentPage = 1;
  bool _sending = false;
  bool _paging = false;

  @override
  void initState() {
    super.initState();
    if (widget.ticket.id.isNotEmpty) {
      unawaited(_loadInitialMessages());
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
    final displayTitle = widget.ticket.title.trim().isEmpty
        ? supportTicketSubcategoryLabel(
            categoryId: widget.ticket.category,
            subcategoryId: widget.ticket.subcategory,
          )
        : widget.ticket.title;
    final ticketType = supportTicketRequestTypeFromId(widget.ticket.ticketType);
    final topicLabel = supportTicketSubcategoryLabel(
      categoryId: widget.ticket.category,
      subcategoryId: widget.ticket.subcategory,
    );
    final canSend = !_sending && _composerController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppThemeTokens.isDark(context)
                ? const [Color(0xFF0E1728), Color(0xFF142238)]
                : const [Color(0xFFF8FBFF), Color(0xFFF1F5FC)],
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
                        AppTopBar(
                          title:
                              '${supportTicketRequestTypeLabel(ticketType)} chat',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        8,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeTokens.surface(context),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppThemeTokens.outline(context),
                        ),
                        boxShadow: AppThemeTokens.cardShadow(context),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(15),
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
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayTitle,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color:
                                                        AppThemeTokens.textPrimary(
                                                          context,
                                                        ),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _MetaPill(
                                            text: _prettyStatus(
                                              widget.ticket.status,
                                            ),
                                            color: statusColor,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppThemeTokens.mutedSurface(
                                            context,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppThemeTokens.outline(
                                              context,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _HeaderInfoLine(
                                              label: 'Category',
                                              value: supportTicketCategoryLabel(
                                                widget.ticket.category,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _HeaderInfoLine(
                                              label: 'Subcategory',
                                              value: topicLabel,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: AppThemeTokens.outline(context),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                10,
                              ),
                              child: ValueListenableBuilder<List<HelpTicketMessage>>(
                                valueListenable: messageListenable,
                                builder: (context, messages, _) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: loadingListenable,
                                    builder: (context, loading, _) {
                                      return ValueListenableBuilder<
                                        PaginationMeta
                                      >(
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
                                                title:
                                                    'Loading support messages',
                                              ),
                                            );
                                          }
                                          if (messages.isEmpty) {
                                            return const AppStatePanel.empty(
                                              title: 'Conversation is syncing',
                                              message:
                                                  'The support thread is being prepared. Pull to refresh in a moment.',
                                            );
                                          }
                                          return Column(
                                            children: [
                                              Expanded(
                                                child: ListView.separated(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                      ),
                                                  itemCount: messages.length,
                                                  separatorBuilder: (_, _) =>
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                  itemBuilder: (context, index) {
                                                    final item =
                                                        messages[index];
                                                    final fromAdmin =
                                                        item.senderRole
                                                            .toLowerCase() ==
                                                        'admin';
                                                    final isAutoReply =
                                                        item.type
                                                            .toLowerCase() ==
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                      ),
                                                  child: PaginationBar(
                                                    currentPage:
                                                        _normalizedPage(
                                                          pagination.page,
                                                        ),
                                                    totalPages:
                                                        pagination.totalPages,
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
                          Divider(
                            height: 1,
                            color: AppThemeTokens.outline(context),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppThemeTokens.mutedSurface(context),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: AppThemeTokens.outline(context),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reply to support',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _sending ? null : _sendImage,
                                        icon: Icon(
                                          Icons.image_rounded,
                                          color: _sending
                                              ? AppThemeTokens.textSecondary(
                                                  context,
                                                )
                                              : AppColors.primary,
                                        ),
                                        tooltip: 'Attach image',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: AppTextField(
                                          hint:
                                              'Type your message to support...',
                                          controller: _composerController,
                                          onChanged: (_) => setState(() {}),
                                          minLines: 1,
                                          maxLines: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final compactComposer =
                                          constraints.maxWidth < 360;
                                      if (compactComposer) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _sending
                                                  ? 'Sending your reply...'
                                                  : 'Support replies appear here automatically.',
                                              style: TextStyle(
                                                color:
                                                    AppThemeTokens.textSecondary(
                                                      context,
                                                    ),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            PrimaryButton(
                                              label: _sending
                                                  ? 'Sending...'
                                                  : 'Send message',
                                              onPressed: canSend ? _send : null,
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _sending
                                                  ? 'Sending your reply...'
                                                  : 'Support replies appear here automatically.',
                                              style: TextStyle(
                                                color:
                                                    AppThemeTokens.textSecondary(
                                                      context,
                                                    ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          FilledButton.icon(
                                            onPressed: canSend ? _send : null,
                                            icon: const Icon(
                                              Icons.send_rounded,
                                            ),
                                            label: Text(
                                              _sending
                                                  ? 'Sending...'
                                                  : 'Send message',
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
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

  Future<void> _loadInitialMessages() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await ProfileSettingsState.refreshCurrentHelpTicketMessages(
          ticketId: widget.ticket.id,
          page: _currentPage,
        );
        return;
      } catch (_) {
        if (attempt == 2) return;
        await Future<void>.delayed(const Duration(milliseconds: 350));
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

  Future<void> _sendImage() async {
    if (widget.ticket.id.isEmpty) {
      AppToast.error(context, 'Ticket not synced yet. Please re-open chat.');
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          AppToast.warning(context, 'Selected image is empty.');
        }
        return;
      }

      setState(() => _sending = true);

      final extension = _fileExtension(picked.name);
      final downloadUrl = await FirebaseStorageService.uploadMessageImage(
        bytes,
        extension: extension,
        folder: 'ticket_images',
        filePrefix: 'ticket',
      );
      if (downloadUrl == null || downloadUrl.isEmpty) {
        if (mounted) {
          AppToast.error(context, 'Failed to upload image.');
        }
        return;
      }

      await ProfileSettingsState.sendCurrentHelpTicketMessage(
        ticketId: widget.ticket.id,
        text: downloadUrl,
        imageUrl: downloadUrl,
      );
      _currentPage = 1;
      await ProfileSettingsState.refreshCurrentHelpTicketMessages(
        ticketId: widget.ticket.id,
        page: _currentPage,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to send image.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _fileExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) return 'jpg';
    return name.substring(dot + 1).toLowerCase();
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
    final isDark = AppThemeTokens.isDark(context);
    final alignment = isAutoReply
        ? Alignment.centerLeft
        : (fromAdmin ? Alignment.centerLeft : Alignment.centerRight);
    final background = isAutoReply
        ? (isDark ? const Color(0xFF172335) : const Color(0xFFF8FAFD))
        : (fromAdmin
              ? (isDark ? const Color(0xFF121F31) : const Color(0xFFF4F7FB))
              : (isDark ? const Color(0xFF162846) : const Color(0xFFEEF4FF)));
    final border = isAutoReply
        ? (isDark ? const Color(0xFF304768) : const Color(0xFFD8E7FF))
        : (fromAdmin
              ? (isDark ? const Color(0xFF27364D) : const Color(0xFFDCE4F2))
              : AppColors.primary.withValues(alpha: 0.22));
    final nameColor = isAutoReply
        ? const Color(0xFF2563EB)
        : (fromAdmin ? AppColors.textSecondary : AppColors.primaryDark);
    final label = isAutoReply
        ? 'Support assistant'
        : (fromAdmin ? 'Admin support' : 'You');
    final hasImage = message.imageUrl.isNotEmpty;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppThemeTokens.cardShadow(context),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: AppThemeTokens.textSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (!isAutoReply && message.senderName.trim().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                message.senderName,
                style: TextStyle(
                  color: AppThemeTokens.textSecondary(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            if (hasImage)
              GestureDetector(
                onTap: () => _showFullScreenImage(context, message.imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildImage(message.imageUrl),
                ),
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  color: AppThemeTokens.textPrimary(context),
                  height: 1.45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    return SafeImage(
      source: url,
      width: 220,
      height: 150,
      fit: BoxFit.cover,
      errorBuilder: const _ImageErrorPlaceholder(),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: url.startsWith('data:')
                    ? Builder(
                        builder: (_) {
                          final comma = url.indexOf(',');
                          if (comma > 0 && comma < url.length - 1) {
                            try {
                              final bytes = base64Decode(
                                url.substring(comma + 1),
                              );
                              return Image.memory(
                                Uint8List.fromList(bytes),
                                fit: BoxFit.contain,
                              );
                            } catch (_) {
                              return const _ImageErrorPlaceholder();
                            }
                          }
                          return const _ImageErrorPlaceholder();
                        },
                      )
                    : SafeImage(
                        source: url,
                        fit: BoxFit.contain,
                        errorBuilder: const _ImageErrorPlaceholder(),
                      ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
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

class _HeaderInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              color: AppThemeTokens.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppThemeTokens.textPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 120,
      decoration: BoxDecoration(
        color: AppThemeTokens.mutedSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppThemeTokens.outline(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: AppThemeTokens.textSecondary(context),
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: AppThemeTokens.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
