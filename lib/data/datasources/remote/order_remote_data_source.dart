import '../../network/backend_api_client.dart';
import '../../../domain/entities/pagination.dart';

class OrderRemoteDataSource {
  static const int _defaultPageSize = 10;

  final BackendApiClient _apiClient;

  const OrderRemoteDataSource(this._apiClient);

  void setBearerToken(String token) {
    _apiClient.setBearerToken(token);
  }

  Future<Map<String, dynamic>> createFinderOrder(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postJson('/api/orders', payload);
    return _safeMap(response['data']);
  }

  Future<PaginatedResult<Map<String, dynamic>>> fetchFinderOrders({
    int page = 1,
    int limit = _defaultPageSize,
  }) async {
    final response = await _apiClient.getJson(
      '/api/orders/finder?page=$page&limit=$limit',
    );
    final items = _safeList(response['data']);
    final pagination = PaginationMeta.fromMap(
      _safeMap(response['pagination']),
      fallbackPage: page,
      fallbackLimit: limit,
      fallbackTotalItems: items.length,
    );
    return PaginatedResult(items: items, pagination: pagination);
  }

  Future<PaginatedResult<Map<String, dynamic>>> fetchProviderOrders({
    int page = 1,
    int limit = _defaultPageSize,
  }) async {
    final response = await _apiClient.getJson(
      '/api/orders/provider?page=$page&limit=$limit',
    );
    final items = _safeList(response['data']);
    final pagination = PaginationMeta.fromMap(
      _safeMap(response['pagination']),
      fallbackPage: page,
      fallbackLimit: limit,
      fallbackTotalItems: items.length,
    );
    return PaginatedResult(items: items, pagination: pagination);
  }

  Future<List<Map<String, dynamic>>> fetchSavedAddresses() async {
    final response = await _apiClient.getJson('/api/users/addresses');
    return _safeList(response['data']);
  }

  Future<Map<String, dynamic>> createSavedAddress(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postJson('/api/users/addresses', payload);
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> createKhqrPaymentSession({
    required String orderId,
  }) async {
    final response = await _apiClient.postJson('/api/payments/khqr/create', {
      'orderId': orderId,
    });
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> verifyKhqrPayment({
    required String orderId,
    String transactionId = '',
  }) async {
    final body = <String, dynamic>{'orderId': orderId};
    if (transactionId.trim().isNotEmpty) {
      body['transactionId'] = transactionId.trim();
    }
    final response = await _apiClient.postJson(
      '/api/payments/khqr/verify',
      body,
    );
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    required String actorRole,
  }) async {
    final response = await _apiClient.putJson('/api/orders/$orderId/status', {
      'status': status,
      'actorRole': actorRole,
    });
    return _safeMap(response['data']);
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
    return value.whereType<Map>().map((item) => _safeMap(item)).toList();
  }
}
