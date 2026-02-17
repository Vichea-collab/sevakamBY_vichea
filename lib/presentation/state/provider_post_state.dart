import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../data/datasources/remote/provider_post_remote_data_source.dart';
import '../../data/network/backend_api_client.dart';
import '../../data/repositories/provider_post_repository_impl.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/provider_post_repository.dart';

class ProviderPostState {
  static const int _pageSize = 10;

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
  static final ValueNotifier<List<ProviderPostItem>> allPosts = ValueNotifier(
    const <ProviderPostItem>[],
  );
  static final ValueNotifier<PaginationMeta> pagination = ValueNotifier(
    const PaginationMeta.initial(limit: _pageSize),
  );
  static final ValueNotifier<bool> loading = ValueNotifier(false);
  static final ValueNotifier<bool> allPostsLoading = ValueNotifier(false);
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
      allPosts.value = const <ProviderPostItem>[];
      pagination.value = const PaginationMeta.initial(limit: _pageSize);
      realtimeActive.value = false;
      return;
    }
    unawaited(refresh(page: 1));
    if (allPosts.value.isEmpty) {
      unawaited(refreshAllForLookup(maxPages: 3));
    }
  }

  static Future<void> refresh({int? page, int limit = _pageSize}) async {
    final targetPage = _normalizedPage(page ?? pagination.value.page);
    loading.value = true;
    try {
      final result = await _repository.loadProviderPosts(
        page: targetPage,
        limit: limit,
      );
      posts.value = result.items;
      pagination.value = result.pagination;
      realtimeActive.value = false;
    } catch (_) {
      posts.value = const <ProviderPostItem>[];
      pagination.value = PaginationMeta(
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

  static Future<void> refreshAllForLookup({
    int limit = _pageSize,
    int maxPages = 5,
  }) async {
    allPostsLoading.value = true;
    try {
      final combined = <ProviderPostItem>[];
      var page = 1;
      final safeMaxPages = maxPages < 1 ? 1 : maxPages;
      while (page <= safeMaxPages) {
        final result = await _repository.loadProviderPosts(
          page: page,
          limit: limit,
        );
        combined.addAll(result.items);
        if (!result.pagination.hasNextPage) break;
        page += 1;
      }

      final deduped = <String, ProviderPostItem>{};
      for (final item in combined) {
        deduped[item.id] = item;
      }
      allPosts.value = deduped.values.toList(growable: false);
    } catch (_) {
      // Keep previous allPosts values when lookup refresh fails.
    } finally {
      allPostsLoading.value = false;
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
    if (_normalizedPage(pagination.value.page) == 1) {
      posts.value = <ProviderPostItem>[
        created,
        ...posts.value.where((item) => item.id != created.id),
      ].take(_pageSize).toList(growable: false);
    }
    allPosts.value = <ProviderPostItem>[
      created,
      ...allPosts.value.where((item) => item.id != created.id),
    ];
    pagination.value = _withAdjustedTotalItems(pagination.value, delta: 1);
  }

  static int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }

  static PaginationMeta _withAdjustedTotalItems(
    PaginationMeta current, {
    required int delta,
  }) {
    final totalItems = (current.totalItems + delta).clamp(0, 99999999);
    final limit = current.limit <= 0 ? _pageSize : current.limit;
    final totalPages = totalItems == 0
        ? 0
        : ((totalItems + limit - 1) ~/ limit);
    final page = current.page.clamp(1, totalPages == 0 ? 1 : totalPages);
    return PaginationMeta(
      page: page,
      limit: limit,
      totalItems: totalItems,
      totalPages: totalPages,
      hasPrevPage: totalPages > 0 && page > 1,
      hasNextPage: totalPages > 0 && page < totalPages,
    );
  }
}
