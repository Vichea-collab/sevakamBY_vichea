import 'package:flutter/material.dart';
import 'core/config/app_env.dart';
import 'presentation/app.dart';
import 'presentation/state/auth_state.dart';
import 'presentation/state/finder_post_state.dart';
import 'presentation/state/profile_settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();
  await AuthState.initialize();
  await ProfileSettingsState.initialize();
  await FinderPostState.initialize();
  runApp(const ServiceFinderApp());
}
