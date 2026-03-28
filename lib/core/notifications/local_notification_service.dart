import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static const String soundingChannelId = 'sevakam_general';
  static const String silentChannelId = 'sevakam_general_silent';
  static const String _channelName = 'General notifications';
  static const String _channelDescription =
      'Sevakam updates, booking activity, support replies, and messages.';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize({
    required Future<void> Function(Map<String, dynamic> data) onTapData,
  }) async {
    if (_initialized || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload ?? '';
        if (payload.trim().isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            await onTapData(decoded);
          } else if (decoded is Map) {
            await onTapData(
              decoded.map((key, value) => MapEntry(key.toString(), value)),
            );
          }
        } catch (_) {
          // Ignore malformed payloads.
        }
      },
    );

    const soundingChannel = AndroidNotificationChannel(
      soundingChannelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    const silentChannel = AndroidNotificationChannel(
      silentChannelId,
      'General notifications (silent)',
      description: _channelDescription,
      importance: Importance.max,
      playSound: false,
      enableVibration: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(soundingChannel);
    await androidPlugin?.createNotificationChannel(silentChannel);

    _initialized = true;
  }

  static Future<void> showRemoteMessage(
    RemoteMessage message, {
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    if (!_initialized || kIsWeb) return;

    final notification = message.notification;
    final rawTitle = (notification?.title ?? '').trim();
    final rawBody = (notification?.body ?? '').trim();
    final title = rawTitle.isEmpty ? 'New notification' : rawTitle;
    final body = rawBody.isEmpty ? 'You have a new message.' : rawBody;
    final payload = jsonEncode(
      message.data.map((key, value) => MapEntry(key, value.toString())),
    );

    final androidDetails = AndroidNotificationDetails(
      playSound ? soundingChannelId : silentChannelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: title,
      playSound: playSound,
      enableVibration: enableVibration,
      styleInformation: const DefaultStyleInformation(true, true),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.show(
      id: _stableIdForMessage(message),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  static int _stableIdForMessage(RemoteMessage message) {
    final key = [
      message.messageId ?? '',
      message.data['threadId']?.toString() ?? '',
      message.data['chatId']?.toString() ?? '',
      message.sentTime?.millisecondsSinceEpoch.toString() ?? '',
      message.notification?.title ?? '',
      message.notification?.body ?? '',
    ].join('|');
    return key.hashCode & 0x7fffffff;
  }
}
