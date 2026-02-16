import 'package:flutter/material.dart';

import '../core/config/app_env.dart';
import '../core/firebase/firebase_bootstrap.dart';
import 'app/admin_web_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();
  final firebaseReady = await FirebaseBootstrap.initializeIfConfigured();
  runApp(AdminWebApp(firebaseReady: firebaseReady));
}
