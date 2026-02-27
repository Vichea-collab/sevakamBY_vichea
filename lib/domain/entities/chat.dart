enum ChatMessageType { text, image }

enum ChatDeliveryStatus { sending, sent, delivered, seen }

class ChatMessage {
  final String id;
  final String text;
  final ChatMessageType type;
  final String imageUrl;
  final bool fromMe;
  final DateTime sentAt;
  final ChatDeliveryStatus deliveryStatus;

  const ChatMessage({
    required this.id,
    required this.text,
    this.type = ChatMessageType.text,
    this.imageUrl = '',
    required this.fromMe,
    required this.sentAt,
    this.deliveryStatus = ChatDeliveryStatus.delivered,
  });
}

class ChatThread {
  final String id;
  final String title;
  final String subtitle;
  final String avatarPath;
  final DateTime updatedAt;
  final int unreadCount;
  final List<ChatMessage> messages;

  const ChatThread({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatarPath,
    required this.updatedAt,
    required this.unreadCount,
    required this.messages,
  });
}
