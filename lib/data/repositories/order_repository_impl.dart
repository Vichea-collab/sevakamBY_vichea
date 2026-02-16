import 'package:flutter/material.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/provider.dart';
import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/remote/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  const OrderRepositoryImpl({required OrderRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  void setBearerToken(String token) {
    _remoteDataSource.setBearerToken(token);
  }

  @override
  Future<OrderItem> createFinderOrder(BookingDraft draft) async {
    final payload = <String, dynamic>{
      'providerUid': draft.provider.uid.trim(),
      'providerName': draft.provider.name,
      'providerRole': draft.provider.role,
      'providerRating': draft.provider.rating,
      'providerImagePath': draft.provider.imagePath,
      'categoryName': draft.categoryName,
      'serviceName': draft.serviceName,
      'addressLabel': draft.address?.label ?? '',
      'addressStreet': draft.address?.street ?? '',
      'addressCity': draft.address?.city ?? '',
      'addressMapLink': draft.address?.mapLink ?? '',
      'preferredDate': draft.preferredDate.toIso8601String(),
      'preferredTimeSlot': draft.preferredTimeSlot,
      'hours': draft.hours,
      'workers': draft.workers,
      'homeType': _homeTypeToStorage(draft.homeType),
      'paymentMethod': _paymentMethodToStorage(draft.paymentMethod),
      'additionalService': draft.additionalService,
      'finderNote': draft.additionalService,
      'promoCode': draft.promoCode,
      'serviceFields': draft.serviceFields,
      'subtotal': draft.subtotal,
      'processingFee': draft.processingFee,
      'discount': draft.discount,
      'total': draft.total,
    };
    final row = await _remoteDataSource.createFinderOrder(payload);
    return _toFinderOrder(row);
  }

  @override
  Future<PaginatedResult<OrderItem>> fetchFinderOrders({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _remoteDataSource.fetchFinderOrders(
      page: page,
      limit: limit,
    );
    return PaginatedResult(
      items: result.items.map(_toFinderOrder).toList(),
      pagination: result.pagination,
    );
  }

  @override
  Future<PaginatedResult<ProviderOrderItem>> fetchProviderOrders({
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _remoteDataSource.fetchProviderOrders(
      page: page,
      limit: limit,
    );
    return PaginatedResult(
      items: result.items.map(_toProviderOrder).toList(),
      pagination: result.pagination,
    );
  }

  @override
  Future<List<HomeAddress>> fetchSavedAddresses() async {
    final rows = await _remoteDataSource.fetchSavedAddresses();
    if (rows.isEmpty) return const <HomeAddress>[];
    return rows.map(_toHomeAddress).toList(growable: false);
  }

  @override
  Future<HomeAddress> createSavedAddress({required HomeAddress address}) async {
    final row = await _remoteDataSource.createSavedAddress({
      'label': address.label,
      'mapLink': address.mapLink,
      'street': address.street,
      'city': address.city,
      'isDefault': address.isDefault,
    });
    return _toHomeAddress(row);
  }

  @override
  Future<KhqrPaymentSession> createKhqrPaymentSession({
    required String orderId,
  }) async {
    final row = await _remoteDataSource.createKhqrPaymentSession(
      orderId: orderId,
    );
    return KhqrPaymentSession(
      orderId: (row['orderId'] ?? orderId).toString(),
      amount: _toDouble(row['amount']),
      currency: (row['currency'] ?? 'USD').toString(),
      merchantReference: (row['merchantReference'] ?? '').toString(),
      transactionId: (row['transactionId'] ?? '').toString(),
      qrPayload: (row['qrPayload'] ?? '').toString(),
      qrImageUrl: (row['qrImageUrl'] ?? '').toString(),
      paymentStatus: (row['paymentStatus'] ?? 'pending').toString(),
    );
  }

  @override
  Future<KhqrPaymentVerification> verifyKhqrPayment({
    required String orderId,
    String transactionId = '',
  }) async {
    final row = await _remoteDataSource.verifyKhqrPayment(
      orderId: orderId,
      transactionId: transactionId,
    );
    final order = _toFinderOrder(_safeMap(row['order']));
    return KhqrPaymentVerification(
      paid: row['paid'] == true,
      paymentStatus: (row['paymentStatus'] ?? 'pending').toString(),
      status: (row['status'] ?? '').toString(),
      order: order,
    );
  }

  @override
  Future<OrderItem> updateFinderOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final row = await _remoteDataSource.updateOrderStatus(
      orderId: orderId,
      status: _orderStatusToStorage(status),
      actorRole: 'finder',
    );
    return _toFinderOrder(row);
  }

  @override
  Future<ProviderOrderItem> updateProviderOrderStatus({
    required String orderId,
    required ProviderOrderState state,
  }) async {
    final row = await _remoteDataSource.updateOrderStatus(
      orderId: orderId,
      status: _providerStateToStorage(state),
      actorRole: 'provider',
    );
    return _toProviderOrder(row);
  }

  OrderItem _toFinderOrder(Map<String, dynamic> row) {
    final provider = ProviderItem(
      uid: (row['providerUid'] ?? '').toString(),
      name: (row['providerName'] ?? '').toString().trim().isEmpty
          ? 'Service Provider'
          : (row['providerName'] ?? '').toString().trim(),
      role: (row['providerRole'] ?? '').toString().trim().isEmpty
          ? (row['categoryName'] ?? 'General').toString()
          : (row['providerRole'] ?? '').toString(),
      rating: _toDouble(row['providerRating'], fallback: 4.0),
      imagePath: _safeAssetPath(row['providerImagePath']),
      accentColor: const Color(0xFFEAF1FF),
    );
    final address = HomeAddress(
      id: (row['id'] ?? '').toString(),
      label: (row['addressLabel'] ?? 'Home').toString(),
      mapLink: (row['addressMapLink'] ?? '').toString(),
      street: (row['addressStreet'] ?? '').toString(),
      city: (row['addressCity'] ?? '').toString(),
    );
    final preferredDate = _toDateTime(row['preferredDate']);
    final bookedAt = _toDateTime(row['createdAt']);
    final timeline = _timelineFromRow(row, fallbackBookedAt: bookedAt);
    return OrderItem(
      id: (row['id'] ?? '').toString(),
      provider: provider,
      serviceName: (row['serviceName'] ?? 'Service').toString(),
      address: address,
      hours: _toInt(row['hours'], fallback: 1),
      workers: _toInt(row['workers'], fallback: 1),
      homeType: _homeTypeFromStorage((row['homeType'] ?? '').toString()),
      additionalService: (row['additionalService'] ?? '').toString(),
      bookedAt: bookedAt,
      scheduledAt: preferredDate,
      timeRange: (row['preferredTimeSlot'] ?? '').toString(),
      paymentMethod: _paymentMethodFromStorage(
        (row['paymentMethod'] ?? '').toString(),
      ),
      subtotal: _toDouble(row['subtotal']),
      processingFee: _toDouble(row['processingFee']),
      discount: _toDouble(row['discount']),
      status: _orderStatusFromStorage((row['status'] ?? '').toString()),
      timeline: timeline,
    );
  }

  ProviderOrderItem _toProviderOrder(Map<String, dynamic> row) {
    final preferredDate = _toDateTime(row['preferredDate']);
    final timeline = _timelineFromRow(
      row,
      fallbackBookedAt: _toDateTimeOrNull(row['createdAt']),
    );
    final inputs = <String, String>{};
    final rawInputs = row['serviceFields'];
    if (rawInputs is Map) {
      for (final entry in rawInputs.entries) {
        inputs[entry.key.toString()] = (entry.value ?? '').toString();
      }
    }
    final address =
        '${(row['addressStreet'] ?? '').toString()}, ${(row['addressCity'] ?? '').toString()}'
            .trim();
    return ProviderOrderItem(
      id: (row['id'] ?? '').toString(),
      clientName: (row['finderName'] ?? 'Finder').toString(),
      clientPhone: (row['finderPhone'] ?? '').toString(),
      category: (row['categoryName'] ?? '').toString(),
      serviceName: (row['serviceName'] ?? '').toString(),
      address: address.replaceAll(RegExp(r'^,\s*|\s*,\s*$'), ''),
      addressLink: (row['addressMapLink'] ?? '').toString(),
      scheduleDate: _formatDate(preferredDate),
      scheduleTime: (row['preferredTimeSlot'] ?? '').toString(),
      workers: _toInt(row['workers'], fallback: 1),
      hours: _toInt(row['hours'], fallback: 1),
      homeType: (row['homeType'] ?? '').toString(),
      paymentMethod: (row['paymentMethod'] ?? '').toString(),
      additionalService: (row['additionalService'] ?? '').toString(),
      finderNote: (row['finderNote'] ?? '').toString(),
      serviceInputs: inputs,
      subtotal: _toDouble(row['subtotal']),
      processingFee: _toDouble(row['processingFee']),
      discount: _toDouble(row['discount']),
      total: _toDouble(row['total']),
      state: _providerStateFromStorage((row['status'] ?? '').toString()),
      timeline: timeline,
    );
  }

  String _safeAssetPath(dynamic value) {
    final path = (value ?? '').toString().trim();
    if (path.startsWith('assets/')) return path;
    return 'assets/images/profile.jpg';
  }

  HomeAddress _toHomeAddress(Map<String, dynamic> row) {
    return HomeAddress(
      id: (row['id'] ?? '').toString().trim(),
      label: (row['label'] ?? 'Home').toString().trim(),
      mapLink: (row['mapLink'] ?? '').toString().trim(),
      street: (row['street'] ?? '').toString().trim(),
      city: (row['city'] ?? '').toString().trim(),
      isDefault: _toBool(row['isDefault']),
    );
  }

  DateTime _toDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim()) ?? DateTime.now();
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    }
    return DateTime.now();
  }

  DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    }
    return null;
  }

  OrderStatusTimeline _timelineFromRow(
    Map<String, dynamic> row, {
    DateTime? fallbackBookedAt,
  }) {
    final source = row['statusTimeline'];
    DateTime? read(String key) {
      if (source is! Map) return null;
      return _toDateTimeOrNull(source[key]);
    }

    var completedAt = read('completedAt');
    var cancelledAt = read('cancelledAt');
    var declinedAt = read('declinedAt');
    final updatedAt = _toDateTimeOrNull(row['updatedAt']);
    final status = (row['status'] ?? '').toString().trim().toLowerCase();
    if (status == 'completed') completedAt ??= updatedAt;
    if (status == 'cancelled') cancelledAt ??= updatedAt;
    if (status == 'declined') declinedAt ??= updatedAt;

    return OrderStatusTimeline(
      bookedAt: read('bookedAt') ?? fallbackBookedAt,
      onTheWayAt: read('onTheWayAt'),
      startedAt: read('startedAt'),
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      declinedAt: declinedAt,
    );
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    final parsed = int.tryParse((value ?? '').toString());
    return parsed ?? fallback;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse((value ?? '').toString());
    return parsed ?? fallback;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    final text = (value ?? '').toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  String _formatDate(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[(value.weekday - 1).clamp(0, 6)];
    final month = months[(value.month - 1).clamp(0, 11)];
    return '$weekday, $month ${value.day}';
  }

  String _orderStatusToStorage(OrderStatus status) {
    switch (status) {
      case OrderStatus.booked:
        return 'booked';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.started:
        return 'started';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.declined:
        return 'declined';
    }
  }

  OrderStatus _orderStatusFromStorage(String status) {
    switch (status.trim().toLowerCase()) {
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'started':
        return OrderStatus.started;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'declined':
        return OrderStatus.declined;
      case 'booked':
      default:
        return OrderStatus.booked;
    }
  }

  String _providerStateToStorage(ProviderOrderState state) {
    switch (state) {
      case ProviderOrderState.incoming:
        return 'booked';
      case ProviderOrderState.onTheWay:
        return 'on_the_way';
      case ProviderOrderState.started:
        return 'started';
      case ProviderOrderState.completed:
        return 'completed';
      case ProviderOrderState.declined:
        return 'declined';
    }
  }

  ProviderOrderState _providerStateFromStorage(String status) {
    switch (status.trim().toLowerCase()) {
      case 'on_the_way':
        return ProviderOrderState.onTheWay;
      case 'started':
        return ProviderOrderState.started;
      case 'completed':
        return ProviderOrderState.completed;
      case 'declined':
        return ProviderOrderState.declined;
      case 'booked':
      default:
        return ProviderOrderState.incoming;
    }
  }

  String _paymentMethodToStorage(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.bankAccount:
        return 'bank_account';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.khqr:
        return 'khqr';
    }
  }

  PaymentMethod _paymentMethodFromStorage(String value) {
    switch (value.trim().toLowerCase()) {
      case 'bank_account':
      case 'bank account':
        return PaymentMethod.bankAccount;
      case 'cash':
        return PaymentMethod.cash;
      case 'khqr':
        return PaymentMethod.khqr;
      default:
        return PaymentMethod.creditCard;
    }
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  String _homeTypeToStorage(HomeType value) {
    switch (value) {
      case HomeType.apartment:
        return 'apartment';
      case HomeType.flat:
        return 'flat';
      case HomeType.villa:
        return 'villa';
      case HomeType.office:
        return 'office';
    }
  }

  HomeType _homeTypeFromStorage(String value) {
    switch (value.trim().toLowerCase()) {
      case 'flat':
        return HomeType.flat;
      case 'villa':
        return HomeType.villa;
      case 'office':
        return HomeType.office;
      case 'apartment':
      default:
        return HomeType.apartment;
    }
  }
}
