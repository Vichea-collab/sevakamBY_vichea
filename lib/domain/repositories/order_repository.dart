import '../entities/order.dart';
import '../entities/provider_portal.dart';

abstract class OrderRepository {
  void setBearerToken(String token);

  Future<OrderItem> createFinderOrder(BookingDraft draft);
  Future<List<OrderItem>> fetchFinderOrders();
  Future<List<ProviderOrderItem>> fetchProviderOrders();
  Future<OrderItem> updateFinderOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
  Future<ProviderOrderItem> updateProviderOrderStatus({
    required String orderId,
    required ProviderOrderState state,
  });
}
