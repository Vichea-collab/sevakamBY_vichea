import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../data/network/backend_api_client.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/profile_settings.dart';
import 'app_role_state.dart';
import 'profile_settings_state.dart';

class ChatState {
  static final BackendApiClient _apiClient = BackendApiClient(
    baseUrl: AppEnv.apiBaseUrl(),
    bearerToken: AppEnv.apiAuthToken(),
  );

  static final ValueNotifier<List<ChatThread>> threads = ValueNotifier(
    const <ChatThread>[],
  );
  static final ValueNotifier<bool> loading = ValueNotifier(false);
  static final ValueNotifier<bool> realtimeActive = ValueNotifier(false);

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  static void setBackendToken(String token) {
    _apiClient.setBearerToken(token);
    if (token.trim().isEmpty) {
      threads.value = const <ChatThread>[];
      realtimeActive.value = false;
      return;
    }
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    loading.value = true;
    try {
      if (!FirebaseBootstrap.isConfigured || _apiClient.bearerToken.isEmpty) {
        threads.value = const <ChatThread>[];
        realtimeActive.value = false;
        return;
      }
      threads.value = await _loadThreadsFromApi();
      realtimeActive.value = false;
    } catch (_) {
      threads.value = const <ChatThread>[];
      realtimeActive.value = false;
    } finally {
      loading.value = false;
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
    final updated = <ChatThread>[
      thread,
      ...threads.value.where((item) => item.id != thread.id),
    ];
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    threads.value = updated;
    return thread;
  }

  static Stream<List<ChatMessage>> messageStream(String threadId) {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final id = threadId.trim();
    if (uid.isEmpty || id.isEmpty || _apiClient.bearerToken.isEmpty) {
      return Stream<List<ChatMessage>>.value(const <ChatMessage>[]);
    }

    final controller = StreamController<List<ChatMessage>>();
    Timer? pollTimer;
    var emitted = false;

    Future<void> poll() async {
      try {
        final messages = await _loadMessagesFromApi(id, uid);
        if (controller.isClosed) return;
        emitted = true;
        controller.add(messages);
      } catch (_) {
        if (!emitted && !controller.isClosed) {
          controller.add(const <ChatMessage>[]);
        }
      }
    }

    controller.onListen = () {
      unawaited(poll());
      pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => unawaited(poll()),
      );
    };
    controller.onCancel = () async {
      pollTimer?.cancel();
      pollTimer = null;
      await controller.close();
    };

    return controller.stream;
  }

  static Future<void> sendMessage({
    required String threadId,
    required String text,
  }) async {
    final message = text.trim();
    if (message.isEmpty) return;

    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      throw StateError('Please sign in first.');
    }

    await _apiClient.postJson('/api/chats/${threadId.trim()}/messages', {
      'text': message,
      'senderName': _safeName(
        ProfileSettingsState.currentProfile,
        fallback: current.displayName,
      ),
    });

    unawaited(refresh());
  }

  static Future<void> sendImageMessage({
    required String threadId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) return;

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

    await _apiClient.postJson(
      '/api/chats/${threadId.trim()}/messages',
      {
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
      timeout: const Duration(seconds: 25),
    );

    unawaited(refresh());
  }

  static Future<void> markThreadAsRead(String threadId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final id = threadId.trim();
    if (uid.isEmpty || id.isEmpty || _apiClient.bearerToken.isEmpty) {
      return;
    }

    await _apiClient.putJson('/api/chats/$id/read', const <String, dynamic>{});

    final current = threads.value;
    threads.value = current
        .map(
          (thread) => thread.id == id
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

  static Future<List<ChatThread>> _loadThreadsFromApi() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return const <ChatThread>[];

    final response = await _apiClient.getJson('/api/chats');
    final data = response['data'];
    if (data is! List) return const <ChatThread>[];

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

    return mapped;
  }

  static Future<List<ChatMessage>> _loadMessagesFromApi(
    String threadId,
    String currentUid,
  ) async {
    final response = await _apiClient.getJson('/api/chats/$threadId/messages');
    final data = response['data'];
    if (data is! List) return const <ChatMessage>[];

    final mapped =
        data
            .whereType<Map>()
            .map(_safeMap)
            .map(
              (row) => ChatMessage(
                text: (row['text'] ?? '').toString(),
                type: _messageTypeFromStorage(
                  (row['type'] ?? '').toString(),
                  imageUrl: (row['imageUrl'] ?? '').toString(),
                ),
                imageUrl: (row['imageUrl'] ?? '').toString(),
                fromMe:
                    (row['senderUid'] ?? '').toString().trim() == currentUid,
                sentAt: _toDateTime(row['sentAt']),
                seen: true,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    return mapped;
  }

  static ChatThread _threadFromMap(
    String id,
    Map<String, dynamic> row,
    String currentUid,
  ) {
    final fallbackSubtitle = (row['lastMessageText'] ?? '').toString().trim();
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
}
