import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../data/network/backend_api_client.dart';

class PushNotificationState {
  static final BackendApiClient _apiClient = BackendApiClient(
    baseUrl: AppEnv.apiBaseUrl(),
    bearerToken: AppEnv.apiAuthToken(),
  );

  static String _lastRegisteredToken = '';
  static String _lastKnownBearerToken = '';

  static void setBackendToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isNotEmpty) {
      _lastKnownBearerToken = trimmed;
    }
    _apiClient.setBearerToken(trimmed);
  }

  static Future<void> syncCurrentDeviceToken() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = (await FirebaseMessaging.instance.getAPNSToken() ?? '')
            .trim();
        if (apnsToken.isEmpty) return;
      }
      final token = (await FirebaseMessaging.instance.getToken() ?? '').trim();
      if (token.isEmpty) return;
      await registerDeviceToken(token);
    } catch (_) {
      // APNS can be unavailable for a while on iOS simulators and early app boot.
    }
  }

  static Future<void> registerDeviceToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    final ready = await _ensureBackendToken();
    if (!ready) return;
    await _apiClient.putJson('/api/users/push-token', {
      'token': normalized,
      'platform': _platformLabel(),
    });
    _lastRegisteredToken = normalized;
  }

  static Future<void> unregisterCurrentToken() async {
    final token = _lastRegisteredToken.trim();
    if (token.isEmpty) return;

    final currentBearer = _apiClient.bearerToken.trim();
    final fallbackBearer = _lastKnownBearerToken.trim();
    final tokenToUse = currentBearer.isNotEmpty ? currentBearer : fallbackBearer;
    if (tokenToUse.isEmpty) return;

    final previousBearer = _apiClient.bearerToken;
    _apiClient.setBearerToken(tokenToUse);
    try {
      await _apiClient.postJson('/api/users/push-token/remove', {
        'token': token,
      });
      _lastRegisteredToken = '';
    } catch (_) {
      // Best effort during sign-out.
    } finally {
      _apiClient.setBearerToken(previousBearer);
    }
  }

  static Future<bool> _ensureBackendToken() async {
    if (_apiClient.bearerToken.trim().isNotEmpty) return true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final token = (await user.getIdToken() ?? '').trim();
      if (token.isEmpty) return false;
      _lastKnownBearerToken = token;
      _apiClient.setBearerToken(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}
