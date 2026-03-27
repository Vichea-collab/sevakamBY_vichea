import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/theme/app_theme_tokens.dart';
import 'package:servicefinder/core/utils/app_toast.dart';
import 'package:servicefinder/core/utils/chat_utils.dart';
import 'package:servicefinder/core/utils/page_transition.dart';
import 'package:servicefinder/core/utils/responsive.dart';
import 'package:servicefinder/core/utils/safe_image_provider.dart';
import 'package:servicefinder/core/utils/category_utils.dart';
import 'package:servicefinder/data/network/backend_api_client.dart';
import 'package:servicefinder/domain/entities/chat.dart';
import 'package:servicefinder/domain/entities/pagination.dart';
import 'package:servicefinder/domain/entities/provider.dart';
import 'package:servicefinder/presentation/state/chat_state.dart';
import 'package:servicefinder/presentation/state/app_role_state.dart';
import 'package:servicefinder/presentation/state/provider_post_state.dart';
import 'package:servicefinder/presentation/widgets/app_state_panel.dart';
import 'package:servicefinder/presentation/widgets/pressable_scale.dart';
import 'package:servicefinder/presentation/pages/providers/provider_detail_page.dart';

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
  Timer? _uiRefreshTimer;
  bool _realtimeActive = false;
  ChatThread? _currentThread;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _threadSubscription;

  @override
  void initState() {
    super.initState();
    ChatState.setActiveThread(widget.thread.id);
    unawaited(ChatState.updateHeartbeat());
    unawaited(_syncReadState(syncThreads: true));
    unawaited(ChatState.flushQueuedMessages(threadId: widget.thread.id));

    // Delay heavy data loading slightly to ensure smooth route transition
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(_loadInitial());
      unawaited(_bindRealtimeMessages());
      unawaited(_bindRealtimeThread());
      _startFallbackRefreshTimer();
      _startUiRefreshTimer();
    });
  }

  @override
  void didUpdateWidget(covariant ChatConversationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread.id != widget.thread.id) {
      ChatState.clearActiveThread(oldWidget.thread.id);
      ChatState.setActiveThread(widget.thread.id);
    }
  }

  @override
  void dispose() {
    ChatState.clearActiveThread(widget.thread.id);
    _uiRefreshTimer?.cancel();
    unawaited(_messagesSubscription?.cancel());
    unawaited(_threadSubscription?.cancel());
    _fallbackRefreshTimer?.cancel();
    _scrollController.dispose();
    _inputController.dispose();
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
    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      body: Column(
        children: [
          _ChatHeader(
            thread: _currentThread ?? widget.thread,
            onProfileLinkTap: AppRoleState.isProvider
                ? _sendProfileLink
                : null,
          ),
          Expanded(
            child: Container(
              color: AppThemeTokens.mutedSurface(context),
              child: RefreshIndicator(
                onRefresh: _refreshLatest,
                color: AppColors.primary,
                backgroundColor: AppThemeTokens.surface(context),
                child: _buildMessageList(context),
              ),
            ),
          ),
          _Composer(
            controller: _inputController,
            onSend: _sending ? null : _sendMessage,
            onPickImage: _sending ? null : _sendImage,
          ),
        ],
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          AppStatePanel.empty(
            title: 'No messages yet',
            message: 'Start your conversation.',
          ),
        ],
      );
    }

    final reversedMessages = messages.reversed.toList();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.expand_less_rounded,
                        color: AppColors.primary,
                      ),
                label: Text(
                  _loadingOlder ? 'Loading...' : 'Load older messages',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        final message = reversedMessages[index];
        final next = index < reversedMessages.length - 1
            ? reversedMessages[index + 1]
            : null;

        final showDateHeader =
            next == null || !_isSameCalendarDay(next.sentAt, message.sentAt);

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
    _fallbackRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
      final id = (row['id'] ?? '').toString().trim();
      return ChatMessage(
        id: id.trim().isEmpty
            ? '${senderUid}_${chatDateTimeFromDynamic(row['sentAt'] ?? row['createdAt']).millisecondsSinceEpoch}'
            : id,
        text: (row['text'] ?? '').toString(),
        type: type,
        imageUrl: imageUrl,
        fromMe: senderUid == currentUid,
        sentAt: chatDateTimeFromDynamic(row['sentAt'] ?? row['createdAt']),
        deliveryStatus: chatDeliveryStatus(
          senderUid: senderUid,
          currentUid: currentUid,
          seenBy: seenBy,
          deliveredTo: deliveredTo,
        ),
      );
  }

  // DateTime parsing delegated to chatDateTimeFromDynamic in chat_utils.dart
  // Delivery status logic delegated to chatDeliveryStatus in chat_utils.dart

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

    final extension = chatFileExtension(picked.name);
    final mimeType = chatMimeType(extension);
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

  // File extension and MIME helpers delegated to chatFileExtension / chatMimeType in chat_utils.dart

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

  Future<void> _bindRealtimeThread() async {
    final threadId = widget.thread.id.trim();
    if (threadId.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('chats').doc(threadId);
    await _threadSubscription?.cancel();
    _threadSubscription = docRef.snapshots().listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data() ?? {};

      DateTime? peerHeartbeat;
      final participantMetaRaw = data['participantMeta'];
      if (participantMetaRaw is Map) {
        final participants = (data['participants'] is List)
            ? (data['participants'] as List)
                  .map((e) => e.toString().trim())
                  .toList()
            : <String>[];
        final peerUid = participants.firstWhere(
          (id) => id.isNotEmpty && id != uid,
          orElse: () => '',
        );
        if (peerUid.isNotEmpty) {
          final raw = participantMetaRaw[peerUid];
          if (raw is Map && raw['lastActiveAt'] != null) {
            peerHeartbeat = chatDateTimeFromDynamic(raw['lastActiveAt']);
          }
        }
      }
      final currentLastActiveAt = _currentThread?.lastActiveAt;
      final fallbackLastActiveAt =
          currentLastActiveAt != null && currentLastActiveAt.year >= 2010
          ? currentLastActiveAt
          : widget.thread.lastActiveAt;
      final resolvedLastActiveAt =
          peerHeartbeat ??
          chatDateTimeFromDynamic(
            data['lastActiveAt'] ?? data['peerActiveAt'] ?? 0,
          );
      final lastActiveAt = resolvedLastActiveAt.year >= 2010
          ? resolvedLastActiveAt
          : fallbackLastActiveAt;

      final title = (data['title'] ?? '').toString().trim();
      final lastMessageText = (data['lastMessageText'] ?? '').toString().trim();
      final lastSenderUid = (data['lastSenderUid'] ?? '').toString().trim();
      final subtitle = (data['subtitle'] ?? '').toString().trim();

      final resolvedSubtitle = subtitle.isNotEmpty
          ? subtitle
          : (lastSenderUid == uid ? 'You: $lastMessageText' : lastMessageText);

      setState(() {
        _currentThread = ChatThread(
          id: threadId,
          peerUid: _currentThread?.peerUid ?? widget.thread.peerUid,
          title: title.isNotEmpty ? title : widget.thread.title,
          subtitle: resolvedSubtitle.isNotEmpty
              ? resolvedSubtitle
              : widget.thread.subtitle,
          avatarPath: widget.thread.avatarPath,
          updatedAt: chatDateTimeFromDynamic(
            data['updatedAt'] ?? data['lastMessageAt'] ?? 0,
          ),
          lastActiveAt: lastActiveAt,
          unreadCount: (data['unreadCounts'] is Map)
              ? (data['unreadCounts'][uid] ?? 0)
              : 0,
          messages: _latestMessages,
        );
      });
    }, onError: (_) {
      // Keep the current thread visible if realtime thread access fails.
    });
  }

  bool _isNearLatest() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    // With reverse: true, latest messages are at offset 0.0
    return position.pixels <= 80;
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
    final rs = context.rs;
    final status = _activityStatus(thread.lastActiveAt);
    final isProvider = AppRoleState.isProvider;
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        boxShadow: AppThemeTokens.cardShadow(context),
      ),
      padding: EdgeInsets.fromLTRB(
        rs.space(4),
        topInset + rs.space(8),
        rs.space(8),
        rs.space(10),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF64748B),
            ),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: rs.dimension(20),
                backgroundColor: AppColors.background,
                backgroundImage: thread.avatarPath.trim().isNotEmpty
                    ? safeImageProvider(thread.avatarPath)
                    : null,
                child: thread.avatarPath.trim().isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: rs.icon(24),
                        color: AppColors.primary,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: rs.dimension(10),
                  height: rs.dimension(10),
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppThemeTokens.surface(context),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          rs.gapW(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppThemeTokens.textPrimary(context),
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
            icon: isProvider
                ? Icons.assignment_turned_in_rounded
                : Icons.info_outline_rounded,
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
    final local = lastActiveAt.toLocal();
    final now = DateTime.now();
    final delta = now.difference(local);

    // If date is uninitialized or extremely old (1970 epoch), show general Offline
    if (local.year < 2010) {
      return (label: 'Offline', color: const Color(0xFF94A3B8));
    }

    if (delta.inMinutes < 2) {
      return (label: 'Active now', color: AppColors.success);
    }

    const inactiveColor = Color(0xFF94A3B8);

    if (delta.inMinutes < 60) {
      return (label: 'Active ${delta.inMinutes} min ago', color: inactiveColor);
    }

    if (delta.inHours < 24) {
      return (label: 'Active ${delta.inHours} hr ago', color: inactiveColor);
    }

    final timeStr =
        "${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}";

    if (delta.inDays < 2) {
      final yesterday = now.subtract(const Duration(days: 1));
      if (local.day == yesterday.day &&
          local.month == yesterday.month &&
          local.year == yesterday.year) {
        return (label: 'Active yesterday at $timeStr', color: inactiveColor);
      }
    }

    if (delta.inDays < 7) {
      return (label: 'Active ${delta.inDays}d ago', color: inactiveColor);
    }

    final dateLabel = '${local.day}/${local.month}/${local.year}';
    return (label: 'Active $dateLabel', color: inactiveColor);
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(rs.radius(12)),
        child: Container(
          padding: rs.all(8),
          decoration: BoxDecoration(
            color: AppThemeTokens.mutedSurface(context),
            borderRadius: BorderRadius.circular(rs.radius(10)),
          ),
          child: Icon(
            icon,
            color: AppThemeTokens.textSecondary(context),
            size: rs.icon(20),
          ),
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
    final rs = context.rs;
    final isDark = AppThemeTokens.isDark(context);
    return Container(
      margin: EdgeInsets.symmetric(vertical: rs.space(16)),
      padding: EdgeInsets.symmetric(
        horizontal: rs.space(14),
        vertical: rs.space(6),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF223048) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(rs.radius(20)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppThemeTokens.textSecondary(context),
          fontWeight: FontWeight.w700,
          fontSize: rs.text(11),
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
    final rs = context.rs;
    final fromMe = message.fromMe;
    const accentColor = AppColors.primary;
    final bubbleColor = fromMe ? accentColor : AppThemeTokens.surface(context);
    final textColor = fromMe
        ? Colors.white
        : AppThemeTokens.textPrimary(context);

    final hasImage =
        message.type == ChatMessageType.image &&
        message.imageUrl.trim().isNotEmpty;
    final hasText = message.text.trim().isNotEmpty;

    final isProfileLink = message.text.startsWith('PROTOCOL:VIEW_PROFILE:');
    final providerUid = isProfileLink
        ? message.text.split(':').last.trim()
        : null;

    final isLocalDataUrl = message.imageUrl.startsWith('data:');
    final maxBubbleWidth =
        (MediaQuery.of(context).size.width * (rs.compact ? 0.8 : 0.72)).clamp(
          220.0,
          360.0,
        );
    final imageWidth = math.max(180.0, maxBubbleWidth - rs.space(40));

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: fromMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: rs.space(4)),
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            padding: EdgeInsets.symmetric(
              horizontal: isProfileLink ? 0 : rs.space(14),
              vertical: isProfileLink ? 0 : rs.space(11),
            ),
            decoration: BoxDecoration(
              color: isProfileLink ? Colors.transparent : bubbleColor,
              gradient: (fromMe && !isProfileLink)
                  ? LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(rs.radius(20)),
                topRight: Radius.circular(rs.radius(20)),
                bottomLeft: Radius.circular(rs.radius(fromMe ? 20 : 4)),
                bottomRight: Radius.circular(rs.radius(fromMe ? 4 : 20)),
              ),
              boxShadow: [
                if (!isProfileLink)
                  BoxShadow(
                    color: fromMe
                        ? accentColor.withValues(alpha: 0.2)
                        : AppThemeTokens.cardShadow(context).first.color,
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
                    padding: EdgeInsets.only(bottom: rs.space(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(rs.radius(14)),
                      child: isLocalDataUrl
                          ? _buildLocalImage(
                              message.imageUrl,
                              width: imageWidth,
                              height: imageWidth * 0.66,
                            )
                          : SafeImage(
                              source: message.imageUrl,
                              width: imageWidth,
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
                      fontSize: rs.text(15),
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rs.space(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.sentAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemeTokens.textSecondary(context),
                    fontSize: rs.text(10),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fromMe) ...[
                  rs.gapW(4),
                  _buildStatusIcon(context, accentColor),
                ],
              ],
            ),
          ),
          rs.gapH(12),
        ],
      ),
    );
  }

  Widget _buildLocalImage(
    String dataUrl, {
    required double width,
    required double height,
  }) {
    try {
      final base64String = dataUrl.split(',').last;
      final bytes = base64Decode(base64String);
      return Image.memory(bytes, width: width, fit: BoxFit.cover);
    } catch (_) {
      return SizedBox(
        width: width,
        height: height,
        child: Icon(Icons.broken_image_rounded, color: Colors.grey),
      );
    }
  }

  Widget _buildStatusIcon(BuildContext context, Color accentColor) {
    final rs = context.rs;
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
              fontSize: rs.text(10),
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          rs.gapW(4),
        ],
        Icon(icon, size: rs.icon(12), color: color),
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
            name: post.providerName.trim().isEmpty
                ? 'Service Provider'
                : post.providerName.trim(),
            role: role,
            rating: post.rating,
            imagePath: post.avatarPath,
            accentColor: accentForCategory(role),
            services: post.serviceList,
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
    final rs = context.rs;
    if (_loading) {
      return Container(
        width: rs.dimension(200),
        height: rs.dimension(80),
        alignment: Alignment.center,
        child: SizedBox(
          width: rs.dimension(20),
          height: rs.dimension(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
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

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          slideFadeRoute(ProviderDetailPage(provider: p)),
        );
      },
      child: Container(
        padding: rs.all(12),
        decoration: BoxDecoration(
          color: AppThemeTokens.surface(context),
          borderRadius: BorderRadius.circular(rs.radius(16)),
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
                  radius: rs.dimension(20),
                  backgroundColor: AppColors.background,
                  backgroundImage: p.imagePath.trim().isNotEmpty
                      ? safeImageProvider(p.imagePath)
                      : null,
                  child: p.imagePath.trim().isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: rs.icon(24),
                          color: AppColors.primary,
                        )
                      : null,
                ),
                rs.gapW(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppThemeTokens.textPrimary(context),
                        ),
                      ),
                      Text(
                        'Professional ${p.role}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppThemeTokens.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.isVerified)
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.primary,
                    size: rs.icon(18),
                  ),
              ],
            ),
            rs.gapH(12),
            Container(
              padding: EdgeInsets.symmetric(vertical: rs.space(8)),
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(rs.radius(10)),
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
                  rs.gapW(4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: rs.icon(12),
                    color: widget.accentColor,
                  ),
                ],
              ),
            ),
          ],
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
    final rs = context.rs;
    const accentColor = AppColors.primary;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppThemeTokens.surface(context),
        border: Border(
          top: BorderSide(color: AppThemeTokens.outline(context)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        rs.space(10),
        rs.space(8),
        rs.space(10),
        math.max(rs.space(10), bottomInset + rs.space(6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ComposerAction(
            icon: Icons.add_circle_outline_rounded,
            onTap: onPickImage,
          ),
          rs.gapW(8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppThemeTokens.mutedSurface(context),
                borderRadius: BorderRadius.circular(rs.radius(24)),
              ),
              padding: EdgeInsets.symmetric(horizontal: rs.space(16)),
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(fontSize: rs.text(15)),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: rs.space(10)),
                ),
              ),
            ),
          ),
          rs.gapW(8),
          PressableScale(
            onTap: onSend,
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(rs.radius(24)),
              child: Container(
                width: rs.dimension(44),
                height: rs.dimension(44),
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
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: rs.icon(20),
                ),
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
    final rs = context.rs;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(rs.radius(24)),
        child: Container(
          width: rs.dimension(44),
          height: rs.dimension(44),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppThemeTokens.textSecondary(context),
            size: rs.icon(24),
          ),
        ),
      ),
    );
  }
}
