import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_role_state.dart';

class ProfileImageState {
  static final ValueNotifier<Uint8List?> _finderAvatarBytes =
      ValueNotifier<Uint8List?>(null);
  static final ValueNotifier<Uint8List?> _providerAvatarBytes =
      ValueNotifier<Uint8List?>(null);

  static ValueListenable<Uint8List?> get listenable =>
      listenableForRole(isProvider: AppRoleState.isProvider);

  static ValueListenable<Uint8List?> listenableForRole({
    required bool isProvider,
  }) => isProvider ? _providerAvatarBytes : _finderAvatarBytes;

  static bool get hasCustomAvatar =>
      _valueForRole(AppRoleState.isProvider) != null;

  static bool hasCustomAvatarForRole({required bool isProvider}) =>
      _valueForRole(isProvider) != null;

  static void setCustomAvatar(Uint8List bytes, {bool? isProvider}) {
    _notifierForRole(isProvider ?? AppRoleState.isProvider).value = bytes;
  }

  static void useDefaultAvatar({bool? isProvider}) {
    _notifierForRole(isProvider ?? AppRoleState.isProvider).value = null;
  }

  static ImageProvider<Object>? avatarProvider({bool? isProvider}) {
    final bytes = _valueForRole(isProvider ?? AppRoleState.isProvider);
    if (bytes == null) return null;
    return MemoryImage(bytes);
  }

  static ValueNotifier<Uint8List?> _notifierForRole(bool isProvider) =>
      isProvider ? _providerAvatarBytes : _finderAvatarBytes;

  static Uint8List? _valueForRole(bool isProvider) =>
      isProvider ? _providerAvatarBytes.value : _finderAvatarBytes.value;
}
