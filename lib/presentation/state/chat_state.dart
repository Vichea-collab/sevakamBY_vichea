import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../data/network/backend_api_client.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/profile_settings.dart';
import 'app_role_state.dart';
import 'profile_settings_state.dart';

class ChatState {
  static const int _pageSize = 10;
  static const String _outboxStorageKey = 'chat_outbox_v1';
  static const Duration _outboxFlushInterval = Duration(seconds: 8);
  static const Duration _unreadSyncInterval = Duration(seconds: 6);

  static final BackendApiClient _apiClient = BackendApiClient(
    baseUrl: AppEnv.apiBaseUrl(),
    bearerToken: AppEnv.apiAuthToken(),
  );

  static final ValueNotifier<List<ChatThread>> threads = ValueNotifier(
    const <ChatThread>[],
  );
  static final ValueNotifier<PaginationMeta> threadPagination = ValueNotifier(
    const PaginationMeta.initial(limit: _pageSize),
  );
  static final ValueNotifier<bool> loading = ValueNotifier(false);
  static final ValueNotifier<bool> realtimeActive = ValueNotifier(false);
  static final ValueNotifier<int> unreadCount = ValueNotifier(0);
  static final ValueNotifier<int> pendingOutboxCount = ValueNotifier(0);

  static final List<_QueuedOutgoingMessage> _outbox =
      <_QueuedOutgoingMessage>[];
  static bool _outboxLoaded = false;
  static bool _flushingOutbox = false;
  static Timer? _outboxFlushTimer;
  static Timer? _unreadSyncTimer;
  static final Set<String> _pendingReadThreadIds = <String>{};

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _restoreOutbox();
    _startOutboxFlushTimer();
    _startUnreadSyncTimer();
    await refresh();
    await refreshUnreadCount();
    unawaited(flushQueuedMessages());
  }

  static void setBackendToken(String token) {
    _apiClient.setBearerToken(token);
    if (token.trim().isEmpty) {
      _unreadSyncTimer?.cancel();
      _unreadSyncTimer = null;
      threads.value = const <ChatThread>[];
      threadPagination.value = const PaginationMeta.initial(limit: _pageSize);
      realtimeActive.value = false;
      unreadCount.value = 0;
      return;
    }
    _startUnreadSyncTimer();
    unawaited(refresh(page: 1));
    unawaited(refreshUnreadCount());
    unawaited(flushQueuedMessages());
  }

  static Future<void> refresh({int? page, int limit = _pageSize}) async {
    final targetPage = _normalizedPage(page ?? threadPagination.value.page);
    loading.value = true;
    try {
      if (!FirebaseBootstrap.isConfigured || _apiClient.bearerToken.isEmpty) {
        threads.value = const <ChatThread>[];
        threadPagination.value = PaginationMeta(
          page: targetPage,
          limit: limit,
          totalItems: 0,
          totalPages: 0,
          hasPrevPage: false,
          hasNextPage: false,
        );
        realtimeActive.value = false;
        return;
      }
      final result = await _loadThreadsFromApi(page: targetPage, limit: limit);
      threads.value = _applyPendingReadMask(result.items);
      threadPagination.value = result.pagination;
      realtimeActive.value = false;
      unawaited(refreshUnreadCount());
    } catch (_) {
      threads.value = const <ChatThread>[];
      threadPagination.value = PaginationMeta(
        page: targetPage,
        limit: limit,
        totalItems: 0,
        totalPages: 0,
        hasPrevPage: false,
        hasNextPage: false,
      );
      realtimeActive.value = false;
    } finally {
      loading.value = false;
    }
  }

  static Future<void> refreshUnreadCount() async {
    if (_apiClient.bearerToken.trim().isEmpty) {
      unreadCount.value = 0;
      return;
    }
    if (_pendingReadThreadIds.isNotEmpty) {
      return;
    }
    try {
      final response = await _apiClient.getJson('/api/chats/unread-count');
      final row = _safeMap(response['data']);
      final raw = row['unreadCount'];
      final next = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
      unreadCount.value = next < 0 ? 0 : next;
    } catch (_) {
      // Keep current unread count when request fails.
    }
  }

  static Future<ChatThread> openDirectThread({
    required String peerUid,
    required String peerName,
    required bool peerIsProvider,
  }) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      throw StateError('Please sign in first.');
    }

    final selfUid = current.uid.trim();
    final otherUid = peerUid.trim();
    if (selfUid.isEmpty || otherUid.isEmpty) {
      throw StateError('Invalid chat participant.');
    }

    final response = await _apiClient.postJson('/api/chats/direct', {
      'peerUid': otherUid,
      'peerName': peerName.trim(),
      'peerIsProvider': peerIsProvider,
      'selfRole': AppRoleState.isProvider ? 'provider' : 'finder',
      'selfName': _safeName(
        ProfileSettingsState.currentProfile,
        fallback: current.displayName,
      ),
      'starterText': _starterText(
        peerName: peerName,
        peerIsProvider: peerIsProvider,
      ),
    });

    final row = _safeMap(response['data']);
    final id = (row['id'] ?? '').toString().trim();
    if (id.isEmpty) {
      throw StateError('Chat could not be created.');
    }

    final thread = _threadFromMap(id, row, selfUid);
    final existed = threads.value.any((item) => item.id == thread.id);
    final updated = <ChatThread>[
      thread,
      ...threads.value.where((item) => item.id != thread.id),
    ];
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final limit = threadPagination.value.limit <= 0
        ? _pageSize
        : threadPagination.value.limit;
    if (_normalizedPage(threadPagination.value.page) == 1) {
      final nextThreads = updated.take(limit).toList(growable: false);
      threads.value = nextThreads;
    }
    if (!existed) {
      final totalItems = threadPagination.value.totalItems + 1;
      final totalPages = totalItems == 0
          ? 0
          : ((totalItems + limit - 1) ~/ limit);
      threadPagination.value = PaginationMeta(
        page: _normalizedPage(threadPagination.value.page),
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasPrevPage: threadPagination.value.page > 1,
        hasNextPage: totalPages > 0 && threadPagination.value.page < totalPages,
      );
    }
    return thread;
  }

  static Future<PaginatedResult<ChatMessage>> fetchMessagesPage(
    String threadId, {
    int page = 1,
    int limit = _pageSize,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final id = threadId.trim();
    if (uid.isEmpty || id.isEmpty || _apiClient.bearerToken.isEmpty) {
      const empty = PaginationMeta.initial(limit: _pageSize);
      return const PaginatedResult(items: <ChatMessage>[], pagination: empty);
    }
    final result = await _loadMessagesFromApi(
      id,
      uid,
      page: _normalizedPage(page),
      limit: limit,
    );
    return result;
  }

  static Future<ChatThread?> fetchThreadById(String threadId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final id = threadId.trim();
    if (uid.isEmpty || id.isEmpty || _apiClient.bearerToken.isEmpty) {
      return null;
    }
    final response = await _apiClient.getJson('/api/chats/$id');
    final row = _safeMap(response['data']);
    final resolvedId = (row['id'] ?? id).toString().trim();
    if (resolvedId.isEmpty) {
      return null;
    }
    return _threadFromMap(resolvedId, row, uid);
  }

  static Future<void> acknowledgeDelivered(
    String threadId, {
    List<String> messageIds = const <String>[],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final id = threadId.trim();
    if (uid.isEmpty || id.isEmpty || _apiClient.bearerToken.isEmpty) {
      return;
    }
    final payload = <String, dynamic>{};
    if (messageIds.isNotEmpty) {
      payload['messageIds'] = messageIds
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    await _apiClient.putJson('/api/chats/$id/delivered', payload);
  }

  static Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    String clientMessageId = '',
  }) async {
    final message = text.trim();
    if (message.isEmpty) {
      throw StateError('Message cannot be empty.');
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      throw StateError('Please sign in first.');
    }

    try {
      final sent = await _postMessage(
        threadId: threadId,
        body: <String, dynamic>{
          'text': message,
          'senderName': _safeName(
            ProfileSettingsState.currentProfile,
            fallback: current.displayName,
          ),
        },
        currentUid: current.uid.trim(),
      );
      unawaited(refresh());
      return sent;
    } catch (error) {
      if (_isRetryableSendError(error)) {
        await _queueMessage(
          _QueuedOutgoingMessage.text(
            localId: clientMessageId.trim().isEmpty
                ? 'local_${DateTime.now().microsecondsSinceEpoch}'
                : clientMessageId.trim(),
            threadId: threadId.trim(),
            text: message,
          ),
        );
        throw const ChatQueuedException();
      }
      rethrow;
    }
  }

  static Future<ChatMessage> sendImageMessage({
    required String threadId,
    required Uint8List bytes,
    required String fileName,
    String clientMessageId = '',
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Image is empty.');
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      throw StateError('Please sign in first.');
    }

    final extension = _extensionFromName(fileName);
    final mimeType = _mimeTypeFromExtension(extension);
    final safeFileName = fileName.trim().isEmpty
        ? 'chat_image$extension'
        : fileName.trim();
    final base64Data = base64Encode(bytes);
    final dataUrl = 'data:$mimeType;base64,$base64Data';

    try {
      final sent = await _postMessage(
        threadId: threadId,
        body: <String, dynamic>{
          'text': '',
          'type': 'image',
          'imageDataUrl': dataUrl,
          'fileName': safeFileName,
          'mimeType': mimeType,
          'senderName': _safeName(
            ProfileSettingsState.currentProfile,
            fallback: current.displayName,
          ),
        },
        currentUid: current.uid.trim(),
        timeout: const Duration(seconds: 25),
      );
      unawaited(refresh());
      return sent;
    } catch (error) {
      if (_isRetryableSendError(error)) {
        await _queueMessage(
          _QueuedOutgoingMessage.image(
            localId: clientMessageId.trim().isEmpty
                ? 'local_${DateTime.now().microsecondsSinceEpoch}'
                : clientMessageId.trim(),
            threadId: threadId.trim(),
            imageDataUrl: dataUrl,
            fileName: safeFileName,
            mimeType: mimeType,
          ),
        );
        throw const ChatQueuedException();
      }
      rethrow;
    }
  }

  static Future<void> markThreadAsRead(String threadId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final id = threadId.trim();
    if (uid.isEmpty || id.isEmpty || _apiClient.bearerToken.isEmpty) {
      return;
    }
    _pendingReadThreadIds.add(id);
    _markThreadReadLocallySafely(id);
    try {
      await _apiClient.putJson(
        '/api/chats/$id/read',
        const <String, dynamic>{},
      );
    } catch (_) {
      // Keep local seen state; next sync will reconcile.
    } finally {
      _pendingReadThreadIds.remove(id);
      unawaited(refreshUnreadCount());
    }
  }

  static Future<void> flushQueuedMessages({String threadId = ''}) async {
    if (!_outboxLoaded || _flushingOutbox) return;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty || _apiClient.bearerToken.trim().isEmpty) return;
    _flushingOutbox = true;
    try {
      final targetThread = threadId.trim();
      final snapshot = List<_QueuedOutgoingMessage>.from(_outbox);
      var changed = false;
      var sentCount = 0;
      for (final queued in snapshot) {
        if (targetThread.isNotEmpty && queued.threadId != targetThread) {
          continue;
        }
        final payload = queued.toPayload();
        try {
          await _postMessage(
            threadId: queued.threadId,
            body: payload,
            currentUid: uid,
            timeout: const Duration(seconds: 25),
          );
          _outbox.removeWhere((item) => item.localId == queued.localId);
          changed = true;
          sentCount += 1;
        } catch (error) {
          if (_isRetryableSendError(error)) {
            final index = _outbox.indexWhere(
              (item) => item.localId == queued.localId,
            );
            if (index >= 0) {
              _outbox[index] = _outbox[index].copyWith(
                retries: _outbox[index].retries + 1,
                lastAttemptAtMs: DateTime.now().millisecondsSinceEpoch,
              );
              changed = true;
            }
            continue;
          }
          _outbox.removeWhere((item) => item.localId == queued.localId);
          changed = true;
        }
      }
      if (changed) {
        await _persistOutbox();
      }
      if (sentCount > 0) {
        unawaited(refresh(page: 1));
        unawaited(refreshUnreadCount());
      }
    } finally {
      _flushingOutbox = false;
    }
  }

  static Future<PaginatedResult<ChatThread>> _loadThreadsFromApi({
    required int page,
    required int limit,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      final pagination = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: 0,
        totalPages: 0,
        hasPrevPage: false,
        hasNextPage: false,
      );
      return PaginatedResult(
        items: const <ChatThread>[],
        pagination: pagination,
      );
    }

    final response = await _apiClient.getJson(
      '/api/chats?page=$page&limit=$limit',
    );
    final data = response['data'];
    if (data is! List) {
      final pagination = PaginationMeta.fromMap(
        _safeMap(response['pagination']),
        fallbackPage: page,
        fallbackLimit: limit,
        fallbackTotalItems: 0,
      );
      return PaginatedResult(
        items: const <ChatThread>[],
        pagination: pagination,
      );
    }

    final mapped =
        data
            .whereType<Map>()
            .map(_safeMap)
            .map((row) {
              final id = (row['id'] ?? '').toString().trim();
              if (id.isEmpty) return null;
              return _threadFromMap(id, row, uid);
            })
            .whereType<ChatThread>()
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final pagination = PaginationMeta.fromMap(
      _safeMap(response['pagination']),
      fallbackPage: page,
      fallbackLimit: limit,
      fallbackTotalItems: mapped.length,
    );
    return PaginatedResult(items: mapped, pagination: pagination);
  }

  static Future<PaginatedResult<ChatMessage>> _loadMessagesFromApi(
    String threadId,
    String currentUid, {
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.getJson(
      '/api/chats/$threadId/messages?page=$page&limit=$limit',
    );
    final data = response['data'];
    if (data is! List) {
      final pagination = PaginationMeta.fromMap(
        _safeMap(response['pagination']),
        fallbackPage: page,
        fallbackLimit: limit,
        fallbackTotalItems: 0,
      );
      return PaginatedResult(
        items: const <ChatMessage>[],
        pagination: pagination,
      );
    }

    final mapped =
        data
            .whereType<Map>()
            .map(_safeMap)
            .map((row) => _messageFromRow(row, currentUid))
            .toList(growable: false)
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    final incomingIds = mapped
        .where((message) => !message.fromMe)
        .map((message) => message.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (incomingIds.isNotEmpty) {
      unawaited(acknowledgeDelivered(threadId, messageIds: incomingIds));
    }

    final pagination = PaginationMeta.fromMap(
      _safeMap(response['pagination']),
      fallbackPage: page,
      fallbackLimit: limit,
      fallbackTotalItems: mapped.length,
    );
    return PaginatedResult(items: mapped, pagination: pagination);
  }

  static ChatThread _threadFromMap(
    String id,
    Map<String, dynamic> row,
    String currentUid,
  ) {
    final rawFallbackSubtitle = (row['lastMessageText'] ?? '')
        .toString()
        .trim();
    final lastSenderUid = (row['lastSenderUid'] ?? '').toString().trim();
    final fallbackSubtitle =
        lastSenderUid.isNotEmpty &&
            lastSenderUid == currentUid &&
            rawFallbackSubtitle.isNotEmpty
        ? 'You: $rawFallbackSubtitle'
        : rawFallbackSubtitle;
    final fallbackTitle = _fallbackPeerName(row, currentUid);
    final title = (row['title'] ?? '').toString().trim();
    final subtitle = (row['subtitle'] ?? '').toString().trim();

    final unreadCount = _unreadCount(row, currentUid);
    final updatedAt = _toDateTime(
      row['updatedAt'] ?? row['lastMessageAt'] ?? row['createdAt'],
    );

    return ChatThread(
      id: id,
      title: title.isEmpty ? fallbackTitle : title,
      subtitle: subtitle.isEmpty
          ? (fallbackSubtitle.isEmpty ? 'Start conversation' : fallbackSubtitle)
          : subtitle,
      avatarPath: _safeAvatarPath(),
      updatedAt: updatedAt,
      unreadCount: unreadCount,
      messages: const <ChatMessage>[],
    );
  }

  static String _fallbackPeerName(Map<String, dynamic> row, String currentUid) {
    final participantMetaRaw = row['participantMeta'];
    if (participantMetaRaw is Map) {
      final participants = (row['participants'] is List)
          ? (row['participants'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];
      final peerUid = participants.firstWhere(
        (uid) => uid != currentUid,
        orElse: () => '',
      );
      if (peerUid.isNotEmpty) {
        final raw = participantMetaRaw[peerUid];
        if (raw is Map) {
          final name = (raw['name'] ?? '').toString().trim();
          if (name.isNotEmpty) return name;
        }
      }
    }

    final peerName = (row['peerName'] ?? '').toString().trim();
    if (peerName.isNotEmpty) return peerName;
    return 'Chat';
  }

  static int _unreadCount(Map<String, dynamic> row, String currentUid) {
    final direct = row['unreadCount'];
    if (direct is num) return direct.toInt();
    if (direct is String) return int.tryParse(direct) ?? 0;

    final unreadRaw = row['unreadCounts'];
    if (unreadRaw is Map) {
      final value = unreadRaw[currentUid];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    }
    return DateTime.now();
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  static String _safeName(ProfileFormData profile, {String? fallback}) {
    final name = profile.name.trim();
    if (name.isNotEmpty) return name;
    final alt = (fallback ?? '').trim();
    if (alt.isNotEmpty) return alt;
    return AppRoleState.isProvider ? 'Service Provider' : 'Service Finder';
  }

  static String _safeAvatarPath() => 'assets/images/profile.jpg';

  static int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }

  static ChatMessageType _messageTypeFromStorage(
    String raw, {
    required String imageUrl,
  }) {
    final value = raw.trim().toLowerCase();
    if (value == 'image') return ChatMessageType.image;
    if (imageUrl.trim().isNotEmpty) return ChatMessageType.image;
    return ChatMessageType.text;
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

  static String _starterText({
    required String peerName,
    required bool peerIsProvider,
  }) {
    final peer = peerName.trim().isEmpty ? 'there' : peerName.trim();
    if (peerIsProvider) {
      return 'Hi $peer, I want to discuss your service.';
    }
    return 'Hi $peer, I can help with your request.';
  }

  static ChatMessage _messageFromRow(
    Map<String, dynamic> row,
    String currentUid,
  ) {
    final senderUid = (row['senderUid'] ?? '').toString().trim();
    final imageUrl = (row['imageUrl'] ?? '').toString().trim();
    final seenBy = _safeStringList(row['seenBy']);
    final deliveredTo = _safeStringList(row['deliveredTo']);
    final sentAt = _toDateTime(row['sentAt']);
    final id = (row['id'] ?? '').toString().trim();
    return ChatMessage(
      id: id.isEmpty ? '${senderUid}_${sentAt.millisecondsSinceEpoch}' : id,
      text: (row['text'] ?? '').toString(),
      type: _messageTypeFromStorage(
        (row['type'] ?? '').toString(),
        imageUrl: imageUrl,
      ),
      imageUrl: imageUrl,
      fromMe: senderUid == currentUid,
      sentAt: sentAt,
      deliveryStatus: _deliveryStatusForMessage(
        senderUid: senderUid,
        currentUid: currentUid,
        seenBy: seenBy,
        deliveredTo: deliveredTo,
      ),
    );
  }

  static ChatDeliveryStatus _deliveryStatusForMessage({
    required String senderUid,
    required String currentUid,
    required List<String> seenBy,
    required List<String> deliveredTo,
  }) {
    if (senderUid != currentUid) {
      return ChatDeliveryStatus.seen;
    }
    final peerSeen = seenBy.any((uid) => uid.isNotEmpty && uid != senderUid);
    if (peerSeen) return ChatDeliveryStatus.seen;
    final peerDelivered = deliveredTo.any(
      (uid) => uid.isNotEmpty && uid != senderUid,
    );
    if (peerDelivered) return ChatDeliveryStatus.delivered;
    return ChatDeliveryStatus.sent;
  }

  static List<String> _safeStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static Future<ChatMessage> _postMessage({
    required String threadId,
    required Map<String, dynamic> body,
    required String currentUid,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final response = await _apiClient.postJson(
      '/api/chats/${threadId.trim()}/messages',
      body,
      timeout: timeout,
    );
    return _messageFromRow(_safeMap(response['data']), currentUid);
  }

  static bool _isRetryableSendError(Object error) {
    if (error is TimeoutException) return true;
    if (error is BackendApiException) {
      final status = error.statusCode ?? 0;
      if (status == 0 || status == 408 || status == 429) {
        return true;
      }
      return status >= 500;
    }
    final lower = error.toString().toLowerCase();
    return lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout');
  }

  static Future<void> _queueMessage(_QueuedOutgoingMessage queued) async {
    await _restoreOutbox();
    final exists = _outbox.any((item) => item.localId == queued.localId);
    if (exists) return;
    _outbox.add(queued);
    _outbox.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    await _persistOutbox();
    unawaited(flushQueuedMessages(threadId: queued.threadId));
  }

  static void _startOutboxFlushTimer() {
    _outboxFlushTimer?.cancel();
    _outboxFlushTimer = Timer.periodic(_outboxFlushInterval, (_) {
      unawaited(flushQueuedMessages());
    });
  }

  static void _startUnreadSyncTimer() {
    _unreadSyncTimer?.cancel();
    _unreadSyncTimer = Timer.periodic(_unreadSyncInterval, (_) {
      if (_apiClient.bearerToken.trim().isEmpty) return;
      unawaited(refreshUnreadCount());
    });
  }

  static Future<void> _restoreOutbox() async {
    if (_outboxLoaded) return;
    _outboxLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_outboxStorageKey) ?? '';
      if (raw.trim().isEmpty) {
        pendingOutboxCount.value = 0;
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        pendingOutboxCount.value = 0;
        return;
      }
      _outbox
        ..clear()
        ..addAll(
          decoded
              .whereType<Map>()
              .map(
                (item) => _QueuedOutgoingMessage.fromMap(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .whereType<_QueuedOutgoingMessage>(),
        );
      _outbox.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    } catch (_) {
      _outbox.clear();
    }
    pendingOutboxCount.value = _outbox.length;
  }

  static Future<void> _persistOutbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _outbox
          .map((item) => item.toMap())
          .toList(growable: false);
      await prefs.setString(_outboxStorageKey, jsonEncode(payload));
    } catch (_) {
      // Keep in-memory outbox as fallback.
    }
    pendingOutboxCount.value = _outbox.length;
  }

  static bool isQueuedLocalMessageId(String value) {
    final id = value.trim();
    if (id.isEmpty) return false;
    return _outbox.any((item) => item.localId == id);
  }

  static void _markThreadReadLocally(String threadId) {
    final current = threads.value;
    var unreadInThread = 0;
    for (final thread in current) {
      if (thread.id == threadId) {
        unreadInThread = thread.unreadCount;
        break;
      }
    }
    final updated = threads.value
        .map(
          (thread) => thread.id == threadId
              ? ChatThread(
                  id: thread.id,
                  title: thread.title,
                  subtitle: thread.subtitle,
                  avatarPath: thread.avatarPath,
                  updatedAt: thread.updatedAt,
                  unreadCount: 0,
                  messages: thread.messages,
                )
              : thread,
        )
        .toList(growable: false);
    threads.value = updated;
    if (unreadInThread > 0) {
      final next = unreadCount.value - unreadInThread;
      unreadCount.value = next < 0 ? 0 : next;
    }
  }

  static List<ChatThread> _applyPendingReadMask(List<ChatThread> source) {
    if (_pendingReadThreadIds.isEmpty || source.isEmpty) return source;
    return source
        .map(
          (thread) => _pendingReadThreadIds.contains(thread.id)
              ? ChatThread(
                  id: thread.id,
                  title: thread.title,
                  subtitle: thread.subtitle,
                  avatarPath: thread.avatarPath,
                  updatedAt: thread.updatedAt,
                  unreadCount: 0,
                  messages: thread.messages,
                )
              : thread,
        )
        .toList(growable: false);
  }

  static void _markThreadReadLocallySafely(String threadId) {
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    final isDuringFrameBuild =
        schedulerPhase == SchedulerPhase.transientCallbacks ||
        schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
        schedulerPhase == SchedulerPhase.persistentCallbacks;
    if (!isDuringFrameBuild) {
      _markThreadReadLocally(threadId);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markThreadReadLocally(threadId);
    });
  }
}

class ChatQueuedException implements Exception {
  final String message;

  const ChatQueuedException([
    this.message =
        'Message queued and will send automatically when connection returns.',
  ]);

  @override
  String toString() => message;
}

class _QueuedOutgoingMessage {
  final String localId;
  final String threadId;
  final String type;
  final String text;
  final String imageDataUrl;
  final String fileName;
  final String mimeType;
  final int createdAtMs;
  final int lastAttemptAtMs;
  final int retries;

  const _QueuedOutgoingMessage({
    required this.localId,
    required this.threadId,
    required this.type,
    required this.text,
    required this.imageDataUrl,
    required this.fileName,
    required this.mimeType,
    required this.createdAtMs,
    required this.lastAttemptAtMs,
    required this.retries,
  });

  factory _QueuedOutgoingMessage.text({
    required String localId,
    required String threadId,
    required String text,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _QueuedOutgoingMessage(
      localId: localId,
      threadId: threadId,
      type: 'text',
      text: text,
      imageDataUrl: '',
      fileName: '',
      mimeType: '',
      createdAtMs: now,
      lastAttemptAtMs: 0,
      retries: 0,
    );
  }

  factory _QueuedOutgoingMessage.image({
    required String localId,
    required String threadId,
    required String imageDataUrl,
    required String fileName,
    required String mimeType,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _QueuedOutgoingMessage(
      localId: localId,
      threadId: threadId,
      type: 'image',
      text: '',
      imageDataUrl: imageDataUrl,
      fileName: fileName,
      mimeType: mimeType,
      createdAtMs: now,
      lastAttemptAtMs: 0,
      retries: 0,
    );
  }

  static _QueuedOutgoingMessage? fromMap(Map<String, dynamic> row) {
    final localId = (row['localId'] ?? '').toString().trim();
    final threadId = (row['threadId'] ?? '').toString().trim();
    final type = (row['type'] ?? 'text').toString().trim().toLowerCase();
    if (localId.isEmpty || threadId.isEmpty) {
      return null;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return _QueuedOutgoingMessage(
      localId: localId,
      threadId: threadId,
      type: type == 'image' ? 'image' : 'text',
      text: (row['text'] ?? '').toString(),
      imageDataUrl: (row['imageDataUrl'] ?? '').toString(),
      fileName: (row['fileName'] ?? '').toString(),
      mimeType: (row['mimeType'] ?? '').toString(),
      createdAtMs: (row['createdAtMs'] as num?)?.toInt() ?? now,
      lastAttemptAtMs: (row['lastAttemptAtMs'] as num?)?.toInt() ?? 0,
      retries: (row['retries'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'localId': localId,
      'threadId': threadId,
      'type': type,
      'text': text,
      'imageDataUrl': imageDataUrl,
      'fileName': fileName,
      'mimeType': mimeType,
      'createdAtMs': createdAtMs,
      'lastAttemptAtMs': lastAttemptAtMs,
      'retries': retries,
    };
  }

  _QueuedOutgoingMessage copyWith({int? lastAttemptAtMs, int? retries}) {
    return _QueuedOutgoingMessage(
      localId: localId,
      threadId: threadId,
      type: type,
      text: text,
      imageDataUrl: imageDataUrl,
      fileName: fileName,
      mimeType: mimeType,
      createdAtMs: createdAtMs,
      lastAttemptAtMs: lastAttemptAtMs ?? this.lastAttemptAtMs,
      retries: retries ?? this.retries,
    );
  }

  Map<String, dynamic> toPayload() {
    if (type == 'image') {
      return <String, dynamic>{
        'text': '',
        'type': 'image',
        'imageDataUrl': imageDataUrl,
        'fileName': fileName,
        'mimeType': mimeType,
      };
    }
    return <String, dynamic>{'text': text};
  }
}
