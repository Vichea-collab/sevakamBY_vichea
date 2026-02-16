import '../../domain/entities/admin_models.dart';
import '../network/admin_api_client.dart';

class AdminRemoteDataSource {
  static const int defaultPageSize = 10;

  final AdminApiClient _apiClient;

  AdminRemoteDataSource(this._apiClient);

  void setBearerToken(String token) {
    _apiClient.setBearerToken(token);
  }

  Future<bool> verifyAccess() async {
    try {
      await _apiClient.getJson('/api/admin/overview');
      return true;
    } on AdminApiException {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchOverview() async {
    final response = await _apiClient.getJson('/api/admin/overview');
    return _safeMap(response['data']);
  }

  Future<AdminPage<Map<String, dynamic>>> fetchUsers({
    int page = 1,
    int limit = defaultPageSize,
  }) {
    return _fetchPaginated('/api/admin/users', page: page, limit: limit);
  }

  Future<AdminPage<Map<String, dynamic>>> fetchOrders({
    int page = 1,
    int limit = defaultPageSize,
  }) {
    return _fetchPaginated('/api/admin/orders', page: page, limit: limit);
  }

  Future<AdminPage<Map<String, dynamic>>> fetchPosts({
    int page = 1,
    int limit = defaultPageSize,
  }) {
    return _fetchPaginated('/api/admin/posts', page: page, limit: limit);
  }

  Future<AdminPage<Map<String, dynamic>>> fetchTickets({
    int page = 1,
    int limit = defaultPageSize,
  }) {
    return _fetchPaginated('/api/admin/tickets', page: page, limit: limit);
  }

  Future<AdminPage<Map<String, dynamic>>> fetchServices({
    int page = 1,
    int limit = defaultPageSize,
  }) {
    return _fetchPaginated('/api/admin/services', page: page, limit: limit);
  }

  Future<AdminPage<Map<String, dynamic>>> _fetchPaginated(
    String endpoint, {
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.getJson(
      '$endpoint?page=$page&limit=$limit',
    );
    return AdminPage(
      items: _safeList(response['data']),
      pagination: AdminPagination.fromMap(
        _safeMap(response['pagination']),
        fallbackPage: page,
        fallbackLimit: limit,
      ),
    );
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _safeList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map>().map(_safeMap).toList(growable: false);
  }
}
