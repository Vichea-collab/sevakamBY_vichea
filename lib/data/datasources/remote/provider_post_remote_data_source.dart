import '../../../domain/entities/provider_portal.dart';
import '../../../domain/entities/pagination.dart';
import '../../network/backend_api_client.dart';

class ProviderPostRemoteDataSource {
  static const int _defaultPageSize = 10;

  final BackendApiClient _apiClient;

  const ProviderPostRemoteDataSource(this._apiClient);

  void setBearerToken(String token) {
    _apiClient.setBearerToken(token);
  }

  Future<PaginatedResult<ProviderPostItem>> fetchProviderPosts({
    int page = 1,
    int limit = _defaultPageSize,
  }) async {
    final response = await _apiClient.getJson(
      '/api/posts/provider-offers?page=$page&limit=$limit',
    );
    final data = response['data'];
    final items = data is! List
        ? const <ProviderPostItem>[]
        : data.whereType<Map>().map(_mapToProviderPost).toList();
    final pagination = PaginationMeta.fromMap(
      _safeMap(response['pagination']),
      fallbackPage: page,
      fallbackLimit: limit,
      fallbackTotalItems: items.length,
    );
    return PaginatedResult(items: items, pagination: pagination);
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
      providerType: _providerType(row['providerType']),
      providerCompanyName: (row['providerCompanyName'] ?? '').toString(),
      providerMaxWorkers: _providerMaxWorkers(
        row['providerMaxWorkers'],
        _providerType(row['providerType']),
      ),
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

  String _providerType(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    if (normalized == 'company') return 'company';
    return 'individual';
  }

  int _providerMaxWorkers(dynamic value, String providerType) {
    if (providerType != 'company') return 1;
    if (value is num && value > 0) return value.toInt();
    final parsed = int.tryParse((value ?? '').toString().trim());
    if (parsed != null && parsed > 0) return parsed;
    return 1;
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
