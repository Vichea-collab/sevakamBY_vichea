import 'package:flutter/material.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/provider.dart';
import '../../domain/entities/provider_profile.dart';
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
      'homeType': _houseTypeFromServiceFields(draft.serviceFields),
      'additionalService': draft.additionalService,
      'finderNote': draft.additionalService,
      'serviceFields': draft.serviceFields,
    };
    final row = await _remoteDataSource.createFinderOrder(payload);
    return _toFinderOrder(row);
  }

  @override
  Future<PaginatedResult<OrderItem>> fetchFinderOrders({
    int page = 1,
    int limit = 10,
    List<String> statuses = const <String>[],
  }) async {
    final result = await _remoteDataSource.fetchFinderOrders(
      page: page,
      limit: limit,
      statuses: statuses,
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
    List<String> statuses = const <String>[],
  }) async {
    final result = await _remoteDataSource.fetchProviderOrders(
      page: page,
      limit: limit,
      statuses: statuses,
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
    final mapped = rows.map(_toHomeAddress).toList(growable: false);
    mapped.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      if (byLabel != 0) return byLabel;
      return a.id.compareTo(b.id);
    });
    return mapped;
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
  Future<HomeAddress> updateSavedAddress({required HomeAddress address}) async {
    final row = await _remoteDataSource.updateSavedAddress(
      addressId: address.id,
      payload: {
        'label': address.label,
        'mapLink': address.mapLink,
        'street': address.street,
        'city': address.city,
        'isDefault': address.isDefault,
      },
    );
    return _toHomeAddress(row);
  }

  @override
  Future<void> deleteSavedAddress({required String addressId}) async {
    await _remoteDataSource.deleteSavedAddress(addressId: addressId);
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
  Future<OrderItem> submitFinderOrderReview({
    required String orderId,
    required double rating,
    String comment = '',
  }) async {
    final response = await _remoteDataSource.submitFinderOrderReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
    );
    return _toFinderOrder(response);
  }

  @override
  Future<ProviderReviewSummary> fetchProviderReviewSummary({
    required String providerUid,
    int limit = 20,
  }) async {
    final row = await _remoteDataSource.fetchProviderReviewSummary(
      providerUid: providerUid,
      limit: limit,
    );
    final reviews = _safeList(row['reviews'])
        .map((item) {
          final reviewerName = (item['reviewerName'] ?? 'Customer').toString();
          final reviewedAt = _toDateTimeOrNull(item['reviewedAt']);
          return ProviderReview(
            reviewerName: reviewerName,
            reviewerInitials:
                (item['reviewerInitials'] ?? '').toString().trim().isNotEmpty
                ? (item['reviewerInitials'] ?? '').toString().trim()
                : _initialsFromName(reviewerName),
            reviewerPhotoUrl: (item['reviewerPhotoUrl'] ?? '').toString(),
            rating: _toDouble(item['rating'], fallback: 0),
            daysAgo: _daysAgoFromDate(reviewedAt),
            reviewedAt: reviewedAt,
            comment: (item['comment'] ?? '').toString(),
          );
        })
        .toList(growable: false);

    return ProviderReviewSummary(
      providerUid: (row['providerUid'] ?? providerUid).toString(),
      averageRating: _toDouble(row['averageRating'], fallback: 0),
      totalReviews: _toInt(row['totalReviews'], fallback: reviews.length),
      completedJobs: _toInt(row['completedJobs'], fallback: 0),
      reviews: reviews,
    );
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
      blockedDates: (row['providerBlockedDates'] as List? ?? [])
          .map((e) => DateTime.tryParse(e.toString()))
          .where((e) => e != null)
          .cast<DateTime>()
          .toList(),
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
    final serviceFields = _safeMap(row['serviceFields']);
    return OrderItem(
      id: (row['id'] ?? '').toString(),
      provider: provider,
      serviceName: (row['serviceName'] ?? 'Service').toString(),
      address: address,
      homeType: _homeTypeFromStorage((row['homeType'] ?? '').toString()),
      additionalService: (row['additionalService'] ?? '').toString(),
      serviceFields: serviceFields,
      bookedAt: bookedAt,
      scheduledAt: preferredDate,
      timeRange: (row['preferredTimeSlot'] ?? '').toString(),
      status: _orderStatusFromStorage((row['status'] ?? '').toString()),
      rating: _ratingOrNull(row['finderRating'] ?? row['rating']),
      reviewComment: (row['finderComment'] ?? '').toString(),
      reviewedAt: _toDateTimeOrNull(row['reviewedAt']),
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
      homeType: (row['homeType'] ?? '').toString(),
      additionalService: (row['additionalService'] ?? '').toString(),
      finderNote: (row['finderNote'] ?? '').toString(),
      serviceInputs: inputs,
      state: _providerStateFromStorage((row['status'] ?? '').toString()),
      timeline: timeline,
    );
  }

  String _safeAssetPath(dynamic value) {
    final path = (value ?? '').toString().trim();
    if (path.startsWith('assets/')) return path;
    return '';
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

  double? _ratingOrNull(dynamic value) {
    final rating = _toDouble(value);
    if (rating <= 0) return null;
    return rating;
  }

  int _daysAgoFromDate(DateTime? value) {
    if (value == null) return 0;
    final diff = DateTime.now().difference(value).inDays;
    if (diff < 0) return 0;
    return diff;
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return '$first$last'.toUpperCase();
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
      case ProviderOrderState.booked:
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
      case 'cancelled':
        return ProviderOrderState.declined;
      case 'declined':
        return ProviderOrderState.declined;
      case 'booked':
      default:
        return ProviderOrderState.incoming;
    }
  }

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _safeList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map>().map(_safeMap).toList(growable: false);
  }

  String _houseTypeFromServiceFields(Map<String, dynamic> fields) {
    return (fields['houseType'] ?? '').toString().trim();
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
