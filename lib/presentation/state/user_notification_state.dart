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
  final String promoCode;
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
    this.promoCode = '',
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
      promoCode: (row['promoCode'] ?? '').toString(),
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

  static Future<bool>? _tokenRefreshInFlight;

  static void setBackendToken(String token) {
    _apiClient.setBearerToken(token);
    if (token.trim().isEmpty) {
      notices.value = const <UserNotificationItem>[];
      pagination.value = const PaginationMeta.initial(limit: _pageSize);
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

      final role = AppRoleState.isProvider ? 'provider' : 'finder';
      final result = await _runWithAuthRetry(() {
        return _apiClient.getJson(
          '/api/users/notifications?page=$targetPage&limit=$limit&type=$type&role=$role',
        );
      });
      final dataRows = _safeList(result['data']);
      notices.value = dataRows
          .map(UserNotificationItem.fromMap)
          .toList(growable: false);
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
