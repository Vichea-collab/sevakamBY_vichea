import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/app_env.dart';
import '../../firebase_options.dart';

class FirebaseBootstrap {
  static bool _initialized = false;
  static bool _configured = false;

  static bool get isInitialized => _initialized;
  static bool get isConfigured => _configured;

  static Future<bool> initializeIfConfigured() async {
    if (_initialized) return _configured;

    try {
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        _configured = true;
        return true;
      }

      if (kIsWeb) {
        final apiKey = AppEnv.firebaseApiKey();
        final appId = AppEnv.firebaseAppId();
        final senderId = AppEnv.firebaseMessagingSenderId();
        final projectId = AppEnv.firebaseProjectId();
        final requiredReady =
            apiKey.isNotEmpty &&
            appId.isNotEmpty &&
            senderId.isNotEmpty &&
            projectId.isNotEmpty;
        if (!requiredReady) {
          _initialized = true;
          _configured = false;
          return false;
        }
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await _activateWebAppCheckIfConfigured();
      } else {
        // Mobile/desktop platforms should initialize from native Firebase files
        // (google-services.json / GoogleService-Info.plist).
        await Firebase.initializeApp();
        await _activateAppCheckIfSupported();
      }

      _initialized = true;
      _configured = true;
      return true;
    } catch (_) {
      _initialized = true;
      _configured = false;
      return false;
    }
  }

  static String setupHint() {
    if (_configured) return '';
    return kIsWeb
        ? 'Set FIREBASE_* values in .env for web Firebase initialization.'
        : 'Check native Firebase files: android/app/google-services.json and ios/Runner/GoogleService-Info.plist.';
  }

  static Future<void> _activateAppCheckIfSupported() async {
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          await FirebaseAppCheck.instance.activate(
            providerAndroid: kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
          );
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          await FirebaseAppCheck.instance.activate(
            providerApple: kDebugMode
                ? const AppleDebugProvider()
                : const AppleDeviceCheckProvider(),
          );
          break;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          // App Check is not required for these local desktop dev targets here.
          break;
      }
    } catch (error) {
      debugPrint('Firebase App Check activation skipped: $error');
    }
  }

  static Future<void> _activateWebAppCheckIfConfigured() async {
    final siteKey = AppEnv.firebaseRecaptchaV3SiteKey();
    if (siteKey.isEmpty) {
      debugPrint(
        'Firebase App Check (web) skipped: FIREBASE_RECAPTCHA_V3_SITE_KEY is missing.',
      );
      return;
    }
    try {
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(siteKey),
      );
    } catch (error) {
      debugPrint('Firebase App Check (web) activation skipped: $error');
    }
  }
}
