import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/app_env.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey(),
    appId: AppEnv.firebaseAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    authDomain: AppEnv.firebaseAuthDomain(),
    storageBucket: AppEnv.firebaseStorageBucket(),
    measurementId: AppEnv.firebaseMeasurementId(),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey(),
    appId: AppEnv.firebaseAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    storageBucket: AppEnv.firebaseStorageBucket(),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey(),
    appId: AppEnv.firebaseAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    storageBucket: AppEnv.firebaseStorageBucket(),
    iosClientId: AppEnv.firebaseIosClientId(),
    iosBundleId: AppEnv.firebaseIosBundleId(),
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey(),
    appId: AppEnv.firebaseAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    storageBucket: AppEnv.firebaseStorageBucket(),
    iosClientId: AppEnv.firebaseIosClientId(),
    iosBundleId: AppEnv.firebaseIosBundleId(),
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey(),
    appId: AppEnv.firebaseAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    authDomain: AppEnv.firebaseAuthDomain(),
    storageBucket: AppEnv.firebaseStorageBucket(),
  );

  static FirebaseOptions get linux => FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey(),
    appId: AppEnv.firebaseAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    authDomain: AppEnv.firebaseAuthDomain(),
    storageBucket: AppEnv.firebaseStorageBucket(),
  );
}
