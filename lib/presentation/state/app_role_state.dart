import 'package:flutter/foundation.dart';

enum AppRole { finder, provider }

class AppRoleState {
  static final ValueNotifier<AppRole> role = ValueNotifier(AppRole.finder);

  static bool get isProvider => role.value == AppRole.provider;

  static void setProvider(bool enabled) {
    role.value = enabled ? AppRole.provider : AppRole.finder;
  }

  static String homeRoute() => '/main';
  static String notificationRoute() => '/main';
  static String postRoute() => '/main';
  static String orderRoute() => '/main';
  static String profileRoute() => '/main';
}
