import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
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

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  static void setBackendToken(String token) {
    _repository.setBearerToken(token);
  }

  static Future<void> refresh() async {
    loading.value = true;
    try {
      final loaded = await _repository.loadFinderRequests();
      posts.value = loaded;
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
    required String fallbackClientName,
  }) async {
    final created = await _repository.createFinderRequest(
      category: category,
      service: service,
      location: location,
      message: message,
      preferredDate: preferredDate,
      fallbackClientName: fallbackClientName,
    );
    posts.value = <FinderPostItem>[
      created,
      ...posts.value.where((item) => item.id != created.id),
    ];
  }
}
