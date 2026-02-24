import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'app_role_state.dart';

class ProfileImageState {
  static final ValueNotifier<Uint8List?> _finderAvatarBytes =
      ValueNotifier<Uint8List?>(null);
  static final ValueNotifier<Uint8List?> _providerAvatarBytes =
      ValueNotifier<Uint8List?>(null);
  static final ValueNotifier<int> _finderAvatarSignal = ValueNotifier<int>(0);
  static final ValueNotifier<int> _providerAvatarSignal = ValueNotifier<int>(0);
  static final ValueNotifier<String> _finderAvatarUrl = ValueNotifier<String>(
    '',
  );
  static final ValueNotifier<String> _providerAvatarUrl = ValueNotifier<String>(
    '',
  );

  static ValueListenable<int> get listenable =>
      listenableForRole(isProvider: AppRoleState.isProvider);

  static ValueListenable<int> listenableForRole({required bool isProvider}) =>
      isProvider ? _providerAvatarSignal : _finderAvatarSignal;

  static bool get hasCustomAvatar =>
      _valueForRole(AppRoleState.isProvider) != null ||
      _urlForRole(AppRoleState.isProvider).isNotEmpty;

  static bool hasCustomAvatarForRole({required bool isProvider}) =>
      _valueForRole(isProvider) != null || _urlForRole(isProvider).isNotEmpty;

  static void setCustomAvatar(Uint8List bytes, {bool? isProvider}) {
    final targetRole = isProvider ?? AppRoleState.isProvider;
    _notifierForRole(targetRole).value = bytes;
    _bumpSignal(targetRole);
  }

  static void setRemoteAvatarUrl(String url, {bool? isProvider}) {
    final targetRole = isProvider ?? AppRoleState.isProvider;
    final normalized = url.trim();
    final dataBytes = _decodeImageDataUrl(normalized);
    if (dataBytes != null) {
      _notifierForRole(targetRole).value = dataBytes;
      _urlNotifierForRole(targetRole).value = normalized;
      _bumpSignal(targetRole);
      return;
    }
    _notifierForRole(targetRole).value = null;
    _urlNotifierForRole(targetRole).value = normalized;
    _bumpSignal(targetRole);
  }

  static void useDefaultAvatar({bool? isProvider}) {
    final targetRole = isProvider ?? AppRoleState.isProvider;
    _notifierForRole(targetRole).value = null;
    _urlNotifierForRole(targetRole).value = '';
    _bumpSignal(targetRole);
  }

  static ImageProvider<Object>? avatarProvider({bool? isProvider}) {
    final targetRole = isProvider ?? AppRoleState.isProvider;
    final bytes = _valueForRole(targetRole);
    if (bytes != null) return MemoryImage(bytes);
    final url = _urlForRole(targetRole);
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }

  static ImageProvider<Object>? avatarProviderForRole({
    required bool isProvider,
  }) {
    final bytes = _valueForRole(isProvider);
    if (bytes != null) return MemoryImage(bytes);
    final url = _urlForRole(isProvider);
    if (url.isEmpty) return null;
    return NetworkImage(url);
  }

  static ValueNotifier<Uint8List?> _notifierForRole(bool isProvider) =>
      isProvider ? _providerAvatarBytes : _finderAvatarBytes;

  static ValueNotifier<String> _urlNotifierForRole(bool isProvider) =>
      isProvider ? _providerAvatarUrl : _finderAvatarUrl;

  static Uint8List? _valueForRole(bool isProvider) =>
      isProvider ? _providerAvatarBytes.value : _finderAvatarBytes.value;

  static String _urlForRole(bool isProvider) =>
      isProvider ? _providerAvatarUrl.value : _finderAvatarUrl.value;

  static Uint8List? _decodeImageDataUrl(String value) {
    if (!value.startsWith('data:image/')) return null;
    final commaIndex = value.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= value.length - 1) return null;
    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  static void _bumpSignal(bool isProvider) {
    final notifier = isProvider ? _providerAvatarSignal : _finderAvatarSignal;
    notifier.value = notifier.value + 1;
  }
}
