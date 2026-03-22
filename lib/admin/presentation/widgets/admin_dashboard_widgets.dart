part of '../pages/admin_dashboard_page.dart';

const Color _adminFieldBorderColor = Color(0xFFD3DDEF);
const Color _adminFieldFillColor = Color(0xFFF8FAFF);

InputDecoration _adminFieldDecoration({
  String? labelText,
  String? hintText,
  bool dense = false,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: _adminFieldFillColor,
    isDense: dense,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _adminFieldBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
    ),
  );
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

String _toMoney(num value) => '\$${value.toStringAsFixed(2)}';

int _intValue(num? value) => value?.toInt() ?? 0;

double _numValue(num? value) => value?.toDouble() ?? 0;

String _prettyStatus(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'Unknown';
  return normalized
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _prettyPostType(String value) {
  return switch (value.trim().toLowerCase()) {
    'provider_offer' => 'Provider Offer',
    'finder_request' => 'Finder Request',
    _ => 'Post',
  };
}

String _prettyRole(String value) {
  return switch (value.trim().toLowerCase()) {
    'finder' => 'Finder',
    'provider' => 'Provider',
    'admin' => 'Admin',
    _ => _prettyStatus(value),
  };
}

String _prettyBroadcastType(String value) {
  return switch (value.trim().toLowerCase()) {
    'system' => 'System',
    'promotion' => 'Promotion',
    _ => _prettyStatus(value),
  };
}

Color _statusColor(String status) {
  return switch (status.trim().toLowerCase()) {
    'completed' => AppColors.success,
    'booked' => AppColors.warning,
    'on_the_way' => AppColors.primary,
    'started' => const Color(0xFF0284C7),
    'cancelled' => AppColors.danger,
    'declined' => const Color(0xFFE11D48),
    'waiting_on_admin' => AppColors.warning,
    'waiting_on_user' => AppColors.primary,
    'resolved' => AppColors.success,
    'closed' => const Color(0xFF64748B),
    'active' => AppColors.success,
    'scheduled' => AppColors.warning,
    'expired' => AppColors.danger,
    'inactive' => const Color(0xFF64748B),
    _ => AppColors.textSecondary,
  };
}

Color _postTypeColor(String type) {
  return switch (type.trim().toLowerCase()) {
    'provider_offer' => AppColors.primary,
    'finder_request' => const Color(0xFF14B8A6),
    _ => AppColors.textSecondary,
  };
}

Color _undoStateColor(String state) {
  return switch (state.trim().toLowerCase()) {
    'available' => AppColors.success,
    'used' => const Color(0xFF64748B),
    'expired' => AppColors.warning,
    _ => AppColors.textSecondary,
  };
}

String _prettyUndoActionType(String actionType) {
  final value = actionType.trim().toLowerCase();
  switch (value) {
    case 'user_status':
      return 'User status';
    case 'order_status':
      return 'Order status';
    case 'post_status':
      return 'Post status';
    case 'ticket_status':
      return 'Ticket status';
    case 'service_active':
      return 'Service state';
    default:
      return _prettyStatus(value);
  }
}
