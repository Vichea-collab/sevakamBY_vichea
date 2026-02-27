import '../entities/order.dart';
import '../entities/pagination.dart';
import '../entities/provider_profile.dart';
import '../entities/provider_portal.dart';

abstract class OrderRepository {
  void setBearerToken(String token);

  Future<BookingPriceQuote> quoteFinderOrder(BookingDraft draft);
  Future<OrderItem> createFinderOrder(BookingDraft draft);
  Future<PaginatedResult<OrderItem>> fetchFinderOrders({
    int page = 1,
    int limit = 10,
    List<String> statuses = const <String>[],
  });
  Future<PaginatedResult<ProviderOrderItem>> fetchProviderOrders({
    int page = 1,
    int limit = 10,
    List<String> statuses = const <String>[],
  });
  Future<List<HomeAddress>> fetchSavedAddresses();
  Future<HomeAddress> createSavedAddress({required HomeAddress address});
  Future<HomeAddress> updateSavedAddress({required HomeAddress address});
  Future<void> deleteSavedAddress({required String addressId});
  Future<KhqrPaymentSession> createKhqrPaymentSession({
    required String orderId,
  });
  Future<KhqrPaymentVerification> verifyKhqrPayment({
    required String orderId,
    String transactionId,
  });
  Future<OrderItem> updateFinderOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
  Future<OrderItem> submitFinderOrderReview({
    required String orderId,
    required double rating,
    String comment,
  });
  Future<ProviderReviewSummary> fetchProviderReviewSummary({
    required String providerUid,
    int limit,
  });
  Future<ProviderOrderItem> updateProviderOrderStatus({
    required String orderId,
    required ProviderOrderState state,
  });
}
