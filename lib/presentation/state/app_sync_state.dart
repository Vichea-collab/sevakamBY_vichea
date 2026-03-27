import 'dart:async';

import 'package:flutter/widgets.dart';

import 'chat_state.dart';
import 'catalog_state.dart';
import 'finder_post_state.dart';
import 'order_state.dart';
import 'provider_post_state.dart';
import 'user_notification_state.dart';

class AppSyncState with WidgetsBindingObserver {
  // Spark-friendly cadence to reduce Firestore reads.
  static const Duration _syncInterval = Duration(minutes: 10);
  static const Duration _fastSyncInterval = Duration(seconds: 15);
  static const Duration _forceFullSyncInterval = Duration(minutes: 30);
  static const Duration _catalogRefreshInterval = Duration(hours: 6);
  static const Duration _lookupRefreshInterval = Duration(hours: 4);

  static bool _initialized = false;
  static bool _signedIn = false;
  static bool _syncing = false;
  static bool _fastSyncing = false;
  static Timer? _timer;
  static Timer? _fastTimer;
  static DateTime? _lastCatalogSyncedAt;
  static DateTime? _lastFullSyncedAt;
  static DateTime? _lastFinderLookupSyncedAt;
  static DateTime? _lastProviderLookupSyncedAt;

  static Future<void> initialize({required bool signedIn}) async {
    if (_initialized) {
      await setSignedIn(signedIn);
      return;
    }
    _initialized = true;
    _signedIn = signedIn;
    WidgetsBinding.instance.addObserver(AppSyncState());
    if (_signedIn) {
      unawaited(_syncNow(forceFull: true));
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
    unawaited(_syncNow(forceFull: true));
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
    _fastTimer = Timer.periodic(_fastSyncInterval, (_) {
      unawaited(_fastSyncNow());
    });
  }

  static void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _fastTimer?.cancel();
    _fastTimer = null;
  }

  static Future<void> _fastSyncNow() async {
    if (!_signedIn || _fastSyncing) return;
    _fastSyncing = true;
    try {
      final tasks = <Future<void>>[];
      
      // Fast poll for new notifications without full payload
      if (!UserNotificationState.loading.value) {
        tasks.add(_safeRun(() => UserNotificationState.refreshUnreadStatus()));
      }

      // Fast poll for new chats and unread count
      if (!ChatState.loading.value) {
        tasks.add(_safeRun(ChatState.refreshUnreadCount));
        
        // Also update heartbeat to keep user online status fresh
        tasks.add(_safeRun(ChatState.updateHeartbeat));
        
        // If there's an active thread being viewed or just checking for new messages in general
        if (!ChatState.realtimeActive.value) {
           tasks.add(_safeRun(() => ChatState.refresh(limit: 5)));
        }
      }

      // Important to also pull order state as new matches appear there
      if (!OrderState.loading.value && !OrderState.realtimeActive.value) {
         tasks.add(_safeRun(() => OrderState.refreshCurrentRole(forceNetwork: false)));
      }

      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }
    } catch (_) {
      // Ignore transient errors on fast poll
    } finally {
      _fastSyncing = false;
    }
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
      final shouldRefreshFinderLookup =
          shouldForceFull ||
          _lastFinderLookupSyncedAt == null ||
          now.difference(_lastFinderLookupSyncedAt!) >= _lookupRefreshInterval;
      final shouldRefreshProviderLookup =
          shouldForceFull ||
          _lastProviderLookupSyncedAt == null ||
          now.difference(_lastProviderLookupSyncedAt!) >=
              _lookupRefreshInterval;

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
            if (shouldRefreshFinderLookup ||
                FinderPostState.allPosts.value.isEmpty) {
              await FinderPostState.refreshAllForLookup(maxPages: 3);
              _lastFinderLookupSyncedAt = DateTime.now();
            }
          }),
        );
      }

      if (!ProviderPostState.loading.value) {
        tasks.add(
          _safeRun(() async {
            await ProviderPostState.refresh();
            if (shouldRefreshProviderLookup ||
                ProviderPostState.allPosts.value.isEmpty) {
              await ProviderPostState.refreshAllForLookup(maxPages: 3);
              _lastProviderLookupSyncedAt = DateTime.now();
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

      if (!UserNotificationState.loading.value) {
        tasks.add(_safeRun(UserNotificationState.refresh));
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
