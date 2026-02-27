import '../../domain/entities/provider_portal.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/repositories/provider_post_repository.dart';
import '../datasources/remote/provider_post_remote_data_source.dart';

class ProviderPostRepositoryImpl implements ProviderPostRepository {
  final ProviderPostRemoteDataSource _remoteDataSource;

  const ProviderPostRepositoryImpl({
    required ProviderPostRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  void setBearerToken(String token) {
    _remoteDataSource.setBearerToken(token);
  }

  @override
  Future<PaginatedResult<ProviderPostItem>> loadProviderPosts({
    int page = 1,
    int limit = 10,
  }) async {
    return _remoteDataSource.fetchProviderPosts(page: page, limit: limit);
  }

  @override
  Future<ProviderPostItem> createProviderPost({
    required String category,
    required List<String> services,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  }) async {
    return _remoteDataSource.createProviderPost(
      category: category,
      services: services,
      area: area,
      details: details,
      ratePerHour: ratePerHour,
      availableNow: availableNow,
    );
  }

  @override
  Future<ProviderPostItem> updateProviderPost({
    required String postId,
    required String category,
    required List<String> services,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  }) async {
    return _remoteDataSource.updateProviderPost(
      postId: postId,
      category: category,
      services: services,
      area: area,
      details: details,
      ratePerHour: ratePerHour,
      availableNow: availableNow,
    );
  }

  @override
  Future<void> deleteProviderPost({required String postId}) async {
    await _remoteDataSource.deleteProviderPost(postId: postId);
  }
}
