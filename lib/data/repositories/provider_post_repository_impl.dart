import '../../domain/entities/provider_portal.dart';
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
  Future<List<ProviderPostItem>> loadProviderPosts() async {
    return _remoteDataSource.fetchProviderPosts();
  }

  @override
  Future<ProviderPostItem> createProviderPost({
    required String category,
    required String service,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  }) async {
    return _remoteDataSource.createProviderPost(
      category: category,
      service: service,
      area: area,
      details: details,
      ratePerHour: ratePerHour,
      availableNow: availableNow,
    );
  }
}
