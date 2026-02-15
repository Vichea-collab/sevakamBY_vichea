import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../data/datasources/remote/finder_post_remote_data_source.dart';
import '../../data/network/backend_api_client.dart';
import '../../data/repositories/finder_post_repository_impl.dart';
import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/finder_post_repository.dart';

class FinderPostState {
  static final FinderPostRepository _repository = FinderPostRepositoryImpl(
    remoteDataSource: FinderPostRemoteDataSource(
      BackendApiClient(
        baseUrl: AppEnv.apiBaseUrl(),
        bearerToken: AppEnv.apiAuthToken(),
      ),
    ),
  );

  static final ValueNotifier<List<FinderPostItem>> posts = ValueNotifier(
    const <FinderPostItem>[],
  );
  static final ValueNotifier<bool> loading = ValueNotifier(false);
  static final ValueNotifier<bool> realtimeActive = ValueNotifier(false);

  static bool _initialized = false;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _postSubscription;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  static void setBackendToken(String token) {
    _repository.setBearerToken(token);
    if (token.trim().isEmpty) {
      unawaited(_stopRealtime());
      posts.value = const <FinderPostItem>[];
      return;
    }
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    loading.value = true;
    try {
      final realtime = await _startRealtimeIfAvailable();
      if (realtime) return;
      await _loadFromBackend();
    } catch (_) {
      posts.value = const <FinderPostItem>[];
    } finally {
      loading.value = false;
    }
  }

  static Future<void> createFinderRequest({
    required String category,
    required String service,
    required String location,
    required String message,
    required DateTime preferredDate,
  }) async {
    final created = await _repository.createFinderRequest(
      category: category,
      service: service,
      location: location,
      message: message,
      preferredDate: preferredDate,
    );
    posts.value = <FinderPostItem>[
      created,
      ...posts.value.where((item) => item.id != created.id),
    ];
  }

  static Future<bool> _startRealtimeIfAvailable() async {
    if (!FirebaseBootstrap.isConfigured) return false;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return false;
    if (_postSubscription != null) {
      realtimeActive.value = true;
      return true;
    }

    _postSubscription = FirebaseFirestore.instance
        .collection('finderPosts')
        .limit(120)
        .snapshots()
        .listen(
          (snapshot) {
            final docs =
                snapshot.docs.where((doc) {
                  final row = doc.data();
                  final status = (row['status'] ?? 'open').toString().trim();
                  return status == 'open';
                }).toList()..sort((a, b) {
                  return _toEpochMillis(b.data()['createdAt']) -
                      _toEpochMillis(a.data()['createdAt']);
                });

            final items = docs.map((doc) {
              final row = Map<String, dynamic>.from(doc.data());
              row['id'] ??= doc.id;
              return _mapRealtimePost(row);
            }).toList();
            posts.value = items;
            realtimeActive.value = true;
          },
          onError: (_) {
            realtimeActive.value = false;
            unawaited(_fallbackToBackendAfterRealtimeError());
          },
        );
    realtimeActive.value = true;
    return true;
  }

  static Future<void> _fallbackToBackendAfterRealtimeError() async {
    await _stopRealtime();
    await _loadFromBackend();
  }

  static Future<void> _loadFromBackend() async {
    try {
      final loaded = await _repository.loadFinderRequests();
      posts.value = loaded;
    } catch (_) {
      posts.value = const <FinderPostItem>[];
    }
  }

  static Future<void> _stopRealtime() async {
    await _postSubscription?.cancel();
    _postSubscription = null;
    realtimeActive.value = false;
  }

  static FinderPostItem _mapRealtimePost(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final createdAt = _parseDate(row['createdAt']);
    return FinderPostItem(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      finderUid: (row['finderUid'] ?? '').toString(),
      clientName: (row['clientName'] ?? 'Finder User').toString(),
      message: (row['message'] ?? '').toString(),
      timeLabel: _timeLabel(createdAt),
      category: (row['category'] ?? '').toString(),
      service: (row['service'] ?? '').toString(),
      location: (row['location'] ?? '').toString(),
      avatarPath: 'assets/images/profile.jpg',
      preferredDate: _parseDate(row['preferredDate']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toLocal();
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    }
    return null;
  }

  static String _timeLabel(DateTime? date) {
    if (date == null) return 'Just now';
    final delta = DateTime.now().difference(date);
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inHours < 1) return '${delta.inMinutes} mins ago';
    if (delta.inDays < 1) return '${delta.inHours} hrs ago';
    return '${delta.inDays} days ago';
  }

  static int _toEpochMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return (seconds * 1000).round();
    }
    return 0;
  }
}
