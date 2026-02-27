import '../entities/provider_portal.dart';
import '../entities/pagination.dart';

abstract class ProviderPostRepository {
  void setBearerToken(String token);

  Future<PaginatedResult<ProviderPostItem>> loadProviderPosts({
    int page = 1,
    int limit = 10,
  });

  Future<ProviderPostItem> createProviderPost({
    required String category,
    required List<String> services,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  });

  Future<ProviderPostItem> updateProviderPost({
    required String postId,
    required String category,
    required List<String> services,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  });

  Future<void> deleteProviderPost({required String postId});
}
