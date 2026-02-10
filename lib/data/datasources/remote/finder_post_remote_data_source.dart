import '../../../domain/entities/provider_portal.dart';
import '../../network/backend_api_client.dart';

class FinderPostRemoteDataSource {
  final BackendApiClient _apiClient;

  const FinderPostRemoteDataSource(this._apiClient);

  void setBearerToken(String token) {
    _apiClient.setBearerToken(token);
  }

  Future<List<FinderPostItem>> fetchFinderRequests() async {
    final response = await _apiClient.getJson('/api/posts/finder-requests');
    final data = response['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map(_mapToFinderPost).toList();
  }

  Future<FinderPostItem> createFinderRequest({
    required String category,
    required String service,
    required String location,
    required String message,
    required DateTime preferredDate,
  }) async {
    final response = await _apiClient.postJson('/api/posts/finder-requests', {
      'category': category,
      'service': service,
      'location': location,
      'message': message,
      'preferredDate': preferredDate.toIso8601String(),
    });
    return _mapToFinderPost(_safeMap(response['data']));
  }

  FinderPostItem _mapToFinderPost(Map<dynamic, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final createdAt = _parseDate(row['createdAt']);
    return FinderPostItem(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      clientName: (row['clientName'] ?? 'Finder User').toString(),
      message: (row['message'] ?? '').toString(),
      timeLabel: _timeLabel(createdAt),
      category: (row['category'] ?? '').toString(),
      service: (row['service'] ?? '').toString(),
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
}
