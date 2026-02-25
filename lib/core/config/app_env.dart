import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class AppEnv {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // App can still run with --dart-define fallback values.
    }
  }

  static String apiBaseUrl() {
    final raw = _read(
      key: 'API_BASE_URL',
      fallback: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5050',
      ),
    );
    return _normalizeApiBaseUrl(raw);
  }

  static String apiAuthToken() {
    return _read(
      key: 'API_AUTH_TOKEN',
      fallback: const String.fromEnvironment('API_AUTH_TOKEN'),
    );
  }

  static String googleMapsApiKey() {
    if (kIsWeb) return googleMapsWebApiKey();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return googleMapsAndroidApiKey();
      case TargetPlatform.iOS:
        return googleMapsIosApiKey();
      default:
        return _read(
          key: 'GOOGLE_MAPS_API_KEY',
          fallback: const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
        );
    }
  }

  static String googleMapsWebApiKey() {
    final webSpecific = _read(
      key: 'GOOGLE_MAPS_WEB_API_KEY',
      fallback: const String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY'),
    );
    if (webSpecific.isNotEmpty) return webSpecific;
    return _read(
      key: 'GOOGLE_MAPS_API_KEY',
      fallback: const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    );
  }

  static String googleMapsAndroidApiKey() {
    final androidSpecific = _read(
      key: 'GOOGLE_MAPS_ANDROID_API_KEY',
      fallback: const String.fromEnvironment('GOOGLE_MAPS_ANDROID_API_KEY'),
    );
    if (androidSpecific.isNotEmpty) return androidSpecific;
    return _read(
      key: 'GOOGLE_MAPS_API_KEY',
      fallback: const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    );
  }

  static String googleMapsIosApiKey() {
    final iosSpecific = _read(
      key: 'GOOGLE_MAPS_IOS_API_KEY',
      fallback: const String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY'),
    );
    if (iosSpecific.isNotEmpty) return iosSpecific;
    return _read(
      key: 'GOOGLE_MAPS_API_KEY',
      fallback: const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    );
  }

  static String firebaseApiKey() {
    return _read(
      key: 'FIREBASE_API_KEY',
      fallback: const String.fromEnvironment('FIREBASE_API_KEY'),
    );
  }

  static String firebaseWebApiKey() {
    return _read(key: 'FIREBASE_WEB_API_KEY', fallback: firebaseApiKey());
  }

  static String firebaseAndroidApiKey() {
    return _read(key: 'FIREBASE_ANDROID_API_KEY', fallback: firebaseApiKey());
  }

  static String firebaseIosApiKey() {
    return _read(key: 'FIREBASE_IOS_API_KEY', fallback: firebaseApiKey());
  }

  static String firebaseAppId() {
    return _read(
      key: 'FIREBASE_APP_ID',
      fallback: const String.fromEnvironment('FIREBASE_APP_ID'),
    );
  }

  static String firebaseWebAppId() {
    return _read(key: 'FIREBASE_WEB_APP_ID', fallback: firebaseAppId());
  }

  static String firebaseAndroidAppId() {
    return _read(key: 'FIREBASE_ANDROID_APP_ID', fallback: firebaseAppId());
  }

  static String firebaseIosAppId() {
    return _read(key: 'FIREBASE_IOS_APP_ID', fallback: firebaseAppId());
  }

  static String firebaseMessagingSenderId() {
    return _read(
      key: 'FIREBASE_MESSAGING_SENDER_ID',
      fallback: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    );
  }

  static String firebaseProjectId() {
    return _read(
      key: 'FIREBASE_PROJECT_ID',
      fallback: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    );
  }

  static String firebaseAuthDomain() {
    return _read(
      key: 'FIREBASE_AUTH_DOMAIN',
      fallback: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    );
  }

  static String firebaseStorageBucket() {
    return _read(
      key: 'FIREBASE_STORAGE_BUCKET',
      fallback: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    );
  }

  static String firebaseIosClientId() {
    return _read(
      key: 'FIREBASE_IOS_CLIENT_ID',
      fallback: const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
    );
  }

  static String firebaseIosBundleId() {
    return _read(
      key: 'FIREBASE_IOS_BUNDLE_ID',
      fallback: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    );
  }

  static String firebaseMeasurementId() {
    return _read(
      key: 'FIREBASE_MEASUREMENT_ID',
      fallback: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
    );
  }

  static String firebaseWebClientId() {
    return _read(
      key: 'FIREBASE_WEB_CLIENT_ID',
      fallback: const String.fromEnvironment('FIREBASE_WEB_CLIENT_ID'),
    );
  }

  static String firebaseRecaptchaV3SiteKey() {
    return _read(
      key: 'FIREBASE_RECAPTCHA_V3_SITE_KEY',
      fallback: const String.fromEnvironment('FIREBASE_RECAPTCHA_V3_SITE_KEY'),
    );
  }

  static bool enableDebugMobileAppCheck() {
    final raw = _read(
      key: 'FIREBASE_ENABLE_DEBUG_MOBILE_APP_CHECK',
      fallback: const String.fromEnvironment(
        'FIREBASE_ENABLE_DEBUG_MOBILE_APP_CHECK',
      ),
    ).toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }

  static String _read({required String key, required String fallback}) {
    final fromEnv = dotenv.env[key]?.trim() ?? '';
    if (fromEnv.isNotEmpty) return fromEnv;
    return fallback.trim();
  }

  static String _normalizeApiBaseUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return raw;

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return raw;

    // Android emulator cannot reach host localhost directly.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const localhostHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
      if (localhostHosts.contains(uri.host.toLowerCase())) {
        return uri.replace(host: '10.0.2.2').toString();
      }
    }

    return raw;
  }
}
