import '../entities/provider_portal.dart';

abstract class ProviderPostRepository {
  void setBearerToken(String token);

  Future<List<ProviderPostItem>> loadProviderPosts();

  Future<ProviderPostItem> createProviderPost({
    required String category,
    required String service,
    required String area,
    required String details,
    required double ratePerHour,
    required bool availableNow,
  });
}
