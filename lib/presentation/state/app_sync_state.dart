import 'dart:async';

import 'package:flutter/widgets.dart';

import 'chat_state.dart';
import 'catalog_state.dart';
import 'finder_post_state.dart';
import 'order_state.dart';
import 'provider_post_state.dart';

class AppSyncState with WidgetsBindingObserver {
  // Spark-friendly cadence to reduce Firestore reads.
  static const Duration _syncInterval = Duration(minutes: 2);
  static const Duration _forceFullSyncInterval = Duration(minutes: 10);
  static const Duration _catalogRefreshInterval = Duration(minutes: 30);

  static bool _initialized = false;
  static bool _signedIn = false;
  static bool _syncing = false;
  static Timer? _timer;
  static DateTime? _lastCatalogSyncedAt;
  static DateTime? _lastFullSyncedAt;

  static Future<void> initialize({required bool signedIn}) async {
    if (_initialized) {
      await setSignedIn(signedIn);
      return;
    }
    _initialized = true;
    _signedIn = signedIn;
    WidgetsBinding.instance.addObserver(AppSyncState());
    if (_signedIn) {
      await _syncNow(forceFull: true);
      _startTimer();
    }
  }

  static Future<void> setSignedIn(bool value) async {
    _signedIn = value;
    if (!_initialized) return;
    if (!_signedIn) {
      _stopTimer();
      return;
    }
    await _syncNow(forceFull: true);
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized || !_signedIn) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNow(forceFull: true));
      _startTimer();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTimer();
    }
  }

  static void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(_syncInterval, (_) {
      unawaited(_syncNow());
    });
  }

  static void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _syncNow({bool forceFull = false}) async {
    if (!_signedIn || _syncing) return;
    _syncing = true;
    try {
      final now = DateTime.now();
      final shouldForceFull =
          forceFull ||
          _lastFullSyncedAt == null ||
          now.difference(_lastFullSyncedAt!) >= _forceFullSyncInterval;
      if (shouldForceFull) {
        _lastFullSyncedAt = now;
      }
      final shouldRefreshCatalog =
          shouldForceFull ||
          _lastCatalogSyncedAt == null ||
          now.difference(_lastCatalogSyncedAt!) >= _catalogRefreshInterval;

      final tasks = <Future<void>>[];

      if (shouldRefreshCatalog && !CatalogState.loading.value) {
        tasks.add(
          _safeRun(() async {
            await CatalogState.refresh();
            _lastCatalogSyncedAt = DateTime.now();
          }),
        );
      }

      if (!ChatState.loading.value &&
          (!ChatState.realtimeActive.value || shouldForceFull)) {
        tasks.add(_safeRun(ChatState.refresh));
      }

      if (!FinderPostState.loading.value &&
          (!FinderPostState.realtimeActive.value || shouldForceFull)) {
        tasks.add(
          _safeRun(() async {
            await FinderPostState.refresh();
            if (shouldForceFull || FinderPostState.allPosts.value.isEmpty) {
              await FinderPostState.refreshAllForLookup(maxPages: 3);
            }
          }),
        );
      }

      if (!ProviderPostState.loading.value) {
        tasks.add(
          _safeRun(() async {
            await ProviderPostState.refresh();
            if (shouldForceFull || ProviderPostState.allPosts.value.isEmpty) {
              await ProviderPostState.refreshAllForLookup(maxPages: 3);
            }
          }),
        );
      }

      if (!OrderState.loading.value) {
        tasks.add(
          _safeRun(
            () => OrderState.refreshCurrentRole(
              forceNetwork: shouldForceFull || !OrderState.realtimeActive.value,
            ),
          ),
        );
      }

      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }
    } catch (_) {
      // Ignore transient network errors; next cycle will retry.
    } finally {
      _syncing = false;
    }
  }

  static Future<void> _safeRun(Future<void> Function() task) async {
    try {
      await task();
    } catch (_) {
      // Isolate sync task failure so others continue.
    }
  }
}
