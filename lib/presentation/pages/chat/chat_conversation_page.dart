import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/network/backend_api_client.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/entities/pagination.dart';
import '../../state/chat_state.dart';
import '../../widgets/pressable_scale.dart';

class ChatConversationPage extends StatefulWidget {
  final ChatThread thread;

  const ChatConversationPage({super.key, required this.thread});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _inputController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;
  bool _loading = true;
  bool _loadingOlder = false;
  List<ChatMessage> _latestMessages = const <ChatMessage>[];
  List<ChatMessage> _olderMessages = const <ChatMessage>[];
  PaginationMeta _pagination = const PaginationMeta.initial(limit: 10);
  int _loadedPages = 1;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    unawaited(ChatState.markThreadAsRead(widget.thread.id));
    unawaited(_loadInitial());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(_refreshLatest()),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(thread: widget.thread),
            Expanded(
              child: Container(
                color: const Color(0xFFEAF1FF),
                child: _buildMessageList(context),
              ),
            ),
            _Composer(
              controller: _inputController,
              onSend: _sending ? null : _sendMessage,
              onPickImage: _sending ? null : _sendImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final messages = _mergedMessages();
    final hasOlder = _loadedPages < _pagination.totalPages;
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'Start your conversation',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        if (hasOlder)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextButton.icon(
              onPressed: _loadingOlder ? null : _loadOlder,
              icon: _loadingOlder
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_less_rounded),
              label: Text(_loadingOlder ? 'Loading...' : 'Load older messages'),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _MessageBubble(message: messages[index]);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadInitial() async {
    try {
      final result = await ChatState.fetchMessagesPage(
        widget.thread.id,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _latestMessages = result.items;
        _olderMessages = const <ChatMessage>[];
        _pagination = result.pagination;
        _loadedPages = 1;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latestMessages = const <ChatMessage>[];
        _olderMessages = const <ChatMessage>[];
        _loading = false;
      });
    }
  }

  Future<void> _refreshLatest() async {
    if (!mounted) return;
    try {
      final result = await ChatState.fetchMessagesPage(
        widget.thread.id,
        page: 1,
      );
      if (!mounted) return;
      setState(() {
        _latestMessages = result.items;
        _pagination = result.pagination;
      });
    } catch (_) {}
  }

  Future<void> _loadOlder() async {
    final nextPage = _loadedPages + 1;
    if (_loadingOlder || nextPage > _pagination.totalPages) {
      return;
    }
    setState(() => _loadingOlder = true);
    try {
      final result = await ChatState.fetchMessagesPage(
        widget.thread.id,
        page: nextPage,
      );
      if (!mounted) return;
      setState(() {
        _olderMessages = _dedupeAndSort(<ChatMessage>[
          ...result.items,
          ..._olderMessages,
        ]);
        _loadedPages = nextPage;
        _pagination = PaginationMeta(
          page: 1,
          limit: result.pagination.limit,
          totalItems: result.pagination.totalItems,
          totalPages: result.pagination.totalPages,
          hasPrevPage: false,
          hasNextPage: _loadedPages < result.pagination.totalPages,
        );
      });
    } catch (_) {
      // keep current messages when page fetch fails
    } finally {
      if (mounted) {
        setState(() => _loadingOlder = false);
      }
    }
  }

  List<ChatMessage> _mergedMessages() {
    return _dedupeAndSort(<ChatMessage>[..._olderMessages, ..._latestMessages]);
  }

  List<ChatMessage> _dedupeAndSort(List<ChatMessage> messages) {
    final seen = <String>{};
    final unique = <ChatMessage>[];
    final sorted = List<ChatMessage>.from(messages)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    for (final message in sorted) {
      final key = [
        message.sentAt.millisecondsSinceEpoch,
        message.fromMe ? 1 : 0,
        message.type.index,
        message.text,
        message.imageUrl,
      ].join('|');
      if (seen.add(key)) {
        unique.add(message);
      }
    }
    return unique;
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ChatState.sendMessage(threadId: widget.thread.id, text: text);
      _inputController.clear();
      await _refreshLatest();
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Unable to send message right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendImage() async {
    try {
      final picked = await _picker.pickImage(
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
      await ChatState.sendImageMessage(
        threadId: widget.thread.id,
        bytes: bytes,
        fileName: picked.name,
      );
      await _refreshLatest();
    } catch (error) {
      if (mounted) {
        final reason = error is BackendApiException
            ? error.message
            : 'Unable to send image right now.';
        AppToast.error(context, reason);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class _ChatHeader extends StatelessWidget {
  final ChatThread thread;

  const _ChatHeader({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage(thread.avatarPath),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'last seen just now',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final align = message.fromMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.fromMe ? const Color(0xFFCEF6B8) : Colors.white;
    final hasImage =
        message.type == ChatMessageType.image &&
        message.imageUrl.trim().isNotEmpty;
    final hasText = message.text.trim().isNotEmpty;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  message.imageUrl,
                  width: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 240,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x1A000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Image unavailable',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            if (hasImage && hasText) const SizedBox(height: 8),
            if (hasText)
              Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _timeLabel(message.sentAt),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
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

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onPickImage;

  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onPickImage,
            icon: const Icon(Icons.attach_file),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Message',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: onSend,
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.send, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
