import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileImageState {
  static final ValueNotifier<Uint8List?> _avatarBytes =
      ValueNotifier<Uint8List?>(null);

  static ValueListenable<Uint8List?> get listenable => _avatarBytes;

  static bool get hasCustomAvatar => _avatarBytes.value != null;

  static void setCustomAvatar(Uint8List bytes) {
    _avatarBytes.value = bytes;
  }

  static void useDefaultAvatar() {
    _avatarBytes.value = null;
  }

  static ImageProvider<Object> avatarProvider() {
    final bytes = _avatarBytes.value;
    if (bytes != null) return MemoryImage(bytes);
    return const AssetImage('assets/images/profile.jpg');
  }
}
