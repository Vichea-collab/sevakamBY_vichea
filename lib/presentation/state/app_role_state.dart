import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { finder, provider }

class AppRoleState {
  static final ValueNotifier<AppRole> role = ValueNotifier(AppRole.finder);
  static const String _roleKey = 'active_app_role_v1';
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedRole = _prefs?.getString(_roleKey);
      if (savedRole == 'provider') {
        role.value = AppRole.provider;
      } else {
        role.value = AppRole.finder; // Default
      }
    } catch (_) {
      // Ignore initial setup error
    }
  }

  static bool get isProvider => role.value == AppRole.provider;

  static void setProvider(bool enabled) {
    role.value = enabled ? AppRole.provider : AppRole.finder;
    _prefs?.setString(_roleKey, enabled ? 'provider' : 'finder');
  }

  static String homeRoute() => '/main';
  static String notificationRoute() => '/main';
  static String postRoute() => '/main';
  static String orderRoute() => '/main';
  static String profileRoute() => '/main';
}
