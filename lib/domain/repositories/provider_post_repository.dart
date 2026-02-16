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
    required String service,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  });
}
