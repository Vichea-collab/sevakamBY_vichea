import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../core/utils/page_transition.dart';
import '../../core/utils/safe_image_provider.dart';
import '../../domain/entities/chat.dart';
import '../pages/chat/chat_conversation_page.dart';
import '../state/chat_state.dart';
import 'pressable_scale.dart';

Future<void> showNotificationMessengerSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<ChatThread> threads,
  Color accentColor = AppColors.primary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    enableDrag: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _NotificationMessengerSheet(
        title: title,
        subtitle: subtitle,
        threads: threads,
        accentColor: accentColor,
      );
    },
  );
}

class _NotificationMessengerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ChatThread> threads;
  final Color accentColor;

  const _NotificationMessengerSheet({
    required this.title,
    required this.subtitle,
    required this.threads,
    required this.accentColor,
  });

  @override
  State<_NotificationMessengerSheet> createState() =>
      _NotificationMessengerSheetState();
}

class _NotificationMessengerSheetState
    extends State<_NotificationMessengerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late List<ChatThread> _threads;

  @override
  void initState() {
    super.initState();
    _threads = List<ChatThread>.from(widget.threads)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = AppThemeTokens.pageBackground(context);
    return FractionallySizedBox(
      heightFactor: 0.96,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _buildThreadList(),
      ),
    );
  }

  Widget _buildThreadList() {
    final primaryText = AppThemeTokens.textPrimary(context);
    final secondaryText = AppThemeTokens.textSecondary(context);
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? _threads
        : _threads
              .where(
                (thread) =>
                    thread.title.toLowerCase().contains(query) ||
                    thread.subtitle.toLowerCase().contains(query),
              )
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search messages',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'No conversations found',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: secondaryText,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final thread = visible[index];
                    return _MessengerThreadTile(
                      thread: thread,
                      accentColor: widget.accentColor,
                      onTap: () => _openThread(thread),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openThread(ChatThread thread) async {
    final navigator = Navigator.of(context);
    ChatThread resolved = thread;
    try {
      final latest = await ChatState.fetchThreadById(thread.id);
      if (latest != null) {
        resolved = latest;
      }
    } catch (_) {}
    if (!mounted) return;
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    await navigator.push(
      slideFadeRoute(ChatConversationPage(thread: resolved)),
    );
    unawaited(ChatState.markThreadAsRead(resolved.id, syncThreads: true));
    unawaited(ChatState.refreshUnreadCount());
  }
}

class _MessengerThreadTile extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;
  final Color accentColor;

  const _MessengerThreadTile({
    required this.thread,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;
    final isActive =
        DateTime.now().difference(thread.lastActiveAt.toLocal()).inMinutes < 2;
    final primaryText = AppThemeTokens.textPrimary(context);
    final secondaryText = AppThemeTokens.textSecondary(context);
    final surface = AppThemeTokens.surface(context);
    final mutedSurface = AppThemeTokens.mutedSurface(context);
    final outline = AppThemeTokens.outline(context);
    final isDark = AppThemeTokens.isDark(context);
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: hasUnread
                ? accentColor.withValues(alpha: 0.04)
                : surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUnread
                  ? accentColor.withValues(alpha: 0.12)
                  : outline.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: mutedSurface,
                    backgroundImage: thread.avatarPath.trim().isNotEmpty
                        ? safeImageProvider(thread.avatarPath)
                        : null,
                    child: thread.avatarPath.trim().isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 30,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success
                            : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1)),
                        shape: BoxShape.circle,
                        border: Border.all(color: surface, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: primaryText,
                                  fontWeight: hasUnread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeLabel(thread.updatedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: hasUnread
                                    ? accentColor
                                    : secondaryText,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: hasUnread
                                      ? primaryText
                                      : secondaryText,
                                  fontSize: 14,
                                ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor,
                                  accentColor.withValues(alpha: 0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays >= 1) {
      return '${dateTime.day}/${dateTime.month}';
    }
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
