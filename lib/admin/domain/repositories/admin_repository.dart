import '../entities/admin_models.dart';

abstract class AdminRepository {
  void setBearerToken(String token);

  Future<bool> verifyAccess();
  Future<AdminOverview> fetchOverview();
  Future<AdminReadBudget> fetchReadBudget();
  Future<AdminGlobalSearchResult> globalSearch({
    required String query,
    int limit = 5,
  });

  Future<AdminPage<AdminUserRow>> fetchUsers({
    int page = 1,
    int limit = 10,
    String query = '',
    String role = '',
  });
  Future<AdminPage<AdminOrderRow>> fetchOrders({
    int page = 1,
    int limit = 10,
    String query = '',
    String status = '',
  });
  Future<AdminPage<AdminPostRow>> fetchPosts({
    int page = 1,
    int limit = 10,
    String query = '',
    String type = '',
  });
  Future<AdminPage<AdminTicketRow>> fetchTickets({
    int page = 1,
    int limit = 10,
    String query = '',
    String status = '',
  });
  Future<AdminPage<AdminTicketMessageRow>> fetchTicketMessages({
    required String userUid,
    required String ticketId,
    int page = 1,
    int limit = 10,
  });
  Future<AdminTicketMessageRow> sendTicketMessage({
    required String userUid,
    required String ticketId,
    required String text,
  });
  Future<AdminPage<AdminServiceRow>> fetchServices({
    int page = 1,
    int limit = 10,
    String query = '',
    String active = '',
  });
  Future<AdminPage<AdminBroadcastRow>> fetchBroadcasts({
    int page = 1,
    int limit = 10,
    String query = '',
    String type = '',
    String status = '',
    String role = '',
  });
  Future<AdminPage<AdminUndoHistoryRow>> fetchUndoHistory({
    int page = 1,
    int limit = 10,
    String query = '',
    String state = '',
  });

  Future<AdminActionResult> updateUserStatus({
    required String userId,
    required bool active,
    required String reason,
  });
  Future<AdminActionResult> updateOrderStatus({
    required String orderId,
    required String status,
    required String reason,
  });
  Future<AdminActionResult> updatePostStatus({
    required String sourceCollection,
    required String postId,
    required String status,
    required String reason,
  });
  Future<AdminActionResult> updateTicketStatus({
    required String userUid,
    required String ticketId,
    required String status,
    required String reason,
  });
  Future<AdminActionResult> updateServiceActive({
    required String serviceId,
    required bool active,
    required String reason,
  });
  Future<AdminBroadcastRow> createBroadcast({
    required String type,
    required String title,
    required String message,
    required List<String> targetRoles,
    required bool active,
    String promoCode,
    String discountType,
    double discountValue,
    double minSubtotal,
    double maxDiscount,
    int usageLimit,
    String? startAtIso,
    String? endAtIso,
  });
  Future<AdminBroadcastRow> updateBroadcastActive({
    required String broadcastId,
    required bool active,
  });
  Future<void> undoAction({required String undoToken});
}
