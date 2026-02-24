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

  Future<Map<String, dynamic>> quoteFinderOrder(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postJson('/api/orders/quote', payload);
    return _safeMap(response['data']);
  }

  Future<PaginatedResult<Map<String, dynamic>>> fetchFinderOrders({
    int page = 1,
    int limit = _defaultPageSize,
    List<String> statuses = const <String>[],
  }) async {
    final statusQuery = statuses
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final path = statusQuery.isEmpty
        ? '/api/orders/finder?page=$page&limit=$limit'
        : '/api/orders/finder?page=$page&limit=$limit&status=${Uri.encodeQueryComponent(statusQuery.join(','))}';
    final response = await _apiClient.getJson(
      path,
      timeout: const Duration(seconds: 12),
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
    List<String> statuses = const <String>[],
  }) async {
    final statusQuery = statuses
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final path = statusQuery.isEmpty
        ? '/api/orders/provider?page=$page&limit=$limit'
        : '/api/orders/provider?page=$page&limit=$limit&status=${Uri.encodeQueryComponent(statusQuery.join(','))}';
    final response = await _apiClient.getJson(
      path,
      timeout: const Duration(seconds: 12),
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

  Future<Map<String, dynamic>> submitFinderOrderReview({
    required String orderId,
    required double rating,
    String comment = '',
  }) async {
    final response = await _apiClient.postJson('/api/orders/$orderId/review', {
      'rating': rating,
      'comment': comment,
    });
    return _safeMap(response['data']);
  }

  Future<Map<String, dynamic>> fetchProviderReviewSummary({
    required String providerUid,
    int limit = 20,
  }) async {
    final response = await _apiClient.getJson(
      '/api/orders/provider/$providerUid/reviews?limit=$limit',
    );
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
