import '../../domain/entities/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remoteDataSource;

  AdminRepositoryImpl(this._remoteDataSource);

  @override
  void setBearerToken(String token) {
    _remoteDataSource.setBearerToken(token);
  }

  @override
  Future<bool> verifyAccess() {
    return _remoteDataSource.verifyAccess();
  }

  @override
  Future<AdminOverview> fetchOverview() async {
    final row = await _remoteDataSource.fetchOverview();
    return AdminOverview.fromMap(row);
  }

  @override
  Future<AdminReadBudget> fetchReadBudget() async {
    final row = await _remoteDataSource.fetchReadBudget();
    return AdminReadBudget.fromMap(row);
  }

  @override
  Future<AdminGlobalSearchResult> globalSearch({
    required String query,
    int limit = 5,
  }) async {
    final row = await _remoteDataSource.globalSearch(
      query: query,
      limit: limit,
    );
    return AdminGlobalSearchResult.fromMap(row);
  }

  @override
  Future<AdminAnalytics> fetchAnalytics({
    int days = 14,
    int compareDays = 14,
  }) async {
    final row = await _remoteDataSource.fetchAnalytics(
      days: days,
      compareDays: compareDays,
    );
    return AdminAnalytics.fromMap(row);
  }

  @override
  Future<AdminPage<AdminUserRow>> fetchUsers({
    int page = 1,
    int limit = 10,
    String query = '',
    String role = '',
  }) async {
    final result = await _remoteDataSource.fetchUsers(
      page: page,
      limit: limit,
      query: query,
      role: role,
    );
    return AdminPage(
      items: result.items.map(AdminUserRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminPage<AdminOrderRow>> fetchOrders({
    int page = 1,
    int limit = 10,
    String query = '',
    String status = '',
  }) async {
    final result = await _remoteDataSource.fetchOrders(
      page: page,
      limit: limit,
      query: query,
      status: status,
    );
    return AdminPage(
      items: result.items.map(AdminOrderRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminPage<AdminPostRow>> fetchPosts({
    int page = 1,
    int limit = 10,
    String query = '',
    String type = '',
  }) async {
    final result = await _remoteDataSource.fetchPosts(
      page: page,
      limit: limit,
      query: query,
      type: type,
    );
    return AdminPage(
      items: result.items.map(AdminPostRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminPage<AdminTicketRow>> fetchTickets({
    int page = 1,
    int limit = 10,
    String query = '',
    String status = '',
  }) async {
    final result = await _remoteDataSource.fetchTickets(
      page: page,
      limit: limit,
      query: query,
      status: status,
    );
    return AdminPage(
      items: result.items.map(AdminTicketRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminPage<AdminServiceRow>> fetchServices({
    int page = 1,
    int limit = 10,
    String query = '',
    String active = '',
  }) async {
    final result = await _remoteDataSource.fetchServices(
      page: page,
      limit: limit,
      query: query,
      active: active,
    );
    return AdminPage(
      items: result.items.map(AdminServiceRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminPage<AdminUndoHistoryRow>> fetchUndoHistory({
    int page = 1,
    int limit = 10,
    String query = '',
    String state = '',
  }) async {
    final result = await _remoteDataSource.fetchUndoHistory(
      page: page,
      limit: limit,
      query: query,
      state: state,
    );
    return AdminPage(
      items: result.items
          .map(AdminUndoHistoryRow.fromMap)
          .toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminActionResult> updateUserStatus({
    required String userId,
    required bool active,
    required String reason,
  }) async {
    final row = await _remoteDataSource.updateUserStatus(
      userId: userId,
      active: active,
      reason: reason,
    );
    return AdminActionResult.fromMap(row);
  }

  @override
  Future<AdminActionResult> updateOrderStatus({
    required String orderId,
    required String status,
    required String reason,
  }) async {
    final row = await _remoteDataSource.updateOrderStatus(
      orderId: orderId,
      status: status,
      reason: reason,
    );
    return AdminActionResult.fromMap(row);
  }

  @override
  Future<AdminActionResult> updatePostStatus({
    required String sourceCollection,
    required String postId,
    required String status,
    required String reason,
  }) async {
    final row = await _remoteDataSource.updatePostStatus(
      sourceCollection: sourceCollection,
      postId: postId,
      status: status,
      reason: reason,
    );
    return AdminActionResult.fromMap(row);
  }

  @override
  Future<AdminActionResult> updateTicketStatus({
    required String userUid,
    required String ticketId,
    required String status,
    required String reason,
  }) async {
    final row = await _remoteDataSource.updateTicketStatus(
      userUid: userUid,
      ticketId: ticketId,
      status: status,
      reason: reason,
    );
    return AdminActionResult.fromMap(row);
  }

  @override
  Future<AdminActionResult> updateServiceActive({
    required String serviceId,
    required bool active,
    required String reason,
  }) async {
    final row = await _remoteDataSource.updateServiceActive(
      serviceId: serviceId,
      active: active,
      reason: reason,
    );
    return AdminActionResult.fromMap(row);
  }

  @override
  Future<void> undoAction({required String undoToken}) {
    return _remoteDataSource.undoAction(undoToken: undoToken);
  }
}
