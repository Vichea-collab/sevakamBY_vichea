import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../data/datasources/remote/provider_post_remote_data_source.dart';
import '../../data/network/backend_api_client.dart';
import '../../data/repositories/provider_post_repository_impl.dart';
import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/provider_post_repository.dart';

class ProviderPostState {
  static final ProviderPostRepository _repository = ProviderPostRepositoryImpl(
    remoteDataSource: ProviderPostRemoteDataSource(
      BackendApiClient(
        baseUrl: AppEnv.apiBaseUrl(),
        bearerToken: AppEnv.apiAuthToken(),
      ),
    ),
  );

  static final ValueNotifier<List<ProviderPostItem>> posts = ValueNotifier(
    const <ProviderPostItem>[],
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
    _repository.setBearerToken(token);
    if (token.trim().isEmpty) {
      posts.value = const <ProviderPostItem>[];
      realtimeActive.value = false;
      return;
    }
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    loading.value = true;
    try {
      posts.value = await _repository.loadProviderPosts();
      realtimeActive.value = false;
    } catch (_) {
      posts.value = const <ProviderPostItem>[];
      realtimeActive.value = false;
    } finally {
      loading.value = false;
    }
  }

  static Future<void> createProviderPost({
    required String category,
    required String service,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  }) async {
    final created = await _repository.createProviderPost(
      category: category,
      service: service,
      area: area,
      details: details,
      ratePerHour: ratePerHour,
      availableNow: availableNow,
    );
    posts.value = <ProviderPostItem>[
      created,
      ...posts.value.where((item) => item.id != created.id),
    ];
  }
}
