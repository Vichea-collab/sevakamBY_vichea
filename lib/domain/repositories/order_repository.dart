import '../entities/order.dart';
import '../entities/pagination.dart';
import '../entities/provider_portal.dart';

abstract class OrderRepository {
  void setBearerToken(String token);

  Future<BookingPriceQuote> quoteFinderOrder(BookingDraft draft);
  Future<OrderItem> createFinderOrder(BookingDraft draft);
  Future<PaginatedResult<OrderItem>> fetchFinderOrders({
    int page = 1,
    int limit = 10,
  });
  Future<PaginatedResult<ProviderOrderItem>> fetchProviderOrders({
    int page = 1,
    int limit = 10,
  });
  Future<List<HomeAddress>> fetchSavedAddresses();
  Future<HomeAddress> createSavedAddress({required HomeAddress address});
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
  Future<ProviderOrderItem> updateProviderOrderStatus({
    required String orderId,
    required ProviderOrderState state,
  });
}
