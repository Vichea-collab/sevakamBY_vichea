import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat.dart';

/// Converts various timestamp formats (Firestore Timestamp, ISO string,
/// epoch millis/seconds, Firestore-style map) into a local [DateTime].
DateTime chatDateTimeFromDynamic(dynamic value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (value is DateTime) return value.toLocal();
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  if (value is num) {
    if (value == 0) return DateTime.fromMillisecondsSinceEpoch(0);
    final intValue = value.toInt();
    final milliseconds =
        intValue.abs() < 1000000000000 ? intValue * 1000 : intValue;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  }
  if (value is Map && value['_seconds'] is num) {
    final seconds = value['_seconds'] as num;
    return DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000).round(),
    ).toLocal();
  }
  if (value is Map && value['seconds'] is num) {
    final seconds = value['seconds'] as num;
    return DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000).round(),
    ).toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// Determines the delivery status of a chat message based on seen/delivered
/// lists relative to the current user.
ChatDeliveryStatus chatDeliveryStatus({
  required String senderUid,
  required String currentUid,
  required List<String> seenBy,
  required List<String> deliveredTo,
}) {
  if (senderUid != currentUid) return ChatDeliveryStatus.seen;
  final peerSeen = seenBy.any((uid) => uid.isNotEmpty && uid != senderUid);
  if (peerSeen) return ChatDeliveryStatus.seen;
  final peerDelivered = deliveredTo.any(
    (uid) => uid.isNotEmpty && uid != senderUid,
  );
  if (peerDelivered) return ChatDeliveryStatus.delivered;
  return ChatDeliveryStatus.sent;
}

/// Extracts the file extension from a filename (defaults to `.jpg`).
String chatFileExtension(String fileName) {
  final trimmed = fileName.trim();
  final dot = trimmed.lastIndexOf('.');
  if (dot <= 0 || dot >= trimmed.length - 1) return '.jpg';
  return '.${trimmed.substring(dot + 1).toLowerCase()}';
}

/// Maps a file extension to its MIME type (defaults to `image/jpeg`).
String chatMimeType(String extension) {
  switch (extension.toLowerCase()) {
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.heic':
      return 'image/heic';
    case '.jpg':
    case '.jpeg':
    default:
      return 'image/jpeg';
  }
}
