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
  await AppEnv.load();
  await AuthState.initialize();
  await Future.wait<void>([
    ProfileSettingsState.initialize(),
    CatalogState.initialize(),
    ChatState.initialize(),
    FinderPostState.initialize(),
    ProviderPostState.initialize(),
    OrderState.initialize(),
  ]);
  await AppSyncState.initialize(signedIn: AuthState.isSignedIn);
  runApp(const ServiceFinderApp());
}
