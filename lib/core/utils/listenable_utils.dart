import 'dart:async';

import 'package:flutter/foundation.dart';

/// Waits until a [ValueListenable<bool>] becomes `false`.
///
/// Returns immediately if the current value is already `false`.
Future<void> waitUntilNotLoading(ValueListenable<bool> listenable) async {
  if (!listenable.value) return;
  final completer = Completer<void>();
  late VoidCallback listener;
  listener = () {
    if (!listenable.value && !completer.isCompleted) {
      listenable.removeListener(listener);
      completer.complete();
    }
  };
  listenable.addListener(listener);
  // Re-check in case the value changed between the initial check and
  // attaching the listener.
  if (!listenable.value && !completer.isCompleted) {
    listenable.removeListener(listener);
    completer.complete();
  }
  await completer.future;
}
