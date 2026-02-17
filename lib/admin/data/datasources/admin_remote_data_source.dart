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

  Future<Map<String, dynamic>> fetchReadBudget() async {
    final response = await _apiClient.getJson('/api/admin/read-budget');
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> globalSearch({
    required String query,
    int limit = 5,
  }) async {
    final path = _buildPath('/api/admin/search', {
      'q': query.trim(),
      'limit': '$limit',
    });
    final response = await _apiClient.getJson(path);
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> fetchAnalytics({
    int days = 14,
    int compareDays = 14,
  }) async {
    final path = _buildPath('/api/admin/analytics', {
      'days': '$days',
      'compareDays': '$compareDays',
    });
    final response = await _apiClient.getJson(path);
    return _safeMap(response['data']);
  }

  Future<AdminPage<Map<String, dynamic>>> fetchUsers({
    int page = 1,
    int limit = defaultPageSize,
    String query = '',
    String role = '',
  }) {
    return _fetchPaginated(
      '/api/admin/users',
      page: page,
      limit: limit,
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (role.trim().isNotEmpty) 'role': role.trim(),
      },
    );
  }

  Future<AdminPage<Map<String, dynamic>>> fetchOrders({
    int page = 1,
    int limit = defaultPageSize,
    String query = '',
    String status = '',
  }) {
    return _fetchPaginated(
      '/api/admin/orders',
      page: page,
      limit: limit,
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
  }

  Future<AdminPage<Map<String, dynamic>>> fetchPosts({
    int page = 1,
    int limit = defaultPageSize,
    String query = '',
    String type = '',
  }) {
    return _fetchPaginated(
      '/api/admin/posts',
      page: page,
      limit: limit,
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (type.trim().isNotEmpty) 'type': type.trim(),
      },
    );
  }

  Future<AdminPage<Map<String, dynamic>>> fetchTickets({
    int page = 1,
    int limit = defaultPageSize,
    String query = '',
    String status = '',
  }) {
    return _fetchPaginated(
      '/api/admin/tickets',
      page: page,
      limit: limit,
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
  }

  Future<AdminPage<Map<String, dynamic>>> fetchServices({
    int page = 1,
    int limit = defaultPageSize,
    String query = '',
    String active = '',
  }) {
    return _fetchPaginated(
      '/api/admin/services',
      page: page,
      limit: limit,
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (active.trim().isNotEmpty) 'active': active.trim(),
      },
    );
  }

  Future<AdminPage<Map<String, dynamic>>> fetchUndoHistory({
    int page = 1,
    int limit = defaultPageSize,
    String query = '',
    String state = '',
  }) {
    return _fetchPaginated(
      '/api/admin/actions/history',
      page: page,
      limit: limit,
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (state.trim().isNotEmpty) 'state': state.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> updateUserStatus({
    required String userId,
    required bool active,
    required String reason,
  }) async {
    final response = await _apiClient.patchJson(
      '/api/admin/users/${Uri.encodeComponent(userId)}/status',
      body: {'active': active, 'reason': reason},
    );
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    required String reason,
  }) async {
    final response = await _apiClient.patchJson(
      '/api/admin/orders/${Uri.encodeComponent(orderId)}/status',
      body: {'status': status, 'reason': reason},
    );
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> updatePostStatus({
    required String sourceCollection,
    required String postId,
    required String status,
    required String reason,
  }) async {
    final response = await _apiClient.patchJson(
      '/api/admin/posts/${Uri.encodeComponent(sourceCollection)}/${Uri.encodeComponent(postId)}/status',
      body: {'status': status, 'reason': reason},
    );
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> updateTicketStatus({
    required String userUid,
    required String ticketId,
    required String status,
    required String reason,
  }) async {
    final response = await _apiClient.patchJson(
      '/api/admin/tickets/${Uri.encodeComponent(userUid)}/${Uri.encodeComponent(ticketId)}/status',
      body: {'status': status, 'reason': reason},
    );
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> updateServiceActive({
    required String serviceId,
    required bool active,
    required String reason,
  }) async {
    final response = await _apiClient.patchJson(
      '/api/admin/services/${Uri.encodeComponent(serviceId)}/active',
      body: {'active': active, 'reason': reason},
    );
    return _safeMap(response['data']);
  }

  Future<void> undoAction({required String undoToken}) async {
    await _apiClient.postJson(
      '/api/admin/actions/undo',
      body: {'undoToken': undoToken},
    );
  }

  Future<AdminPage<Map<String, dynamic>>> _fetchPaginated(
    String endpoint, {
    required int page,
    required int limit,
    Map<String, String>? query,
  }) async {
    final path = _buildPath(endpoint, {
      'page': '$page',
      'limit': '$limit',
      ...?query,
    });
    final response = await _apiClient.getJson(path);
    return AdminPage(
      items: _safeList(response['data']),
      pagination: AdminPagination.fromMap(
        _safeMap(response['pagination']),
        fallbackPage: page,
        fallbackLimit: limit,
      ),
    );
  }

  String _buildPath(String endpoint, Map<String, String> query) {
    final uri = Uri(path: endpoint, queryParameters: query);
    return uri.toString();
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
