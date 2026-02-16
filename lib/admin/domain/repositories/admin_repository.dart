import '../entities/admin_models.dart';

abstract class AdminRepository {
  void setBearerToken(String token);

  Future<bool> verifyAccess();
  Future<AdminOverview> fetchOverview();

  Future<AdminPage<AdminUserRow>> fetchUsers({int page = 1, int limit = 10});
  Future<AdminPage<AdminOrderRow>> fetchOrders({int page = 1, int limit = 10});
  Future<AdminPage<AdminPostRow>> fetchPosts({int page = 1, int limit = 10});
  Future<AdminPage<AdminTicketRow>> fetchTickets({
    int page = 1,
    int limit = 10,
  });
  Future<AdminPage<AdminServiceRow>> fetchServices({
    int page = 1,
    int limit = 10,
  });
}
