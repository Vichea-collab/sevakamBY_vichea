class ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime sentAt;
  final bool seen;

  const ChatMessage({
    required this.text,
    required this.fromMe,
    required this.sentAt,
    this.seen = true,
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
