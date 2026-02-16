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
  Future<AdminPage<AdminUserRow>> fetchUsers({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _remoteDataSource.fetchUsers(page: page, limit: limit);
    return AdminPage(
      items: result.items.map(AdminUserRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminPage<AdminOrderRow>> fetchOrders({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _remoteDataSource.fetchOrders(
      page: page,
      limit: limit,
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
  }) async {
    final result = await _remoteDataSource.fetchPosts(page: page, limit: limit);
    return AdminPage(
      items: result.items.map(AdminPostRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<AdminPage<AdminTicketRow>> fetchTickets({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _remoteDataSource.fetchTickets(
      page: page,
      limit: limit,
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
  }) async {
    final result = await _remoteDataSource.fetchServices(
      page: page,
      limit: limit,
    );
    return AdminPage(
      items: result.items.map(AdminServiceRow.fromMap).toList(growable: false),
      pagination: result.pagination,
    );
  }
}
