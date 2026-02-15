import '../../../domain/entities/provider_portal.dart';
import '../../network/backend_api_client.dart';

class ProviderPostRemoteDataSource {
  final BackendApiClient _apiClient;

  const ProviderPostRemoteDataSource(this._apiClient);

  void setBearerToken(String token) {
    _apiClient.setBearerToken(token);
  }

  Future<List<ProviderPostItem>> fetchProviderPosts() async {
    final response = await _apiClient.getJson('/api/posts/provider-offers');
    final data = response['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map(_mapToProviderPost).toList();
  }

  Future<ProviderPostItem> createProviderPost({
    required String category,
    required String service,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  }) async {
    final response = await _apiClient.postJson('/api/posts/provider-offers', {
      'category': category,
      'service': service,
      'area': area,
      'details': details,
      'ratePerHour': ratePerHour,
      'availableNow': availableNow,
    });
    return _mapToProviderPost(_safeMap(response['data']));
  }

  ProviderPostItem _mapToProviderPost(Map<dynamic, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final createdAt = _parseDate(row['createdAt']);
    return ProviderPostItem(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      providerUid: (row['providerUid'] ?? '').toString(),
      providerName: (row['providerName'] ?? 'Service Provider').toString(),
      category: (row['category'] ?? '').toString(),
      service: (row['service'] ?? '').toString(),
      area: (row['area'] ?? '').toString(),
      details: (row['details'] ?? '').toString(),
      ratePerHour: _toRate(row['ratePerHour']),
      availableNow: row['availableNow'] == true,
      timeLabel: _timeLabel(createdAt),
      avatarPath: 'assets/images/profile.jpg',
    );
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  double _toRate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toLocal();
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    }
    return null;
  }

  String _timeLabel(DateTime? date) {
    if (date == null) return 'Just now';
    final delta = DateTime.now().difference(date);
    if (delta.inMinutes < 1) return 'Just now';
    if (delta.inHours < 1) return '${delta.inMinutes} mins ago';
    if (delta.inDays < 1) return '${delta.inHours} hrs ago';
    return '${delta.inDays} days ago';
  }
}
