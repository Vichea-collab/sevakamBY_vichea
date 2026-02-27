import '../../domain/entities/provider_portal.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/repositories/finder_post_repository.dart';
import '../datasources/remote/finder_post_remote_data_source.dart';

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
  Future<PaginatedResult<FinderPostItem>> loadFinderRequests({
    int page = 1,
    int limit = 10,
  }) async {
    return _remoteDataSource.fetchFinderRequests(page: page, limit: limit);
  }

  @override
  Future<FinderPostItem> createFinderRequest({
    required String category,
    required List<String> services,
    required String location,
    required String message,
    required DateTime preferredDate,
  }) async {
    return _remoteDataSource.createFinderRequest(
      category: category,
      services: services,
      location: location,
      message: message,
      preferredDate: preferredDate,
    );
  }

  @override
  Future<FinderPostItem> updateFinderRequest({
    required String postId,
    required String category,
    required List<String> services,
    required String location,
    required String message,
    required DateTime preferredDate,
  }) async {
    return _remoteDataSource.updateFinderRequest(
      postId: postId,
      category: category,
      services: services,
      location: location,
      message: message,
      preferredDate: preferredDate,
    );
  }

  @override
  Future<void> deleteFinderRequest({required String postId}) async {
    await _remoteDataSource.deleteFinderRequest(postId: postId);
  }
}
