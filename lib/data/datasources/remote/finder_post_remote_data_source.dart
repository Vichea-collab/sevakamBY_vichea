import '../../../domain/entities/provider_portal.dart';
import '../../../domain/entities/pagination.dart';
import '../../network/backend_api_client.dart';

class FinderPostRemoteDataSource {
  static const int _defaultPageSize = 10;

  final BackendApiClient _apiClient;

  const FinderPostRemoteDataSource(this._apiClient);

  void setBearerToken(String token) {
    _apiClient.setBearerToken(token);
  }

  Future<PaginatedResult<FinderPostItem>> fetchFinderRequests({
    int page = 1,
    int limit = _defaultPageSize,
  }) async {
    final response = await _apiClient.getJson(
      '/api/posts/finder-requests?page=$page&limit=$limit',
    );
    final data = response['data'];
    final items = data is! List
        ? const <FinderPostItem>[]
        : data.whereType<Map>().map(_mapToFinderPost).toList();
    final pagination = PaginationMeta.fromMap(
      _safeMap(response['pagination']),
      fallbackPage: page,
      fallbackLimit: limit,
      fallbackTotalItems: items.length,
    );
    return PaginatedResult(items: items, pagination: pagination);
  }

  Future<FinderPostItem> createFinderRequest({
    required String category,
    required List<String> services,
    required String location,
    required String message,
    required DateTime preferredDate,
  }) async {
    final safeServices = services
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final response = await _apiClient.postJson('/api/posts/finder-requests', {
      'category': category,
      'service': safeServices.isNotEmpty ? safeServices.first : '',
      'services': safeServices,
      'location': location,
      'message': message,
      'preferredDate': preferredDate.toIso8601String(),
    });
    return _mapToFinderPost(_safeMap(response['data']));
  }

  FinderPostItem _mapToFinderPost(Map<dynamic, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final createdAt = _parseDate(row['createdAt']);
    final services = _parseServices(row['services']);
    final primaryService = (row['service'] ?? '').toString().trim();
    return FinderPostItem(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      finderUid: (row['finderUid'] ?? '').toString(),
      clientName: (row['clientName'] ?? 'Finder User').toString(),
      message: (row['message'] ?? '').toString(),
      timeLabel: _timeLabel(createdAt),
      category: (row['category'] ?? '').toString(),
      service: primaryService.isNotEmpty
          ? primaryService
          : (services.isNotEmpty ? services.first : ''),
      services: services,
      location: (row['location'] ?? '').toString(),
      avatarPath: 'assets/images/profile.jpg',
      preferredDate: _parseDate(row['preferredDate']),
    );
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
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

  List<String> _parseServices(dynamic value) {
    if (value is! List) return const <String>[];
    final parsed = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    parsed.sort();
    return parsed;
  }
}
