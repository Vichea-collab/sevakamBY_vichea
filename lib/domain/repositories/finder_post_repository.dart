import '../entities/provider_portal.dart';
import '../entities/pagination.dart';

abstract class FinderPostRepository {
  void setBearerToken(String token);

  Future<PaginatedResult<FinderPostItem>> loadFinderRequests({
    int page = 1,
    int limit = 10,
  });

  Future<FinderPostItem> createFinderRequest({
    required String category,
    required List<String> services,
    required String location,
    required String message,
    required DateTime preferredDate,
  });

  Future<FinderPostItem> updateFinderRequest({
    required String postId,
    required String category,
    required List<String> services,
    required String location,
    required String message,
    required DateTime preferredDate,
  });

  Future<void> deleteFinderRequest({required String postId});
}
