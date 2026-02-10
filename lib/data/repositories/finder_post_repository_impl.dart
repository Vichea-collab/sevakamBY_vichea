import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/finder_post_repository.dart';
import '../datasources/remote/finder_post_remote_data_source.dart';
import '../mock/mock_data.dart';

class FinderPostRepositoryImpl implements FinderPostRepository {
  final FinderPostRemoteDataSource _remoteDataSource;

  const FinderPostRepositoryImpl({
    required FinderPostRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  void setBearerToken(String token) {
    _remoteDataSource.setBearerToken(token);
  }

  @override
  Future<List<FinderPostItem>> loadFinderRequests() async {
    try {
      final remote = await _remoteDataSource.fetchFinderRequests();
      if (remote.isNotEmpty) return remote;
      return List<FinderPostItem>.from(MockData.finderPosts);
    } catch (_) {
      return List<FinderPostItem>.from(MockData.finderPosts);
    }
  }

  @override
  Future<FinderPostItem> createFinderRequest({
    required String category,
    required String service,
    required String location,
    required String message,
    required DateTime preferredDate,
    required String fallbackClientName,
  }) async {
    try {
      return await _remoteDataSource.createFinderRequest(
        category: category,
        service: service,
        location: location,
        message: message,
        preferredDate: preferredDate,
      );
    } catch (_) {
      return FinderPostItem(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        clientName: fallbackClientName.isEmpty
            ? 'Finder User'
            : fallbackClientName,
        message: message,
        timeLabel: 'Just now',
        category: category,
        service: service,
        location: location,
        avatarPath: 'assets/images/profile.jpg',
        preferredDate: preferredDate,
      );
    }
  }
}
