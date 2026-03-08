import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/safe_image_provider.dart';
import '../../domain/entities/chat.dart';
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
  final TextEditingController _composerController = TextEditingController();
  String _query = '';
  late List<ChatThread> _threads;
  ChatThread? _activeThread;
  List<ChatMessage> _activeMessages = const [];

  @override
  void initState() {
    super.initState();
    _threads = List<ChatThread>.from(widget.threads)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.96,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _activeThread == null
            ? _buildThreadList()
            : _buildConversation(),
      ),
    );
  }

  Widget _buildThreadList() {
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
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
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
                      color: AppColors.textSecondary,
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
                      onTap: () {
                        setState(() {
                          _activeThread = thread;
                          _activeMessages = List<ChatMessage>.from(
                            thread.messages,
                          );
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConversation() {
    final thread = _activeThread!;
    final status = _activityStatus(thread.updatedAt);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _activeThread = null),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              CircleAvatar(
                radius: 18,
                backgroundImage: safeImageProvider(thread.avatarPath),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      status.label,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: status.color),
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
        Expanded(
          child: ListView.builder(
            reverse: false,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: _activeMessages.length,
            itemBuilder: (context, index) {
              return _MessengerBubble(
                message: _activeMessages[index],
                accentColor: widget.accentColor,
              );
            },
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _composerController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write a message',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                onTap: _sendMessage,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _sendMessage,
                  child: Ink(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _composerController.text.trim();
    if (text.isEmpty || _activeThread == null) return;
    final message = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      fromMe: true,
      sentAt: DateTime.now(),
      deliveryStatus: ChatDeliveryStatus.delivered,
    );
    setState(() {
      _activeMessages = [..._activeMessages, message];
      _composerController.clear();
      _refreshThreadPreview(message);
    });
  }

  void _refreshThreadPreview(ChatMessage latest) {
    final thread = _activeThread;
    if (thread == null) return;
    final updatedThread = ChatThread(
      id: thread.id,
      title: thread.title,
      subtitle: latest.text,
      avatarPath: thread.avatarPath,
      updatedAt: latest.sentAt,
      lastActiveAt: thread.lastActiveAt,
      unreadCount: 0,
      messages: _activeMessages,
    );
    _threads =
        _threads
            .map((item) => item.id == updatedThread.id ? updatedThread : item)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _activeThread = updatedThread;
  }

  ({String label, Color color}) _activityStatus(DateTime lastActiveAt) {
    final delta = DateTime.now().difference(lastActiveAt.toLocal());
    if (delta.inMinutes < 5) {
      return (label: 'Active now', color: AppColors.success);
    }
    const inactiveColor = Color(0xFF94A3B8);
    if (delta.inHours < 1) {
      return (label: 'Active ${delta.inMinutes}m ago', color: inactiveColor);
    }
    if (delta.inDays < 1) {
      return (label: 'Active ${delta.inHours}h ago', color: inactiveColor);
    }
    return (label: 'Active ${delta.inDays}d ago', color: inactiveColor);
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
    final isActive = DateTime.now().difference(thread.lastActiveAt.toLocal()).inMinutes < 5;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x080F172A),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: safeImageProvider(thread.avatarPath),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success : const Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeLabel(thread.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (thread.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withValues(alpha: 0.85)],
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
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

class _MessengerBubble extends StatelessWidget {
  final ChatMessage message;
  final Color accentColor;

  const _MessengerBubble({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final fromMe = message.fromMe;
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: fromMe ? LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              color: fromMe ? null : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(fromMe ? 18 : 4),
                bottomRight: Radius.circular(fromMe ? 4 : 18),
              ),
              boxShadow: [
                if (fromMe)
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: fromMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _timeLabel(message.sentAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
