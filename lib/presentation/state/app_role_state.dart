import 'package:flutter/foundation.dart';

enum AppRole { finder, provider }

class AppRoleState {
  static final ValueNotifier<AppRole> role = ValueNotifier(AppRole.finder);

  static bool get isProvider => role.value == AppRole.provider;

  static void setProvider(bool enabled) {
    role.value = enabled ? AppRole.provider : AppRole.finder;
  }

  static String homeRoute() => isProvider ? '/provider/home' : '/home';
  static String notificationRoute() =>
      isProvider ? '/provider/notifications' : '/notifications';
  static String postRoute() => isProvider ? '/provider/post' : '/post';
  static String orderRoute() => isProvider ? '/provider/orders' : '/orders';
  static String profileRoute() => isProvider ? '/provider/profile' : '/profile';
}
