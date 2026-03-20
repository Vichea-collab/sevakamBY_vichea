import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/entities/pagination.dart';
import '../../state/chat_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/pressable_scale.dart';
import 'chat_conversation_page.dart';

class ChatListPage extends StatefulWidget {
  static const String routeName = '/chat';

  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isPaging = false;
  bool _refreshInProgress = false;
  Timer? _uiRefreshTimer;

  @override
  void initState() {
    super.initState();
    ChatState.refresh(page: 1);
    _startUiRefreshTimer();
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startUiRefreshTimer() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return ValueListenableBuilder<List<ChatThread>>(
      valueListenable: ChatState.threads,
      builder: (context, threads, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ChatState.loading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<PaginationMeta>(
              valueListenable: ChatState.threadPagination,
              builder: (context, pagination, _) {
                final query = _query.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? threads
                    : threads
                          .where(
                            (chat) =>
                                chat.title.toLowerCase().contains(query) ||
                                chat.subtitle.toLowerCase().contains(query),
                          )
                          .toList();
                final resultCount = query.isEmpty
                    ? pagination.totalItems
                    : filtered.length;
                final currentPage = _normalizedPage(pagination.page);

                final Widget body;
                if (isLoading && threads.isEmpty) {
                  body = _pullablePlaceholder(
                    const AppStatePanel.loading(title: 'Loading conversations'),
                  );
                } else if (filtered.isEmpty) {
                  body = _pullablePlaceholder(
                    AppStatePanel.empty(
                      title: 'No conversation yet',
                      message: query.isEmpty
                          ? 'Start chatting with a provider or customer.'
                          : 'No messages matched your search.',
                    ),
                  );
                } else {
                  body = ListView.separated(
                    key: ValueKey<String>(
                      'chat_list_${filtered.length}_${currentPage}_$query',
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final thread = filtered[index];
                      return _ChatThreadTile(thread: thread);
                    },
                  );
                }

                return Scaffold(
                  body: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            rs.space(10),
                            rs.space(8),
                            rs.space(10),
                            rs.space(4),
                          ),
                          child: AppTopBar(title: 'Chats'),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            rs.space(16),
                            rs.space(8),
                            rs.space(16),
                            rs.space(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              hintText: 'Search for messages or users',
                              prefixIcon: const Icon(Icons.search),
                              suffixText: '$resultCount',
                              isDense: true,
                            ),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _handleRefresh,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: body,
                            ),
                          ),
                        ),
                        if (pagination.totalPages > 1 && query.isEmpty)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              rs.space(12),
                              rs.space(4),
                              rs.space(12),
                              rs.space(12),
                            ),
                            child: PaginationBar(
                              currentPage: currentPage,
                              totalPages: pagination.totalPages,
                              loading: _isPaging,
                              onPageSelected: _goToPage,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _goToPage(int page) async {
    final targetPage = _normalizedPage(page);
    if (_isPaging || targetPage == ChatState.threadPagination.value.page) {
      return;
    }
    setState(() => _isPaging = true);
    try {
      await ChatState.refresh(page: targetPage);
    } finally {
      if (mounted) {
        setState(() => _isPaging = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      await ChatState.refresh(page: 1);
      await ChatState.refreshUnreadCount();
    } catch (_) {
      // Keep current chat list when refresh fails.
    } finally {
      _refreshInProgress = false;
    }
  }

  Widget _pullablePlaceholder(Widget child) {
    final rs = context.rs;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        SizedBox(height: rs.dimension(160)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rs.space(24)),
          child: child,
        ),
      ],
    );
  }

  int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }
}

class _ChatThreadTile extends StatelessWidget {
  final ChatThread thread;

  const _ChatThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final hasUnread = thread.unreadCount > 0;
    const accentColor = AppColors.primary;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive =
        DateTime.now().difference(thread.lastActiveAt.toLocal()).inMinutes < 2;

    void openConversation() {
      final currentPage = ChatState.threadPagination.value.page;

      // Navigate immediately without awaiting
      Navigator.push(
        context,
        slideFadeRoute(ChatConversationPage(thread: thread)),
      ).then((_) {
        if (!context.mounted) return;
        unawaited(ChatState.refresh(page: currentPage < 1 ? 1 : currentPage));
        unawaited(ChatState.refreshUnreadCount());
      });

      // Sync read state in background
      unawaited(ChatState.markThreadAsRead(thread.id, syncThreads: true));
    }

    return PressableScale(
      onTap: openConversation,
      child: InkWell(
        onTap: openConversation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: rs.space(16),
            vertical: rs.space(14),
          ),
          decoration: BoxDecoration(
            color: hasUnread
                ? accentColor.withValues(alpha: isDark ? 0.12 : 0.03)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: rs.dimension(28),
                    backgroundColor: isDark
                        ? const Color(0xFF162133)
                        : AppColors.background,
                    backgroundImage: thread.avatarPath.trim().isNotEmpty
                        ? safeImageProvider(thread.avatarPath)
                        : null,
                    child: thread.avatarPath.trim().isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            size: rs.icon(32),
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: rs.dimension(14),
                      height: rs.dimension(14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success
                            : const Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              rs.gapW(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: hasUnread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  fontSize: rs.text(16),
                                  letterSpacing: -0.3,
                                ),
                          ),
                        ),
                        Text(
                          _timeLabel(thread.updatedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: hasUnread
                                    ? accentColor
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    rs.gapH(4),
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
                                      ? theme.colorScheme.onSurface
                                      : theme.textTheme.bodyMedium?.color,
                                  fontSize: rs.text(14),
                                ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: EdgeInsets.only(left: rs.space(8)),
                            padding: EdgeInsets.symmetric(
                              horizontal: rs.space(8),
                              vertical: rs.space(3),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor,
                                  accentColor.withValues(alpha: 0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                rs.radius(10),
                              ),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
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
    if (diff.inDays >= 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (diff.inDays >= 1) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    }
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
