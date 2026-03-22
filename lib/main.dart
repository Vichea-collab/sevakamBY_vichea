import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/config/app_env.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'presentation/app.dart';
import 'presentation/state/auth_state.dart';
import 'presentation/state/app_sync_state.dart';
import 'presentation/state/chat_state.dart';
import 'presentation/state/finder_post_state.dart';
import 'presentation/state/order_state.dart';
import 'presentation/state/provider_post_state.dart';
import 'presentation/state/profile_settings_state.dart';
import 'presentation/state/catalog_state.dart';
import 'presentation/state/booking_catalog_state.dart';
import 'presentation/state/favorite_state.dart';
import 'presentation/state/app_role_state.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseBootstrap.initializeIfConfigured();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await _runSafe('AppEnv.load', AppEnv.load);
  
  // Must initialize AppRoleState BEFORE AuthState so AuthState knows who is signing in natively
  await _runSafe('AppRoleState.initialize', AppRoleState.initialize);
  
  await _runSafe('AuthState.initialize', AuthState.initialize);
  await Future.wait<void>([
    _runSafe('FavoriteState.init', FavoriteState.init),
    _runSafe(
      'ProfileSettingsState.initialize',
      ProfileSettingsState.initialize,
    ),
    _runSafe('CatalogState.initialize', CatalogState.initialize),
    _runSafe('BookingCatalogState.initialize', BookingCatalogState.initialize),
    _runSafe('ChatState.initialize', ChatState.initialize),
    _runSafe('FinderPostState.initialize', FinderPostState.initialize),
    _runSafe('ProviderPostState.initialize', ProviderPostState.initialize),
    _runSafe('OrderState.initialize', OrderState.initialize),
  ]);
  await _runSafe(
    'AppSyncState.initialize',
    () => AppSyncState.initialize(signedIn: AuthState.isSignedIn),
  );
  runApp(const ServiceFinderApp());
}

Future<void> _runSafe(String label, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    debugPrint('$label failed: $error');
  }
}
