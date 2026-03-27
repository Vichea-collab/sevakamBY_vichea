/// Formats a [DateTime] as a relative time label (e.g. "Just now", "5 min ago").
String timeAgo(DateTime? date) {
  if (date == null) return 'Just now';
  final delta = DateTime.now().difference(date);
  if (delta.isNegative) return 'Just now';
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inHours < 1) {
    final minute = delta.inMinutes;
    return '$minute min ago';
  }
  if (delta.inDays < 1) {
    final hour = delta.inHours;
    return '$hour hr ago';
  }
  final day = delta.inDays;
  return '$day day${day > 1 ? 's' : ''} ago';
}
