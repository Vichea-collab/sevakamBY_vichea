import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../core/utils/category_utils.dart';
import '../../../data/network/backend_api_client.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/provider.dart';
import '../../state/chat_state.dart';
import '../../state/app_role_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/pressable_scale.dart';
import '../providers/provider_detail_page.dart';

class ChatConversationPage extends StatefulWidget {
  final ChatThread thread;

  const ChatConversationPage({super.key, required this.thread});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
  Timer? _heartbeatTimer;
  bool _realtimeActive = false;

  @override
  void initState() {
    super.initState();
    unawaited(_syncReadState(syncThreads: true));
    unawaited(ChatState.flushQueuedMessages(threadId: widget.thread.id));
    
    // Delay heavy data loading slightly to ensure smooth route transition
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_loadInitial());
      unawaited(_bindRealtimeMessages());
      _startFallbackRefreshTimer();
      _startHeartbeat();
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    final subscription = _messagesSubscription;
    _messagesSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _fallbackRefreshTimer?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _startHeartbeat() {
    ChatState.updateHeartbeat();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      ChatState.updateHeartbeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              thread: widget.thread,
              onProfileLinkTap: AppRoleState.isProvider ? _sendProfileLink : null,
            ),
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

    // PROFESSIONAL CHAT UI: Use reverse list for sticky bottom behavior
    // and to prevent scroll jumping when new messages arrive.
    final reversedMessages = messages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      itemCount: reversedMessages.length + (hasOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == reversedMessages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
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
          );
        }

        final message = reversedMessages[index];
        final next = index < reversedMessages.length - 1 ? reversedMessages[index + 1] : null;
        
        final showDateHeader =
            next == null ||
            !_isSameCalendarDay(next.sentAt, message.sentAt);

        return Column(
          key: ValueKey('msg_${message.id}'),
          children: [
            if (showDateHeader)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: _ChatDateChip(label: _dateLabel(message.sentAt)),
              ),
            _MessageBubble(message: message),
          ],
        );
      },
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
      unawaited(_syncReadState(syncThreads: true));
      _scheduleScrollToLatest(animated: false);
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
      _scheduleScrollToLatest(animated: false);
      _ackDeliveredFromMessages(result.items);
      final hasUnread = ChatState.threads.value.any(
        (thread) => thread.id == widget.thread.id && thread.unreadCount > 0,
      );
      if (hasUnread) {
        unawaited(_syncReadState(syncThreads: true));
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
        final shouldStickToLatest = _isNearLatest();
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
        if (shouldStickToLatest) {
          _scheduleScrollToLatest(animated: true);
        }
        if (needsReadAck) {
          unawaited(_syncReadState());
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

  Future<void> _syncReadState({bool syncThreads = false}) {
    return ChatState.markThreadAsRead(
      widget.thread.id,
      syncThreads: syncThreads,
    );
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

  bool _isSameCalendarDay(DateTime left, DateTime right) {
    final a = left.toLocal();
    final b = right.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateLabel(DateTime value) {
    final date = value.toLocal();
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month';
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
    _scheduleScrollToLatest(animated: true);
    setState(() => _sending = true);
    try {
      final sent = await ChatState.sendMessage(
        threadId: widget.thread.id,
        text: text,
        clientMessageId: localId,
      );
      if (!mounted) return;
      _replaceLocalMessage(localId, sent);
      _scheduleScrollToLatest(animated: true);
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
      
      final extension = _extensionFromName(picked.name);
      final mimeType = _mimeTypeFromExtension(extension);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      final pending = ChatMessage(
        id: localId,
        text: '',
        type: ChatMessageType.image,
        imageUrl: dataUrl,
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
      _scheduleScrollToLatest(animated: true);
      setState(() => _sending = true);
      final sent = await ChatState.sendImageMessage(
        threadId: widget.thread.id,
        bytes: bytes,
        fileName: picked.name,
        clientMessageId: localId,
      );
      if (!mounted) return;
      _replaceLocalMessage(localId, sent);
      _scheduleScrollToLatest(animated: true);
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

  static String _extensionFromName(String fileName) {
    final trimmed = fileName.trim();
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0 || dot >= trimmed.length - 1) return '.jpg';
    return '.${trimmed.substring(dot + 1).toLowerCase()}';
  }

  static String _mimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _sendProfileLink() async {
    if (!AppRoleState.isProvider) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final text = 'PROTOCOL:VIEW_PROFILE:$uid';
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
    });
    _scheduleScrollToLatest(animated: true);
    try {
      final sent = await ChatState.sendMessage(
        threadId: widget.thread.id,
        text: text,
        clientMessageId: localId,
      );
      if (!mounted) return;
      _replaceLocalMessage(localId, sent);
      _scheduleScrollToLatest(animated: true);
      if (!_realtimeActive) {
        await _refreshLatest();
      }
    } catch (_) {
      if (mounted) {
        _removeLocalMessage(localId);
        AppToast.error(context, 'Unable to send profile link.');
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
    _scheduleScrollToLatest(animated: true);
  }

  void _removeLocalMessage(String localId) {
    setState(() {
      _latestMessages = _latestMessages
          .where((message) => message.id != localId)
          .toList(growable: false);
    });
  }

  bool _isNearLatest() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 80;
  }

  void _scheduleScrollToLatest({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      // With reverse: true, the bottom of the chat is offset 0.0
      if (animated) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      _scrollController.jumpTo(0.0);
    });
  }
}

class _ChatHeader extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback? onProfileLinkTap;

  const _ChatHeader({required this.thread, this.onProfileLinkTap});

  @override
  Widget build(BuildContext context) {
    final status = _activityStatus(thread.lastActiveAt);
    final isProvider = AppRoleState.isProvider;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A0F172A),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: safeImageProvider(thread.avatarPath),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: status.color,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: isProvider ? Icons.assignment_turned_in_rounded : Icons.info_outline_rounded,
            onTap: () {
              if (isProvider && onProfileLinkTap != null) {
                onProfileLinkTap!();
              } else {
                // Show context info for finder
              }
            },
          ),
        ],
      ),
    );
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

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 20),
        ),
      ),
    );
  }
}

class _ChatDateChip extends StatelessWidget {
  final String label;

  const _ChatDateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final fromMe = message.fromMe;
    final accentColor =
        AppRoleState.isProvider ? const Color(0xFF818CF8) : AppColors.primary;
    final bubbleColor = fromMe ? accentColor : Colors.white;
    final textColor = fromMe ? Colors.white : const Color(0xFF0F172A);

    final hasImage =
        message.type == ChatMessageType.image &&
        message.imageUrl.trim().isNotEmpty;
    final hasText = message.text.trim().isNotEmpty;

    final isProfileLink = message.text.startsWith('PROTOCOL:VIEW_PROFILE:');
    final providerUid =
        isProfileLink ? message.text.split(':').last.trim() : null;

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            constraints: const BoxConstraints(maxWidth: 280),
            padding: EdgeInsets.symmetric(
              horizontal: isProfileLink ? 0 : 14,
              vertical: isProfileLink ? 0 : 11,
            ),
            decoration: BoxDecoration(
              color: isProfileLink ? Colors.transparent : bubbleColor,
              gradient:
                  (fromMe && !isProfileLink)
                      ? LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(fromMe ? 20 : 4),
                bottomRight: Radius.circular(fromMe ? 4 : 20),
              ),
              boxShadow: [
                if (!isProfileLink)
                  BoxShadow(
                    color:
                        fromMe
                            ? accentColor.withValues(alpha: 0.2)
                            : const Color(0x080F172A),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage && !isProfileLink)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SafeImage(
                        source: message.imageUrl,
                        width: 240,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (isProfileLink && providerUid != null)
                  _ProfileLinkCard(
                    uid: providerUid,
                    fromMe: fromMe,
                    accentColor: accentColor,
                  )
                else if (hasText)
                  Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.sentAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fromMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(accentColor),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(Color accentColor) {
    IconData icon;
    Color color = const Color(0xFF94A3B8);
    String label = '';
    switch (message.deliveryStatus) {
      case ChatDeliveryStatus.sending:
        icon = Icons.access_time_rounded;
      case ChatDeliveryStatus.sent:
        icon = Icons.check_rounded;
      case ChatDeliveryStatus.delivered:
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.seen:
        icon = Icons.done_all_rounded;
        color = accentColor;
        label = 'Seen';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Icon(icon, size: 12, color: color),
      ],
    );
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _ProfileLinkCard extends StatefulWidget {
  final String uid;
  final bool fromMe;
  final Color accentColor;

  const _ProfileLinkCard({
    required this.uid,
    required this.fromMe,
    required this.accentColor,
  });

  @override
  State<_ProfileLinkCard> createState() => _ProfileLinkCardState();
}

class _ProfileLinkCardState extends State<_ProfileLinkCard> {
  ProviderItem? _provider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProvider();
  }

  Future<void> _fetchProvider() async {
    try {
      final post = await ProviderPostState.findLatestByUid(widget.uid);
      if (post != null && mounted) {
        setState(() {
          final role = post.category.trim().isEmpty ? 'Cleaner' : post.category;
          _provider = ProviderItem(
            uid: post.providerUid.trim(),
            name:
                post.providerName.trim().isEmpty
                    ? 'Service Provider'
                    : post.providerName.trim(),
            role: role,
            rating: post.rating,
            imagePath: post.avatarPath,
            accentColor: accentForCategory(role),
            services: post.serviceList,
            providerType: post.providerType,
            companyName: post.providerCompanyName.trim(),
            maxWorkers:
                post.providerMaxWorkers < 1 ? 1 : post.providerMaxWorkers,
            blockedDates: post.blockedDates,
            latitude: post.latitude,
            longitude: post.longitude,
            isVerified: post.isVerified,
          );
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: 200,
        height: 80,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final p = _provider;
    if (p == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Profile link unavailable'),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          slideFadeRoute(ProviderDetailPage(provider: p)),
        );
      },
      child: PressableScale(
        onTap: () {
          Navigator.push(
            context,
            slideFadeRoute(ProviderDetailPage(provider: p)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: safeImageProvider(p.imagePath),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Professional ${p.role}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.isVerified)
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Check Information',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: widget.accentColor,
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
    final accentColor = AppRoleState.isProvider ? const Color(0xFF818CF8) : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ComposerAction(icon: Icons.add_circle_outline_rounded, onTap: onPickImage),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: onSend,
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ComposerAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF64748B), size: 24),
        ),
      ),
    );
  }
}
