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
      default:
        throw UnsupportedError('This app supports only web, android, and ios.');
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: AppEnv.firebaseWebApiKey(),
    appId: AppEnv.firebaseWebAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    authDomain: AppEnv.firebaseAuthDomain(),
    storageBucket: AppEnv.firebaseStorageBucket(),
    measurementId: AppEnv.firebaseMeasurementId(),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: AppEnv.firebaseAndroidApiKey(),
    appId: AppEnv.firebaseAndroidAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    storageBucket: AppEnv.firebaseStorageBucket(),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: AppEnv.firebaseIosApiKey(),
    appId: AppEnv.firebaseIosAppId(),
    messagingSenderId: AppEnv.firebaseMessagingSenderId(),
    projectId: AppEnv.firebaseProjectId(),
    storageBucket: AppEnv.firebaseStorageBucket(),
    iosClientId: AppEnv.firebaseIosClientId(),
    iosBundleId: AppEnv.firebaseIosBundleId(),
  );
}
