import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../data/network/backend_api_client.dart';
import '../../domain/entities/pagination.dart';
import 'app_role_state.dart';

enum UserNotificationType { system, promotion }

class UserNotificationItem {
  final String id;
  final UserNotificationType type;
  final String source;
  final String orderId;
  final String orderStatus;
  final String title;
  final String message;
  final String lifecycle;
  final DateTime? createdAt;
  final DateTime? startAt;
  final DateTime? endAt;

  const UserNotificationItem({
    required this.id,
    required this.type,
    this.source = '',
    this.orderId = '',
    this.orderStatus = '',
    required this.title,
    required this.message,
    this.lifecycle = 'active',
    this.createdAt,
    this.startAt,
    this.endAt,
  });

  bool get isPromo => type == UserNotificationType.promotion;

  bool get isActive => lifecycle == 'active';

  static UserNotificationItem fromMap(Map<String, dynamic> row) {
    final typeRaw = (row['type'] ?? '').toString().trim().toLowerCase();
    final type = typeRaw == 'promotion' || typeRaw == 'promo'
        ? UserNotificationType.promotion
        : UserNotificationType.system;
    return UserNotificationItem(
      id: (row['id'] ?? '').toString(),
      type: type,
      source: (row['source'] ?? '').toString().trim().toLowerCase(),
      orderId: (row['orderId'] ?? '').toString(),
      orderStatus: (row['orderStatus'] ?? '').toString().trim().toLowerCase(),
      title: (row['title'] ?? 'Platform update').toString(),
      message: (row['message'] ?? '').toString(),
      lifecycle: (row['lifecycle'] ?? 'active').toString().trim().toLowerCase(),
      createdAt: _toDateTime(row['createdAt']),
      startAt: _toDateTime(row['startAt']),
      endAt: _toDateTime(row['endAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed;
    }
    return null;
  }
}

class UserNotificationState {
  static const int _pageSize = 10;
  static const int _maxReadStateKeys = 2000;

  static final BackendApiClient _apiClient = BackendApiClient(
    baseUrl: AppEnv.apiBaseUrl(),
    bearerToken: AppEnv.apiAuthToken(),
  );

  static final ValueNotifier<List<UserNotificationItem>> notices =
      ValueNotifier(const <UserNotificationItem>[]);

  static final ValueNotifier<PaginationMeta> pagination = ValueNotifier(
    const PaginationMeta.initial(limit: _pageSize),
  );

  static final ValueNotifier<bool> loading = ValueNotifier(false);
  static final ValueNotifier<int> readStateVersion = ValueNotifier(0);

  static Future<bool>? _tokenRefreshInFlight;
  static final Set<String> _readKeys = <String>{};
  static final Set<String> _clearedKeys = <String>{};
  static bool _readStateHydrated = false;
  static bool _readStateHydrating = false;
  static Timer? _readStatePersistTimer;

  static void setBackendToken(String token) {
    _apiClient.setBearerToken(token);
    if (token.trim().isEmpty) {
      notices.value = const <UserNotificationItem>[];
      pagination.value = const PaginationMeta.initial(limit: _pageSize);
      _readKeys.clear();
      _clearedKeys.clear();
      _readStateHydrated = false;
      _readStateHydrating = false;
      _readStatePersistTimer?.cancel();
      readStateVersion.value += 1;
      return;
    }
    unawaited(refresh());
  }

  static Future<void> refresh({
    int page = 1,
    int limit = _pageSize,
    String type = 'all',
  }) async {
    final targetPage = page <= 0 ? 1 : page;
    loading.value = true;
    try {
      final ready = await _ensureBackendToken();
      if (!ready) {
        notices.value = const <UserNotificationItem>[];
        pagination.value = PaginationMeta(
          page: targetPage,
          limit: limit,
          totalItems: 0,
          totalPages: 0,
          hasPrevPage: false,
          hasNextPage: false,
        );
        return;
      }
      await _ensureReadStateHydrated();

      final role = AppRoleState.isProvider ? 'provider' : 'finder';
      final result = await _runWithAuthRetry(() {
        return _apiClient.getJson(
          '/api/users/notifications?page=$targetPage&limit=$limit&type=$type&role=$role',
        );
      });
      final dataRows = _safeList(result['data']);
      final mapped = dataRows
          .map(UserNotificationItem.fromMap)
          .toList(growable: false);
      mapped.sort((a, b) {
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final byTime = right.compareTo(left);
        if (byTime != 0) return byTime;
        return a.id.compareTo(b.id);
      });
      notices.value = mapped;
      pagination.value = PaginationMeta.fromMap(
        _safeMap(result['pagination']),
        fallbackPage: targetPage,
        fallbackLimit: limit,
        fallbackTotalItems: dataRows.length,
      );
    } catch (_) {
      notices.value = const <UserNotificationItem>[];
      pagination.value = PaginationMeta(
        page: targetPage,
        limit: limit,
        totalItems: 0,
        totalPages: 0,
        hasPrevPage: false,
        hasNextPage: false,
      );
    } finally {
      loading.value = false;
    }
  }

  static Future<void> refreshUnreadStatus() async {
    try {
      final ready = await _ensureBackendToken();
      if (!ready) return;

      // Forces re-fetching the read/cleared keys from backend
      // and checking for any unread counts if the backend supports it.
      // Since the backend might not have a dedicated fast-poll unread endpoint yet,
      // we'll fetch the first page minimally to see if there are new items.
      final role = AppRoleState.isProvider ? 'provider' : 'finder';
      final result = await _runWithAuthRetry(() {
        return _apiClient.getJson(
          '/api/users/notifications?page=1&limit=5&type=all&role=$role',
        );
      });

      final dataRows = _safeList(result['data']);
      if (dataRows.isEmpty) return;

      final newTopId = dataRows.first['id']?.toString() ?? '';

      // If we have a new top item we didn't have before, trigger a full refresh
      final currentTopId = notices.value.isNotEmpty
          ? notices.value.first.id
          : '';
      if (newTopId.isNotEmpty && newTopId != currentTopId) {
        unawaited(refresh());
      }
    } catch (_) {
      // Ignore transient errors on background poll
    }
  }

  static bool isRead(String key) {
    final normalized = _normalizeStateKey(key);
    if (normalized.isEmpty) return false;
    return _readKeys.contains(normalized);
  }

  static bool isCleared(String key) {
    final normalized = _normalizeStateKey(key);
    if (normalized.isEmpty) return false;
    return _clearedKeys.contains(normalized);
  }

  static Future<void> markRead(String key) async {
    await markReadMany(<String>[key]);
  }

  static Future<void> markReadMany(Iterable<String> keys) async {
    var changed = false;
    for (final raw in keys) {
      final normalized = _normalizeStateKey(raw);
      if (normalized.isEmpty) continue;
      changed = _readKeys.add(normalized) || changed;
    }
    if (!changed) return;
    _bumpReadStateVersion();
    _scheduleReadStatePersist();
  }

  static Future<void> clear(String key) async {
    await clearMany(<String>[key]);
  }

  static Future<void> clearMany(Iterable<String> keys) async {
    var changed = false;
    for (final raw in keys) {
      final normalized = _normalizeStateKey(raw);
      if (normalized.isEmpty) continue;
      changed = _clearedKeys.add(normalized) || changed;
      changed = _readKeys.add(normalized) || changed;
    }
    if (!changed) return;
    _bumpReadStateVersion();
    _scheduleReadStatePersist();
  }

  static Future<bool> _ensureBackendToken() async {
    if (_apiClient.bearerToken.isNotEmpty) return true;
    return _refreshBackendToken(force: false);
  }

  static Future<bool> _refreshBackendToken({required bool force}) async {
    if (!force && _apiClient.bearerToken.isNotEmpty) return true;
    final inFlight = _tokenRefreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshBackendTokenInternal(force: force);
    _tokenRefreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_tokenRefreshInFlight, future)) {
        _tokenRefreshInFlight = null;
      }
    }
  }

  static Future<bool> _refreshBackendTokenInternal({
    required bool force,
  }) async {
    if (!FirebaseBootstrap.isConfigured) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final refreshed = (await user.getIdToken(force) ?? '').trim();
      if (refreshed.isEmpty) return false;
      _apiClient.setBearerToken(refreshed);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<T> _runWithAuthRetry<T>(Future<T> Function() task) async {
    try {
      return await task();
    } on BackendApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      final refreshed = await _refreshBackendToken(force: true);
      if (!refreshed) rethrow;
      return task();
    }
  }

  static Future<void> _ensureReadStateHydrated() async {
    if (_readStateHydrated || _readStateHydrating) return;
    _readStateHydrating = true;
    try {
      final result = await _runWithAuthRetry(() {
        return _apiClient.getJson('/api/users/notifications/read-state');
      });
      final row = _safeMap(result['data']);
      _readKeys
        ..clear()
        ..addAll(_normalizedKeyList(row['readKeys']));
      _clearedKeys
        ..clear()
        ..addAll(_normalizedKeyList(row['clearedKeys']));
      _readStateHydrated = true;
      _bumpReadStateVersion();
    } catch (_) {
      _readStateHydrated = false;
    } finally {
      _readStateHydrating = false;
    }
  }

  static void _scheduleReadStatePersist() {
    _readStatePersistTimer?.cancel();
    _readStatePersistTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_persistReadState());
    });
  }

  static Future<void> _persistReadState() async {
    final ready = await _ensureBackendToken();
    if (!ready) return;
    final readKeys = _readKeys.take(_maxReadStateKeys).toList(growable: false);
    final clearedKeys = _clearedKeys
        .take(_maxReadStateKeys)
        .toList(growable: false);
    try {
      await _runWithAuthRetry(() {
        return _apiClient.putJson('/api/users/notifications/read-state', {
          'replace': true,
          'readKeys': readKeys,
          'clearedKeys': clearedKeys,
        });
      });
    } catch (_) {
      // Keep local read state and retry on the next mutation.
    }
  }

  static void _bumpReadStateVersion() {
    readStateVersion.value += 1;
  }

  static List<String> _normalizedKeyList(dynamic value) {
    if (value is! List) return const <String>[];
    final result = <String>{};
    for (final item in value) {
      final normalized = _normalizeStateKey(item.toString());
      if (normalized.isEmpty) continue;
      result.add(normalized);
      if (result.length >= _maxReadStateKeys) break;
    }
    return result.toList(growable: false);
  }

  static String _normalizeStateKey(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return '';
    return normalized;
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _safeList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map>().map((item) => _safeMap(item)).toList();
  }
}
