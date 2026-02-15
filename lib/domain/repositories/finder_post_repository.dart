import '../entities/provider_portal.dart';

abstract class FinderPostRepository {
  void setBearerToken(String token);

  Future<List<FinderPostItem>> loadFinderRequests();

  Future<FinderPostItem> createFinderRequest({
    required String category,
    required String service,
    required String location,
    required String message,
    required DateTime preferredDate,
  });
}
