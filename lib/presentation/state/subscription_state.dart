import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_env.dart';
import '../../data/network/backend_api_client.dart';
import '../../domain/entities/subscription.dart';

class SubscriptionState {
  static final ValueNotifier<SubscriptionStatus> status =
      ValueNotifier(const SubscriptionStatus());

  static final ValueNotifier<bool> loading = ValueNotifier(false);

  static final BackendApiClient _apiClient = BackendApiClient(
    baseUrl: AppEnv.apiBaseUrl(),
    bearerToken: AppEnv.apiAuthToken(),
  );

  static Future<void> _ensureToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken() ?? '';
        _apiClient.setBearerToken(token);
      }
    } catch (_) {}
  }

  static void setBackendToken(String token) {
    _apiClient.setBearerToken(token);
  }

  static Future<void> fetchStatus() async {
    try {
    Future.microtask(() => loading.value = true);
      await _ensureToken();
      final response = await _apiClient.getJson('/api/subscriptions/status');
      final data = response['data'];
      debugPrint('[SubscriptionState] fetchStatus data: $data');
      if (data is Map<String, dynamic>) {
        status.value = SubscriptionStatus.fromMap(data);
        debugPrint('[SubscriptionState] Updated status: ${status.value.tier}');
      }
    } catch (e) {
      debugPrint('[SubscriptionState] fetchStatus error: $e');
    } finally {
      loading.value = false;
    }
  }

  static Future<SubscriptionCheckoutSession> createCheckoutSession(
    SubscriptionTier tier, {
    String paymentMethod = 'stripe',
  }) async {
    final plan = tier == SubscriptionTier.professional
        ? 'professional'
        : 'elite';

    try {
      await _ensureToken();
      final response = await _apiClient.postJson('/api/subscriptions/checkout', {
        'plan': plan,
        'paymentMethod': paymentMethod,
      });
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return SubscriptionCheckoutSession.fromMap(data);
      }
    } catch (e) {
      debugPrint('SubscriptionState.createCheckoutSession error: $e');
      rethrow;
    }
    return const SubscriptionCheckoutSession(sessionId: '');
  }

  static Future<void> verifyCheckout(
    String sessionId, {
    String? paymentMethod,
  }) async {
    try {
      debugPrint('[SubscriptionState] verifyCheckout started for: $sessionId');
      await _ensureToken();
      final response = await _apiClient.postJson('/api/subscriptions/verify', {
        'sessionId': sessionId,
        if ((paymentMethod ?? '').trim().isNotEmpty) 'paymentMethod': paymentMethod,
      });
      final data = response['data'];
      debugPrint('[SubscriptionState] verifyCheckout response data: $data');
      if (data is Map<String, dynamic> && data['tier'] != null) {
        status.value = SubscriptionStatus.fromMap(data);
        debugPrint('[SubscriptionState] verifyCheckout success. New tier: ${status.value.tier}');
      } else {
        debugPrint('[SubscriptionState] verifyCheckout: No update applied (verified: ${data['verified']})');
      }
    } catch (e) {
      debugPrint('[SubscriptionState] verifyCheckout error: $e');
    }
  }

  static Future<bool> cancelSubscription() async {
    try {
      await _ensureToken();
      final response = await _apiClient.postJson('/api/subscriptions/cancel', {});
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        status.value = SubscriptionStatus.fromMap(data);
      }
      return true;
    } catch (e) {
      debugPrint('SubscriptionState.cancelSubscription error: $e');
      return false;
    }
  }

  /// Verify & poll status after returning from Stripe Checkout
  static Future<void> refreshAfterCheckout({
    String? sessionId,
    String? paymentMethod,
    SubscriptionTier? expectedTier,
  }) async {
    final hasSession = sessionId != null && sessionId.isNotEmpty;
    
    // Fallback: poll status more aggressively for instant update
    // We retry VERIFICATION as well because Stripe might be slow to propagate "paid" status
    // Increased to 30 iterations for 30s coverage
    for (int i = 0; i < 30; i++) {
      if (hasSession) {
        await verifyCheckout(sessionId, paymentMethod: paymentMethod);
      } else {
        await fetchStatus();
      }
      
      final tierMatched = expectedTier == null
          ? status.value.tier != SubscriptionTier.basic
          : status.value.tier == expectedTier;
      if (tierMatched) {
        debugPrint('[SubscriptionState] Successfully updated to ${status.value.tier} after $i retries');
        return;
      }
      
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
