import 'package:flutter/material.dart';
import 'core/config/app_env.dart';
import 'presentation/app.dart';
import 'presentation/state/auth_state.dart';
import 'presentation/state/app_sync_state.dart';
import 'presentation/state/chat_state.dart';
import 'presentation/state/finder_post_state.dart';
import 'presentation/state/order_state.dart';
import 'presentation/state/provider_post_state.dart';
import 'presentation/state/profile_settings_state.dart';
import 'presentation/state/catalog_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _runSafe('AppEnv.load', AppEnv.load);
  await _runSafe('AuthState.initialize', AuthState.initialize);
  await Future.wait<void>([
    _runSafe(
      'ProfileSettingsState.initialize',
      ProfileSettingsState.initialize,
    ),
    _runSafe('CatalogState.initialize', CatalogState.initialize),
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
