import '../../network/backend_api_client.dart';

class OrderRemoteDataSource {
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

  Future<List<Map<String, dynamic>>> fetchFinderOrders() async {
    final response = await _apiClient.getJson('/api/orders/finder');
    return _safeList(response['data']);
  }

  Future<List<Map<String, dynamic>>> fetchProviderOrders() async {
    final response = await _apiClient.getJson('/api/orders/provider');
    return _safeList(response['data']);
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
