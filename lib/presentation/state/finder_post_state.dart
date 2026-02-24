import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../core/config/app_env.dart';
import '../../data/datasources/remote/finder_post_remote_data_source.dart';
import '../../data/network/backend_api_client.dart';
import '../../data/repositories/finder_post_repository_impl.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/finder_post_repository.dart';

class FinderPostState {
  static const int _pageSize = 10;

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
  static final ValueNotifier<List<FinderPostItem>> allPosts = ValueNotifier(
    const <FinderPostItem>[],
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
      posts.value = const <FinderPostItem>[];
      allPosts.value = const <FinderPostItem>[];
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
    await _awaitSafeNotifierWindow();
    final targetPage = _normalizedPage(page ?? pagination.value.page);
    loading.value = true;
    try {
      final result = await _repository.loadFinderRequests(
        page: targetPage,
        limit: limit,
      );
      posts.value = result.items;
      pagination.value = result.pagination;
      realtimeActive.value = false;
    } catch (_) {
      posts.value = const <FinderPostItem>[];
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

  static Future<void> createFinderRequest({
    required String category,
    required List<String> services,
    required String location,
    required String message,
    required DateTime preferredDate,
  }) async {
    final created = await _repository.createFinderRequest(
      category: category,
      services: services,
      location: location,
      message: message,
      preferredDate: preferredDate,
    );
    if (_normalizedPage(pagination.value.page) == 1) {
      posts.value = <FinderPostItem>[
        created,
        ...posts.value.where((item) => item.id != created.id),
      ].take(_pageSize).toList(growable: false);
    }
    allPosts.value = <FinderPostItem>[
      created,
      ...allPosts.value.where((item) => item.id != created.id),
    ];
    pagination.value = _withAdjustedTotalItems(pagination.value, delta: 1);
  }

  static Future<void> refreshAllForLookup({
    int limit = _pageSize,
    int maxPages = 5,
  }) async {
    await _awaitSafeNotifierWindow();
    allPostsLoading.value = true;
    try {
      final combined = <FinderPostItem>[];
      var page = 1;
      final safeMaxPages = maxPages < 1 ? 1 : maxPages;
      while (page <= safeMaxPages) {
        final result = await _repository.loadFinderRequests(
          page: page,
          limit: limit,
        );
        combined.addAll(result.items);
        if (!result.pagination.hasNextPage) break;
        page += 1;
      }

      final deduped = <String, FinderPostItem>{};
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

  static Future<void> _awaitSafeNotifierWindow() async {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      return;
    }
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await completer.future;
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
