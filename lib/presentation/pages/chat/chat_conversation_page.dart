import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/network/backend_api_client.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/entities/pagination.dart';
import '../../state/chat_state.dart';
import '../../widgets/app_state_panel.dart';
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _messagesSubscription;
  Timer? _fallbackRefreshTimer;
  bool _realtimeActive = false;

  @override
  void initState() {
    super.initState();
    unawaited(ChatState.markThreadAsRead(widget.thread.id));
    unawaited(ChatState.flushQueuedMessages(threadId: widget.thread.id));
    unawaited(_loadInitial());
    unawaited(_bindRealtimeMessages());
    _startFallbackRefreshTimer();
  }

  @override
  void dispose() {
    final subscription = _messagesSubscription;
    _messagesSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _fallbackRefreshTimer?.cancel();
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: AppStatePanel.loading(title: 'Loading conversation'),
        ),
      );
    }
    final messages = _mergedMessages();
    final hasOlder = _loadedPages < _pagination.totalPages;
    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppStatePanel.empty(
          title: 'No messages yet',
          message: 'Start your conversation.',
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
      _ackDeliveredFromMessages(result.items);
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
    if (_realtimeActive) return;
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
      _ackDeliveredFromMessages(result.items);
      final hasUnread = ChatState.threads.value.any(
        (thread) => thread.id == widget.thread.id && thread.unreadCount > 0,
      );
      if (hasUnread) {
        unawaited(ChatState.markThreadAsRead(widget.thread.id));
      }
    } catch (_) {}
  }

  Future<void> _bindRealtimeMessages() async {
    final threadId = widget.thread.id.trim();
    if (threadId.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return;
    final pageLimit = _pagination.limit <= 0 ? 10 : _pagination.limit;
    final stream = FirebaseFirestore.instance
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(pageLimit)
        .snapshots();
    await _messagesSubscription?.cancel();
    _messagesSubscription = stream.listen(
      (snapshot) {
        if (!mounted) return;
        final needsReadAck = snapshot.docs.any((doc) {
          final row = doc.data();
          final senderUid = (row['senderUid'] ?? '').toString().trim();
          if (senderUid.isEmpty || senderUid == uid) return false;
          final seenBy = (row['seenBy'] is List)
              ? (row['seenBy'] as List)
                    .map((item) => item.toString().trim())
                    .toSet()
              : <String>{};
          return !seenBy.contains(uid);
        });
        final deliveryIds = <String>{};
        final mapped = snapshot.docs
            .map((doc) {
              final row = doc.data();
              final senderUid = (row['senderUid'] ?? '').toString().trim();
              final deliveredTo = (row['deliveredTo'] is List)
                  ? (row['deliveredTo'] as List)
                        .map((item) => item.toString().trim())
                        .toSet()
                  : <String>{};
              final messageId = (row['id'] ?? '').toString().trim();
              if (senderUid.isNotEmpty &&
                  senderUid != uid &&
                  messageId.isNotEmpty &&
                  !deliveredTo.contains(uid)) {
                deliveryIds.add(messageId);
              }
              return _toRealtimeMessage(row, uid);
            })
            .toList(growable: false);
        setState(() {
          _latestMessages = mapped;
          _realtimeActive = true;
          if (_loading) {
            _loading = false;
          }
        });
        if (needsReadAck) {
          unawaited(ChatState.markThreadAsRead(widget.thread.id));
        }
        if (deliveryIds.isNotEmpty) {
          unawaited(
            ChatState.acknowledgeDelivered(
              widget.thread.id,
              messageIds: deliveryIds.toList(growable: false),
            ),
          );
        }
      },
      onError: (_) {
        final subscription = _messagesSubscription;
        _messagesSubscription = null;
        if (subscription != null) {
          unawaited(subscription.cancel());
        }
        if (!mounted) return;
        setState(() {
          _realtimeActive = false;
        });
      },
    );
  }

  void _startFallbackRefreshTimer() {
    _fallbackRefreshTimer?.cancel();
    _fallbackRefreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _realtimeActive || _loading || _sending) return;
      unawaited(_refreshLatest());
    });
  }

  ChatMessage _toRealtimeMessage(Map<String, dynamic> row, String currentUid) {
    final senderUid = (row['senderUid'] ?? '').toString().trim();
    final imageUrl = (row['imageUrl'] ?? '').toString().trim();
    final rawType = (row['type'] ?? '').toString().trim().toLowerCase();
    final type = rawType == 'image' || imageUrl.isNotEmpty
        ? ChatMessageType.image
        : ChatMessageType.text;
    final seenBy = (row['seenBy'] is List)
        ? (row['seenBy'] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final deliveredTo = (row['deliveredTo'] is List)
        ? (row['deliveredTo'] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    return ChatMessage(
      id: (row['id'] ?? '').toString().trim().isEmpty
          ? '${senderUid}_${_toRealtimeDateTime(row['sentAt'] ?? row['createdAt']).millisecondsSinceEpoch}'
          : (row['id'] ?? '').toString().trim(),
      text: (row['text'] ?? '').toString(),
      type: type,
      imageUrl: imageUrl,
      fromMe: senderUid == currentUid,
      sentAt: _toRealtimeDateTime(row['sentAt'] ?? row['createdAt']),
      deliveryStatus: _deliveryStatusForMessage(
        senderUid: senderUid,
        currentUid: currentUid,
        seenBy: seenBy,
        deliveredTo: deliveredTo,
      ),
    );
  }

  ChatDeliveryStatus _deliveryStatusForMessage({
    required String senderUid,
    required String currentUid,
    required List<String> seenBy,
    required List<String> deliveredTo,
  }) {
    if (senderUid != currentUid) return ChatDeliveryStatus.seen;
    final peerSeen = seenBy.any((uid) => uid.isNotEmpty && uid != senderUid);
    if (peerSeen) return ChatDeliveryStatus.seen;
    final peerDelivered = deliveredTo.any(
      (uid) => uid.isNotEmpty && uid != senderUid,
    );
    if (peerDelivered) return ChatDeliveryStatus.delivered;
    return ChatDeliveryStatus.sent;
  }

  DateTime _toRealtimeDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is Map<String, dynamic>) {
      final seconds = value['_seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return DateTime.now();
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
      _ackDeliveredFromMessages(result.items);
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

  void _ackDeliveredFromMessages(List<ChatMessage> messages) {
    final ids = messages
        .where((message) => !message.fromMe)
        .map((message) => message.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) return;
    unawaited(
      ChatState.acknowledgeDelivered(widget.thread.id, messageIds: ids),
    );
  }

  List<ChatMessage> _dedupeAndSort(List<ChatMessage> messages) {
    final seenIds = <String>{};
    final seenFingerprint = <String>{};
    final unique = <ChatMessage>[];
    final sorted = List<ChatMessage>.from(messages)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    for (final message in sorted) {
      final id = message.id.trim();
      if (id.isNotEmpty && seenIds.contains(id)) {
        continue;
      }
      if (id.isNotEmpty && !id.startsWith('local_')) {
        final pendingIndex = unique.indexWhere((queued) {
          if (!queued.fromMe || !queued.id.startsWith('local_')) return false;
          if (queued.type != message.type) return false;
          if (message.type == ChatMessageType.text &&
              queued.text.trim() != message.text.trim()) {
            return false;
          }
          final delta = queued.sentAt.difference(message.sentAt).abs();
          return delta.inMinutes <= 3;
        });
        if (pendingIndex >= 0) {
          unique.removeAt(pendingIndex);
        }
      }
      final key = [
        message.sentAt.millisecondsSinceEpoch,
        message.fromMe ? 1 : 0,
        message.type.index,
        message.text,
        message.imageUrl,
      ].join('|');
      if (id.isNotEmpty) {
        seenIds.add(id);
        unique.add(message);
        continue;
      }
      if (seenFingerprint.add(key)) unique.add(message);
    }
    return unique;
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final pending = ChatMessage(
      id: localId,
      text: text,
      fromMe: true,
      sentAt: DateTime.now(),
      deliveryStatus: ChatDeliveryStatus.sending,
    );
    setState(() {
      _latestMessages = _dedupeAndSort(<ChatMessage>[
        ..._latestMessages,
        pending,
      ]);
      _inputController.clear();
    });
    setState(() => _sending = true);
    try {
      final sent = await ChatState.sendMessage(
        threadId: widget.thread.id,
        text: text,
        clientMessageId: localId,
      );
      if (!mounted) return;
      _replaceLocalMessage(localId, sent);
      if (!_realtimeActive) {
        await _refreshLatest();
      }
    } on ChatQueuedException catch (error) {
      if (!mounted) return;
      AppToast.info(context, error.message);
      unawaited(ChatState.flushQueuedMessages(threadId: widget.thread.id));
    } catch (_) {
      if (mounted) {
        _removeLocalMessage(localId);
        AppToast.error(context, 'Unable to send message right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendImage() async {
    String? pendingLocalId;
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
      final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
      pendingLocalId = localId;
      final pending = ChatMessage(
        id: localId,
        text: '',
        type: ChatMessageType.image,
        fromMe: true,
        sentAt: DateTime.now(),
        deliveryStatus: ChatDeliveryStatus.sending,
      );
      setState(() {
        _latestMessages = _dedupeAndSort(<ChatMessage>[
          ..._latestMessages,
          pending,
        ]);
      });
      setState(() => _sending = true);
      final sent = await ChatState.sendImageMessage(
        threadId: widget.thread.id,
        bytes: bytes,
        fileName: picked.name,
        clientMessageId: localId,
      );
      if (!mounted) return;
      _replaceLocalMessage(localId, sent);
      if (!_realtimeActive) {
        await _refreshLatest();
      }
    } on ChatQueuedException catch (error) {
      if (!mounted) return;
      AppToast.info(context, error.message);
      unawaited(ChatState.flushQueuedMessages(threadId: widget.thread.id));
    } catch (error) {
      if (mounted) {
        if (pendingLocalId != null) {
          _removeLocalMessage(pendingLocalId);
        }
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

  void _replaceLocalMessage(String localId, ChatMessage remote) {
    setState(() {
      _latestMessages = _dedupeAndSort(
        _latestMessages
            .map((message) {
              if (message.id == localId) {
                return remote;
              }
              return message;
            })
            .toList(growable: false),
      );
    });
  }

  void _removeLocalMessage(String localId) {
    setState(() {
      _latestMessages = _latestMessages
          .where((message) => message.id != localId)
          .toList(growable: false);
    });
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeLabel(message.sentAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                  if (message.fromMe) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _statusIcon(message.deliveryStatus),
                      size: 12,
                      color: _statusColor(message.deliveryStatus),
                    ),
                  ],
                ],
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

  IconData _statusIcon(ChatDeliveryStatus status) {
    switch (status) {
      case ChatDeliveryStatus.sending:
        return Icons.schedule_rounded;
      case ChatDeliveryStatus.sent:
        return Icons.done_rounded;
      case ChatDeliveryStatus.delivered:
      case ChatDeliveryStatus.seen:
        return Icons.done_all_rounded;
    }
  }

  Color _statusColor(ChatDeliveryStatus status) {
    switch (status) {
      case ChatDeliveryStatus.seen:
        return AppColors.primary;
      case ChatDeliveryStatus.sending:
      case ChatDeliveryStatus.sent:
      case ChatDeliveryStatus.delivered:
        return AppColors.textSecondary;
    }
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
